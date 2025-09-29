#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") -f ARCHIVE -d DEST
  -f  Archive file to extract
  -d  Destination directory
Supports: .tar.gz, .tgz, .tar.xz, .tar.bz2, .zip, .gz (single file)
EOF
}

FILE=""
DEST=""
while getopts ":f:d:h" opt; do
  case "$opt" in
    f) FILE="$OPTARG" ;;
    d) DEST="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [[ -z "$FILE" || -z "$DEST" ]]; then
  err "ARCHIVE and DEST are required"
  usage
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  err "Archive not found: $FILE"
  exit 1
fi

mkdir -p "$DEST"
log "Extracting $FILE -> $DEST"

case "$FILE" in
  *.tar.gz|*.tgz)
    tar -xzf "$FILE" -C "$DEST"
    ;;
  *.tar.xz)
    tar -xJf "$FILE" -C "$DEST"
    ;;
  *.tar.bz2)
    tar -xjf "$FILE" -C "$DEST"
    ;;
  *.tar)
    tar -xf "$FILE" -C "$DEST"
    ;;
  *.zip)
    if command -v unzip >/dev/null 2>&1; then
      unzip -q -o "$FILE" -d "$DEST"
    else
      err "unzip command not found"
      exit 1
    fi
    ;;
  *.gz)
    # Single-file gzip, extract to DEST with same basename
    BASENAME=$(basename "$FILE" .gz)
    gunzip -c "$FILE" > "$DEST/$BASENAME"
    ;;
  *)
    warn "Unknown archive type for $FILE; copying as-is"
    cp -f "$FILE" "$DEST/"
    ;;
esac

log "Extraction complete"

