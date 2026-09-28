#!/usr/bin/env bash
# Package an already-built `cargo build --release --locked` output into the
# same layout as the nixpkgs niri package, as a standalone tar.xz, plus a
# release-notes file with the facts nixos_config needs to consume it
# (see issue #4). Run this after the release build; it does not build niri
# itself, so it can be re-run locally against a build made elsewhere
# (e.g. via remote-run) to check the tarball before pushing to `prod`.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

bin="target/release/niri"
if [ ! -x "$bin" ]; then
    echo "error: $bin not found or not executable; run 'cargo build --release --locked' first" >&2
    exit 1
fi

sha7="$(git rev-parse --short=7 HEAD)"
sha_full="$(git rev-parse HEAD)"
dist_dir="dist"
stage_dir="$dist_dir/stage"
tarball_name="niri-prod-${sha7}-x86_64-linux.tar.xz"
tarball_path="$dist_dir/$tarball_name"
notes_path="$dist_dir/release-notes.md"

rm -rf "$stage_dir"
mkdir -p \
    "$stage_dir/bin" \
    "$stage_dir/share/wayland-sessions" \
    "$stage_dir/share/xdg-desktop-portal" \
    "$stage_dir/share/systemd/user" \
    "$stage_dir/share/bash-completion/completions" \
    "$stage_dir/share/fish/vendor_completions.d" \
    "$stage_dir/share/zsh/site-functions" \
    "$stage_dir/share/nushell/vendor/autoload"

install -Dm755 "$bin" "$stage_dir/bin/niri"
# -s alone leaves .debug_gdb_scripts (a gdb auto-load note, not a symbol
# table); remove it explicitly so no .debug_* section survives.
strip -s -R .debug_gdb_scripts "$stage_dir/bin/niri"

install -Dm755 resources/niri-session "$stage_dir/bin/niri-session"

install -Dm644 resources/niri.desktop -t "$stage_dir/share/wayland-sessions"
install -Dm644 resources/niri-portals.conf -t "$stage_dir/share/xdg-desktop-portal"
install -Dm644 resources/niri.service resources/niri-shutdown.target -t "$stage_dir/share/systemd/user"

"$stage_dir/bin/niri" completions bash > "$stage_dir/share/bash-completion/completions/niri.bash"
"$stage_dir/bin/niri" completions fish > "$stage_dir/share/fish/vendor_completions.d/niri.fish"
"$stage_dir/bin/niri" completions zsh > "$stage_dir/share/zsh/site-functions/_niri"
"$stage_dir/bin/niri" completions nushell > "$stage_dir/share/nushell/vendor/autoload/niri.nu"

tar -cJf "$tarball_path" -C "$stage_dir" .

sha256_hex="$(sha256sum "$tarball_path" | awk '{print $1}')"
sha256_nix="$(nix-prefetch-url --type sha256 "file://$(realpath "$tarball_path")" 2>/dev/null)"

needed="$(readelf -d "$stage_dir/bin/niri" | grep NEEDED)"
# Not `ldd --version | head -1`: under `set -o pipefail`, head closing the
# pipe after its first line can send ldd a SIGPIPE, intermittently exiting
# this whole script with 141.
glibc_version="$(getconf GNU_LIBC_VERSION)"

{
    echo "- 源提交: \`$sha_full\`"
    echo "- tarball: \`$tarball_name\`"
    echo "- sha256 (hex): \`$sha256_hex\`"
    echo "- sha256 (nix): \`$sha256_nix\`"
    echo "- \`bin/niri\` NEEDED:"
    echo '```'
    echo "$needed"
    echo '```'
    echo "- 构建 glibc: \`$glibc_version\`"
} > "$notes_path"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
        echo "sha7=$sha7"
        echo "tarball_path=$tarball_path"
        echo "notes_path=$notes_path"
    } >> "$GITHUB_OUTPUT"
fi

echo "packaged $tarball_path"
cat "$notes_path"
