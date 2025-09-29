#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") -f FILE -s SHA256
  -f  File to verify
  -s  Expected SHA256 (if empty, verification is skipped)
EOF
}

FILE=""
EXPECTED=""
while getopts ":f:s:h" opt; do
  case "$opt" in
    f) FILE="$OPTARG" ;;
    s) EXPECTED="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [[ -z "$FILE" ]]; then
  err "FILE is required"
  usage
  exit 1
fi

if [[ -z "${EXPECTED}" ]]; then
  warn "No SHA256 provided; skipping verification for $FILE"
  exit 0
fi

if [[ ! -f "$FILE" ]]; then
  err "File not found: $FILE"
  exit 1
fi

calc_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    err "No sha256sum or shasum found"
    return 2
  fi
}

ACTUAL=$(calc_sha256 "$FILE")
if [[ "$ACTUAL" == "$EXPECTED" ]]; then
  log "SHA256 OK: $FILE"
else
  err "SHA256 mismatch for $FILE\n  expected: $EXPECTED\n  actual:   $ACTUAL"
  exit 1
fi

