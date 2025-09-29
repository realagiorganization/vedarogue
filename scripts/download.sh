#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") -u URL -o OUTPUT
  -u  URL to download
  -o  Output file path
EOF
}

URL=""
OUT=""
while getopts ":u:o:h" opt; do
  case "$opt" in
    u) URL="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [[ -z "$URL" || -z "$OUT" ]]; then
  err "URL and OUTPUT are required"
  usage
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

log "Downloading: $URL"
if is_cmd curl; then
  TMP="$OUT.part"
  curl -fL --retry 3 --retry-delay 2 -C - -o "$TMP" "$URL"
  mv -f "$TMP" "$OUT"
elif is_cmd wget; then
  TMP="$OUT.part"
  wget -c -O "$TMP" "$URL"
  mv -f "$TMP" "$OUT"
else
  err "Neither curl nor wget is available"
  exit 1
fi

log "Saved to: $OUT"

