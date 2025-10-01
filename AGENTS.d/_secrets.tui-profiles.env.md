# TUI Docker Image Profiles

This document defines how to configure TUI Docker image profiles used by `scripts/run_tuis_docker.sh` and the Makefile targets `docker-tuis` and `docker-tuis-file`.

- Location of profiles file: `_secrets.tui-profiles.env`
- Purpose: map logical profile names to Docker images for running TUIs.
- Consumption: sourced by `scripts/run_tuis_docker.sh` when present.

## Format
- One profile per line, using shell `VAR=value` syntax:
  - `PROFILE_<name>=<docker_image_reference>`
- Lines starting with `#` are comments.
- The right-hand value must be a valid Docker image (optionally with registry and tag).
- You can reference environment variables (e.g., `DOCKER_IMAGE_TUI`) in values.

## Examples
```
# Defaults and quick profiles
PROFILE_default=make-runner:latest
PROFILE_tui=${DOCKER_IMAGE_TUI}
PROFILE_busybox=busybox:latest
PROFILE_alpine=alpine:latest

# Custom registry example
#PROFILE_internal=registry.example.com/team/tui-runner:stable
```

## Usage
- Use the default profile for all entries:
  - `make docker-tuis TUIS="xplr ncdu" PROFILE=default`
- Per-item profile prefix (overrides default for that item):
  - `make docker-tuis TUIS="busybox@sh -lc 'echo hi' alpine@sh -lc 'uname -a'"`
- File-driven list (one item per line; supports `#` comments):
  - `make docker-tuis-file TUIS_FILE=tuistack.txt PROFILE=tui`
  - Each line supports: `[profile@][subdir:]cmd`

## Interaction with registered hosts
- If a profile is not found and `DOCKER_IMAGE_TUI` is unset, the script falls back to `_secrets.registered-hosts.md`:
  - `DOCKER_IMAGE_TUI=<image>` takes precedence if set there.
  - `DOCKER_CONTAINER_HOST_REGISTRY_NAME=<registry>` falls back to `<registry>/awesome/tui:latest`.

## Maintenance Guidance
- Keep `_secrets.tui-profiles.env` under version control (hostnames only; no credentials).
- Update profiles when adding/removing images used by your TUIs.
- Ensure referenced images are available in the environment (local Docker or your registry) and pullable by CI if needed.
- Do not store secrets or tokens in this file.

