#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

pkg=gif-for-cli

user_bin() {
  python3 - <<'PY'
import site, sys
print(site.USER_BASE + '/bin')
PY
}

install() {
  if pip3 show "$pkg" >/dev/null 2>&1; then
    log "$pkg already installed (pip3)"
  else
    ensure_pip3
    log "Installing $pkg via pip3 --user"
    pip3 install --user --upgrade "$pkg"
  fi
  # Ensure user-local pip bin on PATH for verify
  local bin_dir
  bin_dir=$(user_bin)
  ensure_path_entry "$bin_dir"
}

verify() {
  if pip3 show "$pkg" >/dev/null 2>&1; then
    log "Verified: pip package $pkg installed"
  else
    log "Missing: pip package $pkg"
    return 1
  fi
}

case "${1:-install}" in
  install) install ;;
  verify) verify ;;
  *) echo "usage: $0 [install|verify]" >&2; exit 2 ;;
esac

