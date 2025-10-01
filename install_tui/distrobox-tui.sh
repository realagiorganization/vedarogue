#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

cmd=distrobox-tui

install() {
  if have "$cmd"; then
    log "$cmd already installed"
    return 0
  fi
  ensure_go
  local gopath
  gopath=$(go env GOPATH)
  ensure_dir "$gopath/bin"
  log "Installing $cmd via 'go install github.com/phanirithvij/distrobox-tui@main'"
  GO111MODULE=on go install github.com/phanirithvij/distrobox-tui@main
  ensure_path_entry "$gopath/bin"
}

verify() { verify_cmd "$cmd"; }

case "${1:-install}" in
  install) install ;;
  verify) verify ;;
  *) echo "usage: $0 [install|verify]" >&2; exit 2 ;;
esac

