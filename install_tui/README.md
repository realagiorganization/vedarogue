# TUI Installer

This folder contains per‑tool install and verify scripts used by the Makefile targets.

Usage (macOS/Linux):

- List tools and targets: `make list`
- Install everything available on your OS: `make install-all`
- Verify availability: `make verify-all`
- Install a single tool: `make install-xplr` (replace with any tool name)

Windows:

- Run: `make install-win`
  - This calls `install_tui/install_win.ps1` using PowerShell.
  - It uses winget/scoop where possible and cargo/go/pip when available.
  - Supported (best-effort): `kitty`, `tlock` (via Scoop), `gif-for-cli` (pip), `diskonaut`, `ttyper`, `tray-tui`, `xplr` (cargo), `wego` (go).
  - Skipped on Windows: `iTerm2`, `nemu`, `gdu`, `ncdu`, `distrobox-tui`.

- Run in Windows container: `make install-win-docker`
  - Builds a Windows Server Core–based image and runs a persistent container named `tui-win`.
  - Requires Docker Desktop on Windows in Windows containers mode.
  - Mounts the repository into `C:\work` inside the container and keeps a named volume `tui-win-home` for the user profile.
  - Attach with: `docker exec -it tui-win powershell`.

- Install WSL on host: `make install-wsl`
  - Best-effort WSL setup using PowerShell (`wsl --install -d Ubuntu`).
  - May require an elevated PowerShell and a reboot.

- Linux dev container (WSL-like): `make install-wsl-in-docker`
  - Builds `tui-wsl:latest` from `docker/linux/Dockerfile` and runs a persistent container `tui-wsl`.
  - Requires Docker Desktop in Linux containers mode.
  - Mounts the repository into `/work` and keeps a named volume `tui-wsl-home` for `/home/dev`.
  - Attach with: `docker exec -it tui-wsl bash`.

Notes:

- macOS: GUI terminals `kitty` and `iTerm2` install as Homebrew casks. CLI tools install via Homebrew/Cargo/Go/Pip.
- Linux: `kitty` attempts to install via your system package manager if available; `iTerm2` is skipped.
- If a language toolchain is missing (cargo/go/python), scripts try to install via Homebrew (macOS). On other platforms, they’ll prompt for manual installation.
- If a tool prints “skipping/not supported”, it’s intentional for that OS.

Environment → Tab/Config sync:

- Define names in `install_tui/LIST_OF_ENV_VARIABLES_TO_IMPORT` (one per line).
- Generate config snippets from current environment: `make env-sync`.
  - Kitty: include the generated file in kitty.conf. Show the include line: `make print-kitty-include`.
  - iTerm2: install Dynamic Profile: `make install-iterm2-dynamic-profile`. It creates a profile that exports vars and sets the tab/window title to `tab_env: VAR=VAL ...`.
