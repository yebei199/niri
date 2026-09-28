# .github/workflows

GitHub Actions CI/CD workflow definitions for this repository.

- `ci.yml` — build, test, lint, and docs-publishing checks, run on every push/PR.
- `release.yml` — upstream's manual `workflow_dispatch` release prep (vendored-deps
  archive, draft GitHub release for a tagged version).
- `prod-release.yml` — publishes a prebuilt, stripped `niri` tarball (matching the
  nixpkgs package layout) as a GitHub Release whenever `prod` is pushed to, so
  `nixos_config` can `fetchurl` it instead of building from source. See issue #4 for
  background; the packaging logic itself lives in `.github/scripts/package-release.sh`.

Not responsible for: the packaging/build logic itself (kept in `.github/scripts/` so it
can be run and checked outside of Actions).
