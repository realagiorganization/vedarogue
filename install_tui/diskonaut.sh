#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

cmd=diskonaut

install() {
  if have "$cmd"; then
    log "$cmd already installed"
    return 0
  fi
  if have brew && brew info "$cmd" >/dev/null 2>&1; then
    install_formula "$cmd"
  else
    ensure_cargo
    log "Installing $cmd via cargo"
    cargo install diskonaut
  fi
}

verify() { verify_cmd "$cmd"; }

case "${1:-install}" in
  install) install ;;
  verify) verify ;;
  *) echo "usage: $0 [install|verify]" >&2; exit 2 ;;
esac

