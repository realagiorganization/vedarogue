# Agent Operational Guidelines

This repository includes a TUI installer and a cross‑platform automation stack (Makefile, cargo runner, Docker, CI). Agents interacting with this repo should follow these rules when introducing or referencing TUIs and when running commands.

## TUI Presentation Rule

- On first mention of any TUI that does not include a link to its GIF screenshot/demo or its documentation, produce a monospaced pseudographic diagram approximating the TUI.
- Requirements for the diagram:
  - Size: exactly 80×80 characters.
  - Style: pseudographics/box‑drawing characters suitable for terminals.
  - Source: derive from the TUI’s primary GUI or most representative animated GIF by converting it to pseudographics using an “awesome TUI” GIF‑to‑pseudographics converter.
  - If an actual GIF is not available, synthesize a representative layout (panes, lists, status bars, key hints) at 80×80, label panels and important shortcuts.
- After showing the diagram, provide a one‑line caption and a link to the official docs (if known) or to a search query to discover docs.

Notes:
- The diagram is only required on first mention in a conversation or document where the TUI had no GIF/docs link. Later mentions can omit.
- Prefer clarity over photorealism: emphasize structure (panes, headers, key hints, progress bars) and typical navigation.

## Command Execution Rule

- Use the `make-runner` cargo binary (or the provided Docker image) to execute Makefile targets with full stdin/stdout/stderr passthrough when interactive behavior is needed.
  - Local: `cargo run -- run <target> [more targets…]`
  - Docker: `docker run -i --rm -v "$PWD:/work" -w /work make-runner:latest run <target>`
- When showcasing commands, prefer Makefile targets over long shell invocations; this ensures consistent behavior across environments and CI.

## Dockerized TUIs Rule

- Launch TUIs using the Makefile target `docker-tuis` which accepts a space-separated list of commands:
  - Example: `make docker-tuis TUIS="xplr ncdu"`
  - Supports per-item working directory with `subdir:cmd` syntax: `make docker-tuis TUIS="tools/shop:tui-shop"`
- Image selection:
  - Set `DOCKER_IMAGE_TUI` to override the image.
  - If unset, the helper reads `_secrets.registered-hosts.md` for `DOCKER_IMAGE_TUI` or `DOCKER_CONTAINER_HOST_REGISTRY_NAME` (fallback to `<registry>/awesome/tui:latest`).
- Keep `_secrets.registered-hosts.md` maintained with your registry host or a specific TUI image.

## Deployment Catalog Rule

- Before committing and pushing, always ensure the latest deployments catalog is generated and included:
  - In CI: a `deployments-readme` artifact is produced by `scripts/generate_deployments_readme.sh`.
  - Locally (optional): run `bash scripts/generate_deployments_readme.sh` to refresh `README.deployments.md` (requires `GITHUB_TOKEN`/`GITHUB_RUN_ID` for full artifact listing).
- Keep `README.deployments.md` up to date in commits when relevant changes are made to build outputs or Docker images.

## Commit Message Rule for README Changes

- When committing changes that touch any `README*.md` files, append a changelog section to the commit message detailing what changed in each file. Suggested template:

```
README updates:
- README.md: <one-line summary>
- README.deployments.md: <one-line summary>
- install_tui/README.md: <one-line summary>
```

## Update Checklist (Always Before Commit/Push)

- Run environment sync if env vars changed: `make env-sync`.
- Refresh deployments catalog (CI does automatically): `bash scripts/generate_deployments_readme.sh`.
- If adding/mentioning a new TUI without GIF/docs, include an 80×80 pseudographic diagram as per the TUI Presentation Rule.
- Ensure Dockerized flows still work or are covered by `scripts/run_docker_tests.sh`.
- Use the auto‑commit script to compose and push changes with proper changelog:
  - `bash scripts/auto_commit.sh "<short subject>"`
  - The script aggregates README* changes, appends a per‑README changelog block, and includes concise examples of outputs from any launched Docker runs (from `build/test_logs/*.out.txt` and `*.err.txt`).
- Push to the active branch once the above is complete.

## Environment Propagation

- When relevant, run `make env-sync` to generate terminal config snippets from the active environment variables listed in `install_tui/LIST_OF_ENV_VARIABLES_TO_IMPORT`.
- For Kitty users, print the include line via `make print-kitty-include`. For iTerm2 users, install the Dynamic Profile via `make install-iterm2-dynamic-profile`.
