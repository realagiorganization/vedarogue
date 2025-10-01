#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

# tlock has no Homebrew formula; provide a docker-based shim

shim_path="$HOME/.local/bin/tlock"

install() {
  if have tlock; then
    log "tlock already available in PATH"
    return 0
  fi
  if ! have docker; then
    log "docker is required for tlock shim. Install Docker Desktop or Rancher Desktop."
    return 1
  fi
  ensure_dir "$(dirname "$shim_path")"
  cat >"$shim_path" <<'SH'
#!/usr/bin/env bash
exec docker run --rm -it ghcr.io/eklairs/tlock:latest "$@"
SH
  chmod +x "$shim_path"
  ensure_path_entry "$HOME/.local/bin"
  log "Installed docker-based tlock shim at $shim_path"
}

verify() {
  if have tlock; then
    log "Verified: tlock shim present"
  else
    log "Missing: tlock"
    return 1
  fi
}

case "${1:-install}" in
  install) install ;;
  verify) verify ;;
  *) echo "usage: $0 [install|verify]" >&2; exit 2 ;;
esac

