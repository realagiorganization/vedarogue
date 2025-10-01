#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

cmd=tray-tui

install() {
  if have "$cmd"; then
    log "$cmd already installed"
    return 0
  fi
  ensure_cargo
  log "Installing $cmd via cargo (locked)"
  cargo install --locked tray-tui || cargo install tray-tui
}

verify() { verify_cmd "$cmd"; }

case "${1:-install}" in
  install) install ;;
  verify) verify ;;
  *) echo "usage: $0 [install|verify]" >&2; exit 2 ;;
esac

