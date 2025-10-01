#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LOG_DIR="$ROOT_DIR/build/test_logs"
CSV_FILE="$LOG_DIR/tests.csv"
mkdir -p "$LOG_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not available" >&2
  exit 1
fi

SERVER_OS=$(docker version -f '{{.Server.Os}}' 2>/dev/null || echo unknown)

csv_header() {
  echo "name,command,image,exit_code,duration_ms,stdout_file,stderr_file,server_os"
}

run_test() {
  local name="$1"; shift
  local image="$1"; shift
  local out="$LOG_DIR/${name}.out.txt"
  local err="$LOG_DIR/${name}.err.txt"
  local start_ms end_ms dur_ms code

  start_ms=$(python3 - <<'PY'
import time; print(int(time.time()*1000))
PY
)
  set +e
  docker run --rm -v "$ROOT_DIR:/work" -w /work "$image" "$@" >"$out" 2>"$err"
  code=$?
  set -e
  end_ms=$(python3 - <<'PY'
import time; print(int(time.time()*1000))
PY
)
  dur_ms=$(( end_ms - start_ms ))
  # csv line
  printf '%s,%q,%s,%d,%d,%s,%s,%s\n' \
    "$name" "$*" "$image" "$code" "$dur_ms" "$out" "$err" "$SERVER_OS"
}

# Write CSV header
csv_header > "$CSV_FILE"

# Ensure make-runner image exists
if ! docker image inspect make-runner:latest >/dev/null 2>&1; then
  echo "Building make-runner:latest image" >&2
  docker build -f "$ROOT_DIR/docker/cargo/Dockerfile" -t make-runner:latest "$ROOT_DIR"
fi

# Ensure emacs image exists
if ! docker image inspect vedarogue/emacs:latest >/dev/null 2>&1; then
  echo "Building vedarogue/emacs:latest image" >&2
  docker build -f "$ROOT_DIR/docker/emacs/Dockerfile" -t vedarogue/emacs:latest "$ROOT_DIR"
fi

# Tests
run_test make_runner_list make-runner:latest list >> "$CSV_FILE"
run_test make_runner_env_sync make-runner:latest run env-sync >> "$CSV_FILE"
run_test emacs_magit_smoke vedarogue/emacs:latest --batch --eval "(progn (require 'magit) (message \"Magit OK\"))" >> "$CSV_FILE"

echo "Wrote $CSV_FILE and per-test logs in $LOG_DIR" >&2

