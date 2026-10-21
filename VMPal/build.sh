#!/bin/sh
# Builds BusyBox as VMPal's Linux for containers ships it: /bin/busybox, /bin/busybox.static and /usr/bin/ssl_client,
# from this tree (BusyBox 1.37.0 with Alpine's patches) the way Alpine's APKBUILD for busybox 1.37.0-r31 does
# (VMPal/APKBUILD, build()). Run it in Alpine Linux 3.24 on arm64 (aarch64), with
#   apk add build-base linux-headers openssl-dev perl pkgconf utmps-dev utmps-static
# Usage: VMPal/build.sh [folder for the builds, build-vmpal by default]
set -e
source=$(cd "$(dirname "$0")/.." && pwd)
work=${1:-$source/build-vmpal}
mkdir -p "$work"
work=$(cd "$work" && pwd)

# abuild's default flags (abuild 3.16.0, default.conf), which Alpine's builders used for r31.
export CFLAGS="-Os -fstack-clash-protection -Wformat -Werror=format-security"
export LDFLAGS="-Wl,--as-needed,-O1,--sort-common"
export MAKEFLAGS="-j$(nproc)"
# abuild sets this to the time of the last aports commit for the package (c3ef5d10, 2026-01-10 15:38:28 UTC).
# BusyBox prints it in its banner.
export SOURCE_DATE_EPOCH=1768059508
# BusyBox links utmps statically, as Alpine's build does.
extra_cflags=$(pkg-config --cflags --static libutmps)
extra_libs=$(pkg-config --libs --static libutmps)

rm -rf "$work/dynamic" "$work/static" "$work/out"
mkdir -p "$work/dynamic" "$work/static" "$work/out"

# /usr/bin/ssl_client, which BusyBox's wget runs for https.
gcc $CFLAGS $(pkg-config --cflags libcrypto libssl) "$source/VMPal/ssl_client.c" -o "$work/dynamic/ssl_client" \
    $LDFLAGS $(pkg-config --libs libcrypto libssl)

# /bin/busybox, with Alpine's busyboxconfig.
cd "$work/dynamic"
cp "$source/VMPal/busyboxconfig" .config
make -C "$source" O="$PWD" silentoldconfig
make CONFIG_EXTRA_CFLAGS="$extra_cflags" CONFIG_EXTRA_LDLIBS="$extra_libs"

# /bin/busybox.static: the same config, static, without PIE, and with BusyBox's own ssl_client.
cd "$work/static"
sed -e "s/.*CONFIG_PIE.*/\# CONFIG_PIE is not set/" \
    -e "s/.*CONFIG_STATIC\([A-Z_]*\).*/CONFIG_STATIC\1=y/" \
    -e "s/.*CONFIG_SSL_CLIENT.*/CONFIG_SSL_CLIENT=y/" \
    "$source/VMPal/busyboxconfig" > .config
make -C "$source" O="$PWD" silentoldconfig
make CONFIG_EXTRA_CFLAGS="$extra_cflags" CONFIG_EXTRA_LDLIBS="$extra_libs"

# abuild strips the programs it packages.
strip -o "$work/out/busybox" "$work/dynamic/busybox"
strip -o "$work/out/busybox.static" "$work/static/busybox"
strip -o "$work/out/ssl_client" "$work/dynamic/ssl_client"
ls -l "$work/out"
