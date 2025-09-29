#!/usr/bin/env bash
set -euo pipefail

is_cmd() { command -v "$1" >/dev/null 2>&1; }

log() { printf "[%s] %s\n" "$(date +"%H:%M:%S")" "$*"; }
warn() { printf "[WARN] %s\n" "$*" >&2; }
err() { printf "[ERROR] %s\n" "$*" >&2; }

