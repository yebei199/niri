#!/usr/bin/env bash
# Build and install libdisplay-info 0.3.0 from source (soname libdisplay-info.so.3),
# so bin/niri links against the version nixos_config's autoPatchelf can resolve
# (nixpkgs provides libdisplay-info_0_3 for that soname, but not the older
# libdisplay-info-dev shipped by Ubuntu noble, which gives .so.1 — see issue #4
# rework F-001). Do not `apt-get install libdisplay-info-dev` alongside this:
# it would make pkg-config's resolution version-dependent on install order.
#
# Needs `hwdata` installed (its meson.build reads /usr/share/hwdata/pnp.ids for
# the vendor-ID table; there's no pkg-config file for it on Ubuntu, so its
# meson dependency lookup falls through to that hardcoded path — apt's hwdata
# package puts the file there).
set -euo pipefail

version=0.3.0
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

git clone --branch "$version" --depth 1 \
    https://gitlab.freedesktop.org/emersion/libdisplay-info.git \
    "$work_dir/libdisplay-info"

cd "$work_dir/libdisplay-info"
meson setup build --prefix=/usr --buildtype=release
ninja -C build
sudo ninja -C build install
sudo ldconfig

pkg-config --modversion libdisplay-info
