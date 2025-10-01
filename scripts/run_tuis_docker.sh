#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

# Resolve image
IMAGE=${DOCKER_IMAGE_TUI:-}
if [ -z "$IMAGE" ]; then
  if [ -f _secrets.registered-hosts.md ]; then
    # Try to extract DOCKER_IMAGE_TUI or registry variable from the secrets file
    IMAGE=$(grep -Eo '^DOCKER_IMAGE_TUI=.+$' _secrets.registered-hosts.md | head -n1 | cut -d= -f2- || true)
    if [ -z "$IMAGE" ]; then
      REG=$(grep -Eo '^DOCKER_CONTAINER_HOST_REGISTRY_NAME=.+$' _secrets.registered-hosts.md | head -n1 | cut -d= -f2- || true)
      if [ -n "$REG" ]; then
        IMAGE="$REG/awesome/tui:latest"
      fi
    fi
  fi
fi
IMAGE=${IMAGE:-make-runner:latest}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found in PATH" >&2
  exit 1
fi

# Build env flags from import list
env_flags=()
if [ -f install_tui/LIST_OF_ENV_VARIABLES_TO_IMPORT ]; then
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue;; esac
    val=$(printenv "$name" || true)
    [ -n "$val" ] && env_flags+=( -e "$name" )
  done < install_tui/LIST_OF_ENV_VARIABLES_TO_IMPORT
fi

if [ $# -eq 0 ]; then
  echo "Provide a space-separated list of TUIs. Example: xplr ncdu subdir:custom-cmd" >&2
  exit 2
fi

for item in "$@"; do
  work=/work
  cmd="$item"
  if [[ "$item" == *:* ]]; then
    work="/work/${item%%:*}"
    cmd="${item#*:}"
  fi
  echo "[docker-tuis] Image=$IMAGE Workdir=$work Cmd=$cmd"
  TTY_FLAGS="-it"
  if [ ! -t 0 ]; then TTY_FLAGS="-i"; fi
  if [ ${#env_flags[@]} -gt 0 ]; then
    docker run --rm $TTY_FLAGS -v "$ROOT_DIR:/work" -w "$work" "${env_flags[@]}" "$IMAGE" sh -lc "$cmd"
  else
    docker run --rm $TTY_FLAGS -v "$ROOT_DIR:/work" -w "$work" "$IMAGE" sh -lc "$cmd"
  fi
done
