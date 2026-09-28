# .github/scripts

Helper scripts invoked by the workflows in `.github/workflows/`. A workflow's YAML step
should call into a script here rather than growing a long inline `run:` block, so the
logic can also be run and checked locally.

- `build-libdisplay-info.sh` — builds and installs libdisplay-info 0.3.0 from source
  (soname `libdisplay-info.so.3`) before `cargo build`. Ubuntu noble's
  `libdisplay-info-dev` apt package is 0.1.x (`.so.1`), which nixos_config's nixpkgs
  doesn't ship a provider for, breaking autoPatchelf on the released binary (issue #4
  rework F-001). Run this instead of `apt-get install libdisplay-info-dev`.
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

Depends on: a `target/release/niri` binary already built, `nix-prefetch-url` (from Nix)
being on `PATH` for the nix-format hash, and `readelf`/`strip`/`ldd`/`meson`/`ninja`
(standard on Linux, except meson/ninja which the workflow installs via apt).
