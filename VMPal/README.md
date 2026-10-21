# BusyBox in VMPal

This branch is the BusyBox that [VMPal](https://vmpal.com) ships in Linux for containers, the small Linux VM that runs
VMPal's containers. Its root is Alpine Linux 3.24, and its BusyBox is Alpine's package busybox 1.37.0-r31, which
VMPal installs as Alpine built it. This branch is how Alpine made it:

- BusyBox 1.37.0: the tag `1_37_0` (be7d1b7) from [git.busybox.net/busybox](https://git.busybox.net/busybox). Alpine
  builds from [busybox-1.37.0.tar.bz2](https://busybox.net/downloads/busybox-1.37.0.tar.bz2), which has the tag's
  files except its 9 `.gitignore` files.
- Alpine's 44 patches, as the commits after it, in the order Alpine applies them. Each commit names its patch in
  Alpine's [aports, main/busybox at c3ef5d10](https://gitlab.alpinelinux.org/alpine/aports/-/tree/c3ef5d10e6ef6528852c51f0564963e2f8c1be19/main/busybox),
  the commit Alpine built 1.37.0-r31 from.
- `VMPal: how VMPal's Linux for containers builds BusyBox`: this folder, with Alpine's files that the build uses.

| Linux for containers | VMPal | Files from this branch |
| --- | --- | --- |
| 1 | 0.87 to 0.89 | `/bin/busybox`, `/usr/bin/ssl_client` |
| 2 | 0.90 and later | `/bin/busybox`, `/bin/busybox.static`, `/usr/bin/ssl_client` |

`/bin/busybox` and `/usr/bin/ssl_client` are the same files in both versions. `/bin/sh` is a link to `/bin/busybox`.

| File | Made from | SHA-256 |
| --- | --- | --- |
| `/bin/busybox` | this tree, with `busyboxconfig` | 97d52efa149563c8d886e3670e2496d4140d3c54138017afd3a105e0397fae2e |
| `/bin/busybox.static` | this tree, with `busyboxconfig` changed as `build.sh` does: static (`CONFIG_STATIC`, `CONFIG_STATIC_LIBGCC`), `CONFIG_PIE` off (Alpine's gcc still links it as static-pie), and BusyBox's own `ssl_client` applet | 999cb969d09093a71716cfc747bb53cdada3f332c05eb5046c56e0f66a4d6d22 |
| `/usr/bin/ssl_client` | `ssl_client.c`, Alpine's program that BusyBox's `wget` runs for https | 171f6cea11a9dc95f1b7f1c911358a58c8f5cd81ae4ea3bd283d8649b7891701 |

The busybox package also installs some of Alpine's text files as they are in aports: `/etc/securetty`,
`/etc/udhcpc/udhcpc.conf`, `/usr/share/udhcpc/default.script` (`default.script`), `/etc/network/if-up.d/dad`
(`dad.if-up`) and `/etc/logrotate.d/acpid` (`acpid.logrotate`). `/etc/busybox-paths.d/busybox` is the output of
`busybox --list-path`. VMPal doesn't install busybox-extras, so its `busyboxconfig-extras` isn't here.

In this folder:

- `busyboxconfig`: Alpine's BusyBox configuration.
- `ssl_client.c`: Alpine's source of `/usr/bin/ssl_client`.
- `APKBUILD`: Alpine's recipe, for reference. `build.sh` does what its `build()` does.
- `build.sh`: builds the three programs from this tree.

BusyBox is under the GNU General Public License version 2 (`LICENSE`), and so are Alpine's patches, `busyboxconfig` and
`ssl_client.c` (Alpine's license for the package is GPL-2.0-only).

Alpine's build links other libraries into the programs. Their source is in the releases of
[huyphams/vmpal-linux-for-containers](https://github.com/huyphams/vmpal-linux-for-containers) (vm-1 and vm-2):

- utmps 0.1.3.3-r0 and skalibs 2.15.0.0-r0 (ISC), in both BusyBox programs: `utmps-0.1.3.3-r0-source.tar` and
  `skalibs-2.15.0.0-r0-source.tar`. These are the versions Alpine 3.24 has, from aports commits 900a4ecef7 and
  f148233038; Alpine 3.24's package index records the same commits for utmps-static and skalibs-static.
- musl 1.2.6-r2 (MIT) and gcc 15.2.0-r5's libgcc (GPL-3.0-or-later with the GCC Runtime Library Exception), in
  `/bin/busybox.static`: `musl-1.2.6-r2-source.tar` and `gcc-15.2.0-r5-source.tar`.

The kernel of Linux for containers is in [huyphams/linux](https://github.com/huyphams/linux).
[huyphams/vmpal-linux-for-containers](https://github.com/huyphams/vmpal-linux-for-containers) lists what each version
holds, with the sources of its other packages.

## Building

In Alpine Linux 3.24 on arm64 (aarch64), for example a container of `alpine:3.24`:

```sh
apk add build-base linux-headers openssl-dev perl pkgconf utmps-dev utmps-static
VMPal/build.sh
```

It builds `ssl_client`, then BusyBox twice, with the commands and flags Alpine's build used, and strips the three
programs as Alpine's packaging does. It puts them in `build-vmpal/out` and lists them.

In an alpine:3.24 container on 2026-10-21 (gcc 15.2.0-r5, binutils 2.45.1-r1, musl 1.2.6-r2, utmps 0.1.3.3-r0,
skalibs 2.15.0.0-r0, OpenSSL 3.5.9-r0), it builds all three files byte for byte as VMPal ships them: busybox
`97d52efa…`, busybox.static `999cb969…`, ssl_client `171f6cea…`. Newer Alpine packages may change that. The date in
BusyBox's banner, 2026-01-10 15:38:28 UTC, is the time of aports commit c3ef5d10 (abuild's `SOURCE_DATE_EPOCH`), not
the day Alpine built it.

The patches apply with GNU patch, as abuild applies them. One of them,
`0001-awk-fix-handling-of-literal-backslashes-in-replaceme.patch`, needs fuzz in `testsuite/awk.tests`, and BSD
patch puts that test elsewhere in the file. It's a test, not part of the programs.
