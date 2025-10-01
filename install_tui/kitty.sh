#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

cmd=kitty

install() {
  if have "$cmd"; then
    log "$cmd already installed (binary present)"
    return 0
  fi
  if is_macos; then
    install_cask kitty
    return $?
  fi
  if is_linux; then
    if install_linux_pkg kitty; then
      return 0
    fi
    log "Could not install kitty via system package manager. See https://sw.kovidgoyal.net/kitty/binary/ for manual install."
    return 1
  fi
  log "Unsupported OS for kitty in this script."
  return 1
}

verify() { verify_cmd "$cmd"; }

case "${1:-install}" in
  install) install ;;
  verify) verify ;;
  *) echo "usage: $0 [install|verify]" >&2; exit 2 ;;
esac
