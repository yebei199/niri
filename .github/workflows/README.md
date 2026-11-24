# .github/workflows

GitHub Actions CI/CD workflow definitions for this repository.

GitHub-hosted runners stopped starting jobs for this account on 2026-11-20, so this fork runs
only on the self-hosted `pc1` runner (nixos_config `home/features/development/repo-runners.nix`).
Upstream's workflows stay byte-for-byte as upstream has them, for clean merges, and are disabled
in the repository's Actions settings (`gh workflow disable`).

- `ci.yml` — upstream's build, test, lint, and docs-publishing checks (disabled here).
- `release.yml` — upstream's manual `workflow_dispatch` release prep (disabled here).
- `pc1-ci.yml` — rustfmt, clippy and tests on `pc1`, on every push (no `pull_request`
  trigger: a public repo must not run other people's code on a self-hosted machine).
- `prod-release.yml` — publishes a prebuilt, stripped `niri` tarball (matching the
  nixpkgs package layout) as a GitHub Release whenever `prod` is pushed to, so
  `nixos_config` can `fetchurl` it instead of building from source. It builds in the
  flake's dev shell on `pc1`. See issue #4 for background; the packaging logic itself
  lives in `.github/scripts/package-release.sh`.

Not responsible for: the packaging/build logic itself (kept in `.github/scripts/` so it
can be run and checked outside of Actions).
