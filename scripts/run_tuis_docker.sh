#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

# Profiles file (optional)
PROFILES_FILE="_secrets.tui-profiles.env"
if [ -f "$PROFILES_FILE" ]; then
  # shellcheck disable=SC1090
  . "$PROFILES_FILE"
fi

DEFAULT_PROFILE=${DEFAULT_PROFILE:-}

resolve_image() {
  local profile="$1"
  local image=""
  if [ -n "$profile" ]; then
    # Lookup variable: PROFILE_<name>
    local key="PROFILE_${profile}"
    # shellcheck disable=SC2086
    image=$(eval echo "\${$key-}")
  fi
  if [ -z "$image" ]; then
    if [ -n "$DEFAULT_PROFILE" ]; then
      local key="PROFILE_${DEFAULT_PROFILE}"
      image=$(eval echo "\${$key-}")
    fi
  fi
  if [ -z "$image" ]; then
    image=${DOCKER_IMAGE_TUI:-}
    if [ -z "$image" ] && [ -f _secrets.registered-hosts.md ]; then
      image=$(grep -Eo '^DOCKER_IMAGE_TUI=.+$' _secrets.registered-hosts.md | head -n1 | cut -d= -f2- || true)
      if [ -z "$image" ]; then
        REG=$(grep -Eo '^DOCKER_CONTAINER_HOST_REGISTRY_NAME=.+$' _secrets.registered-hosts.md | head -n1 | cut -d= -f2- || true)
        if [ -n "$REG" ]; then
          image="$REG/awesome/tui:latest"
        fi
      fi
    fi
  fi
  echo "${image:-make-runner:latest}"
}

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

LIST_MODE=0
LIST_FILE=""
if [ "${1-}" = "--file" ] && [ -n "${2-}" ]; then
  LIST_MODE=1
  LIST_FILE="$2"
  shift 2
fi

items=()
if [ $LIST_MODE -eq 1 ]; then
  [ -f "$LIST_FILE" ] || { echo "List file not found: $LIST_FILE" >&2; exit 2; }
  while IFS= read -r line; do
    # strip CR and whitespace
    line=$(echo "$line" | tr -d '\r')
    # skip comments/blank
    echo "$line" | grep -Eq '^\s*$|^\s*#' && continue
    items+=("$line")
  done < "$LIST_FILE"
else
  items=("$@")
fi

if [ ${#items[@]} -eq 0 ]; then
  echo "Provide TUIs (args) or --file path. Example: xplr ncdu subdir:custom-cmd or a file with one per line." >&2
  exit 2
fi

for item in "${items[@]}"; do
  work=/work
  profile=""
  cmd="$item"
  # Extract optional profile prefix: profile@...
  if [[ "$cmd" == *@* ]]; then
    profile="${cmd%%@*}"
    cmd="${cmd#*@}"
  fi
  if [[ "$item" == *:* ]]; then
    work="/work/${cmd%%:*}"
    cmd="${cmd#*:}"
  fi
  IMAGE=$(resolve_image "$profile")
  echo "[docker-tuis] Profile=${profile:-<none>} Image=$IMAGE Workdir=$work Cmd=$cmd"
  TTY_FLAGS="-it"
  if [ ! -t 0 ]; then TTY_FLAGS="-i"; fi
  if [ ${#env_flags[@]} -gt 0 ]; then
    docker run --rm $TTY_FLAGS -v "$ROOT_DIR:/work" -w "$work" "${env_flags[@]}" "$IMAGE" sh -lc "$cmd"
  else
    docker run --rm $TTY_FLAGS -v "$ROOT_DIR:/work" -w "$work" "$IMAGE" sh -lc "$cmd"
  fi
done
