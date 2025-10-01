.PHONY: help list install-all verify-all install-% verify-%

TOOLS = diskonaut gdu ncdu xplr wego nemu kitty iterm2 distrobox-tui gif-for-cli ttyper tray-tui tlock

help: list

list:
	@echo "Available tools: $(TOOLS)"
	@echo "Targets: install-<tool>, verify-<tool>, install-all, verify-all, install-win, install-win-docker, install-wsl, install-wsl-in-docker, cargo-* , docker-make-runner-*"

install-all: $(TOOLS:%=install-% )
	@echo "All installs attempted."

verify-all: $(TOOLS:%=verify-% )
	@echo "All verifies attempted."

install-%:
	@bash install_tui/$*.sh install

verify-%:
	@bash install_tui/$*.sh verify

.PHONY: install-win
install-win:
	@echo "Running Windows installer via PowerShell"
	@powershell -NoProfile -ExecutionPolicy Bypass -File install_tui/install_win.ps1 || \
	  pwsh -NoProfile -ExecutionPolicy Bypass -File install_tui/install_win.ps1

.PHONY: install-win-docker
# Build and run a persistent Windows container with the repository mounted.
# Requires: Docker Desktop on Windows in Windows containers mode.
install-win-docker:
	@set -e; \
	OS=$$(uname -s 2>/dev/null || echo Windows_NT); \
	SERVER_OS=$$(docker version -f '{{.Server.Os}}' 2>/dev/null || echo unknown); \
	if [ "$$SERVER_OS" != "windows" ]; then \
	  echo "ERROR: Docker server OS is '$$SERVER_OS'. Please run on Windows with Docker in Windows containers mode."; \
	  exit 1; \
	fi; \
	if [ "$$OS" = "Windows_NT" ]; then \
	  HOST_PWD=$$(powershell -NoProfile -Command "(Resolve-Path .).Path" | tr -d '\r'); \
	else \
	  HOST_PWD=$$(pwd); \
	fi; \
	echo "Building Windows image 'tui-win:latest'..."; \
	docker build -f docker/windows/Dockerfile -t tui-win:latest .; \
	echo "Creating persistent volume 'tui-win-home' (if missing)..."; \
	docker volume inspect tui-win-home >/dev/null 2>&1 || docker volume create tui-win-home >/dev/null; \
	if docker ps -a --format '{{.Names}}' | grep -q '^tui-win$$'; then \
	  echo "Container 'tui-win' already exists."; \
	  if [ "$$(docker inspect -f '{{.State.Running}}' tui-win)" != "true" ]; then \
	    echo "Starting existing container 'tui-win'..."; \
	    docker start tui-win >/dev/null; \
	  fi; \
	  echo "Attach with: docker exec -it tui-win powershell"; \
	else \
	  echo "Launching new persistent container 'tui-win'..."; \
	  env_flags=; \
	  while IFS= read -r name; do \
	    [ -z "$$name" ] && continue; \
	    case "$$name" in \#*) continue;; esac; \
	    val=$$(printenv "$$name"); \
	    [ -n "$$val" ] && env_flags="$$env_flags -e $$name"; \
	  done < install_tui/LIST_OF_ENV_VARIABLES_TO_IMPORT; \
	  docker run -d --restart unless-stopped --name tui-win --hostname tui-win \
	    -v tui-win-home:C:\\Users\\ContainerUser \
	    -v "$$HOST_PWD:C:\\work" \
	    $$env_flags \
	    tui-win:latest >/dev/null; \
	  echo "Container started. Attach with: docker exec -it tui-win powershell"; \
	fi
	@echo "Attempting to setup WSL on host (best-effort)..."
	@$(MAKE) --no-print-directory install-wsl
	@echo "Attempting to setup Linux dev container (WSL-in-docker equivalent)..."
	@$(MAKE) --no-print-directory install-wsl-in-docker
	@echo "Syncing environment variables for kitty/iTerm2..."
	@$(MAKE) --no-print-directory env-sync

.PHONY: env-sync install-iterm2-dynamic-profile print-kitty-include
env-sync:
	@bash install_tui/env_sync.sh

# Install iTerm2 Dynamic Profile by copying it to user's DynamicProfiles directory
install-iterm2-dynamic-profile: env-sync
	@set -e; \
	PROFILE_DIR="$$HOME/Library/Application Support/iTerm2/DynamicProfiles"; \
	mkdir -p "$$PROFILE_DIR"; \
	cp install_tui/generated/iterm2_dynamic_profile.json "$$PROFILE_DIR/tui-env-profile.json"; \
	echo "Installed dynamic profile to: $$PROFILE_DIR/tui-env-profile.json"; \
	echo "Open iTerm2 Preferences > Profiles to see 'TUI Env Profile'."

# Print kitty include line to add generated env config to kitty.conf
print-kitty-include: env-sync
	@absfile=$$(python3 -c 'import os,sys; print(os.path.abspath("install_tui/generated/kitty_env.conf"))'); \
	echo "Add this line to your kitty.conf:"; \
	echo "  include $$absfile"

.PHONY: install-wsl
# Installs WSL with Ubuntu on Windows hosts (best-effort; may require admin and reboot)
install-wsl:
	@set -e; \
	OS=$$(uname -s 2>/dev/null || echo Windows_NT); \
	if [ "$$OS" != "Windows_NT" ]; then \
	  echo "install-wsl: host OS is not Windows; skipping."; \
	  exit 0; \
	fi; \
	if command -v powershell >/dev/null 2>&1; then PSH=powershell; \
	elif command -v pwsh >/dev/null 2>&1; then PSH=pwsh; \
	else echo "install-wsl: PowerShell not found"; exit 0; fi; \
	$$PSH -NoProfile -ExecutionPolicy Bypass -Command "\
	  if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {\
	    Write-Host 'WSL executable not found. Attempting wsl --install (requires admin).';\
	    try { wsl --install } catch { Write-Host 'Please run an elevated PowerShell and execute: wsl --install' };\
	    exit 0;\
	  }\
	  try { wsl --status | Out-Host } catch { Write-Host 'wsl --status failed (continuing)'; }\
	  try { wsl --list --online | Out-Null } catch { Write-Host 'wsl list failed (continuing)'; }\
	  Write-Host 'Ensuring Ubuntu distribution (may require admin & reboot)...';\
	  try { wsl --install -d Ubuntu } catch { Write-Host 'If this fails, run elevated: wsl --install -d Ubuntu' }"

.PHONY: install-wsl-in-docker
# Creates a persistent Linux container as a WSL-like dev environment (requires Docker Linux containers)
install-wsl-in-docker:
	@set -e; \
	SERVER_OS=$$(docker version -f '{{.Server.Os}}' 2>/dev/null || echo unknown); \
	if [ "$$SERVER_OS" != "linux" ]; then \
	  echo "install-wsl-in-docker: Docker server OS is '$$SERVER_OS'. Switch Docker Desktop to Linux containers and re-run."; \
	  exit 0; \
	fi; \
	HOST_PWD=$$(pwd); \
	echo "Building Linux image 'tui-wsl:latest'..."; \
	docker build -f docker/linux/Dockerfile -t tui-wsl:latest .; \
	echo "Creating persistent volume 'tui-wsl-home' (if missing)..."; \
	docker volume inspect tui-wsl-home >/dev/null 2>&1 || docker volume create tui-wsl-home >/dev/null; \
	if docker ps -a --format '{{.Names}}' | grep -q '^tui-wsl$$'; then \
	  echo "Container 'tui-wsl' already exists."; \
	  if [ "$$(docker inspect -f '{{.State.Running}}' tui-wsl)" != "true" ]; then \
	    echo "Starting existing container 'tui-wsl'..."; \
	    docker start tui-wsl >/dev/null; \
	  fi; \
	  echo "Attach with: docker exec -it tui-wsl bash"; \
	else \
	  echo "Launching new persistent Linux container 'tui-wsl'..."; \
	  docker run -d --restart unless-stopped --name tui-wsl --hostname tui-wsl \
	    -v tui-wsl-home:/home/dev \
	    -v "$$HOST_PWD:/work" \
	    tui-wsl:latest >/dev/null; \
	  echo "Container started. Attach with: docker exec -it tui-wsl bash"; \
	fi

.PHONY: docker-emacs-build docker-emacs-magit docker-emacs-magit-smoke
docker-emacs-build:
	@docker build -f docker/emacs/Dockerfile -t vedarogue/emacs:latest .

# Interactive terminal Emacs showing Magit status for the repo
docker-emacs-magit: docker-emacs-build
	@docker run -it --rm -v "$$PWD:/work" -w /work vedarogue/emacs:latest \
	  -nw --eval "(progn (require 'magit) (magit-status))"

# Non-interactive smoke test for Magit availability
docker-emacs-magit-smoke: docker-emacs-build
	@docker run --rm -v "$$PWD:/work" -w /work vedarogue/emacs:latest \
	  --batch --eval "(progn (require 'magit) (message \"Magit OK\"))"

.PHONY: cargo-build cargo-test cargo-run docker-make-runner-build docker-make-runner-run

cargo-build:
	@cargo build --release

cargo-test:
	@cargo test --all

# usage: make cargo-run ARGS="run install-all" or ARGS="list"
cargo-run:
	@cargo run -- $(ARGS)

docker-make-runner-build:
	@docker build -f docker/cargo/Dockerfile -t make-runner:latest .

# usage: make docker-make-runner-run ARGS="run list"
docker-make-runner-run: docker-make-runner-build
	@docker run -i --rm -v "$$PWD:/work" -w /work make-runner:latest $(ARGS)

.PHONY: docker-tuis
# Launch a list of TUIs inside a Docker image.
# Usage:
#   make docker-tuis TUIS="xplr ncdu" [DOCKER_IMAGE_TUI=image]
# Supports entries of form "subdir:cmd" to set working directory per TUI.
docker-tuis:
	@[ -n "$(TUIS)" ] || { echo "TUIS variable is empty. Example: make docker-tuis TUIS=\"xplr ncdu\""; exit 2; }
	@DOCKER_IMAGE_TUI="$(DOCKER_IMAGE_TUI)" bash scripts/run_tuis_docker.sh $(TUIS)
