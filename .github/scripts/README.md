# .github/scripts

Helper scripts invoked by the workflows in `.github/workflows/`. A workflow's YAML step
should call into a script here rather than growing a long inline `run:` block, so the
logic can also be run and checked locally.

- `package-release.sh` — packages an already-built `cargo build --release --locked`
  output into the nixpkgs-niri-package layout (bin/, share/wayland-sessions, etc.),
  strips the binary, generates shell completions, tars it as
  `niri-prod-<sha7>-x86_64-linux.tar.xz`, and writes release notes with the tarball's
  sha256 (hex and nix formats), `bin/niri`'s NEEDED library list, and the build glibc
  version. Used by the `prod` release workflow; does not build niri itself, so it can
  be re-run against a local release build to check the tarball before pushing. Fails
  (non-zero exit) if `bin/niri`'s NEEDED list doesn't contain exactly
  `libdisplay-info.so.3`, since any other soname means nixos_config can't resolve it.

Not responsible for: building niri (that's the workflow's `cargo build` step), or
anything not tied to a GitHub Actions workflow.

Depends on: a `target/release/niri` binary already built in the flake's dev shell (its
libdisplay-info is 0.3, soname `.so.3`; its glibc must not be newer than nixos_config's,
which the release notes' build glibc line shows), `nix-prefetch-url` (from Nix) being on
`PATH` for the nix-format hash, and `readelf`/`strip`/`getconf` (from the dev shell).
