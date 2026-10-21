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
| `/bin/busybox.static` | this tree, with `busyboxconfig` changed as `build.sh` does: static (`CONFIG_STATIC`, `CONFIG_STATIC_LIBGCC`), no PIE, and BusyBox's own `ssl_client` applet | 999cb969d09093a71716cfc747bb53cdada3f332c05eb5046c56e0f66a4d6d22 |
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
`ssl_client.c` (Alpine's license for the package is GPL-2.0-only). Alpine's build links utmps and skalibs (ISC) into
both BusyBox programs, and musl (MIT) into `/bin/busybox.static`.

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
programs as Alpine's packaging does. It puts them in `build-vmpal/out` and lists them. Alpine built 1.37.0-r31 on
2026-01-10 with the packages it had that day, most likely utmps 0.1.3.2 and skalibs 2.14.5.0. Alpine 3.24 has newer
ones now, so a build today isn't the same file byte for byte.
