#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

cmd=iterm2

install() {
  # iTerm2 is macOS only
  if ! is_macos; then
    log "iTerm2 not supported on this OS; skipping"
    return 0
  fi
  if brew list --cask --versions iterm2 >/dev/null 2>&1; then
    log "iTerm2 already installed (cask)"
    return 0
  fi
  install_cask iterm2
}

verify() {
  if is_macos && brew list --cask --versions iterm2 >/dev/null 2>&1; then
    log "Verified: iTerm2 cask installed"
  else
    log "iTerm2 not installed or not applicable on this OS"
  fi
}

case "${1:-install}" in
  install) install ;;
  verify) verify ;;
  *) echo "usage: $0 [install|verify]" >&2; exit 2 ;;
esac
