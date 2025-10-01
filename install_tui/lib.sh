#!/usr/bin/env bash
set -euo pipefail

# Tiny helper library for installer scripts

have() { command -v "$1" >/dev/null 2>&1; }

log() { printf "[install_tui] %s\n" "$*"; }

# OS helpers
os_name() {
  uname -s 2>/dev/null || echo "unknown"
}

is_macos() { [ "$(os_name)" = "Darwin" ]; }
is_linux() { [ "$(os_name)" = "Linux" ]; }

need_brew() {
  if ! have brew; then
    log "Homebrew not found. Please install from https://brew.sh and re-run."
    return 1
  fi
}

ensure_dir() { mkdir -p "$1"; }

ensure_path_entry() {
  case ":${PATH}:" in
    *:"$1":*) ;;
    *) export PATH="$1:$PATH";;
  esac
}

install_formula() {
  local formula=$1
  need_brew
  if brew list --formula --versions "$formula" >/dev/null 2>&1; then
    log "brew formula '$formula' already installed"
  else
    log "Installing brew formula '$formula'"
    brew install "$formula"
  fi
}

install_cask() {
  local cask=$1
  need_brew
  if brew list --cask --versions "$cask" >/dev/null 2>&1; then
    log "brew cask '$cask' already installed"
  else
    log "Installing brew cask '$cask'"
    brew install --cask "$cask"
  fi
}

ensure_cargo() {
  if have cargo; then return 0; fi
  log "cargo not found; attempting to install via brew (rust)"
  install_formula rust
}

ensure_go() {
  if have go; then return 0; fi
  log "go not found; attempting to install via brew"
  install_formula go
}

ensure_pip3() {
  if have pip3; then return 0; fi
  log "pip3 not found; attempting to install python via brew"
  install_formula python
}

verify_cmd() {
  local cmd=$1
  if have "$cmd"; then
    "$cmd" --version >/dev/null 2>&1 || "$cmd" -h >/dev/null 2>&1 || true
    log "Verified: $cmd available"
    return 0
  fi
  log "Missing command: $cmd"
  return 1
}

# Basic Linux package installs (best-effort)
install_linux_pkg() {
  local pkg=$1
  if have apt-get; then
    sudo apt-get update -y && sudo apt-get install -y "$pkg"
    return $?
  elif have dnf; then
    sudo dnf install -y "$pkg"
    return $?
  elif have pacman; then
    sudo pacman -S --noconfirm "$pkg"
    return $?
  fi
  return 1
}
