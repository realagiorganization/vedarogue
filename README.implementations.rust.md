# Rust Implementation Stubs Index

This document catalogs stubbed Rust entry points for features that are or could be testable. Each item is referenced with a hierarchical 1.2.3 style.

1. TUI Installers (`crates/impl-stubs/src/tui_install.rs`)
   - 1.1: `install_diskonaut()`
   - 1.2: `install_gdu()`
   - 1.3: `install_ncdu()`
   - 1.4: `install_xplr()`
   - 1.5: `install_wego()`
   - 1.6: `install_nemu()`
   - 1.7: `install_kitty()`
   - 1.8: `install_iterm2()`
   - 1.9: `install_distrobox_tui()`
   - 1.10: `install_gif_for_cli()`
   - 1.11: `install_ttyper()`
   - 1.12: `install_tray_tui()`
   - 1.13: `install_tlock()`

2. Env Sync (`crates/impl-stubs/src/env_sync.rs`)
   - 2.1: `generate_kitty_env()`
   - 2.2: `generate_iterm_launcher()`
   - 2.3: `generate_iterm_dynamic_profile()`

3. Dockerized TUIs (`crates/impl-stubs/src/docker_tui.rs`)
   - 3.1: `resolve_tui_image(profile)`
   - 3.2: `run_tui_in_container(image, workdir, cmd)`
   - 3.3: `run_tuis_from_file(path, default_profile)`

4. WSL Setup (`crates/impl-stubs/src/wsl.rs`)
   - 4.1: `ensure_wsl()`
   - 4.2: `launch_wsl_like_container()`

5. Windows Container (`crates/impl-stubs/src/win_container.rs`)
   - 5.1: `build_windows_image()`
   - 5.2: `run_windows_container()`

6. CI Deployments & Releases (`crates/impl-stubs/src/ci_deployments.rs`)
   - 6.1: `generate_deployments_catalog()`
   - 6.2: `generate_release_body()`

7. Docker Test Logs (`crates/impl-stubs/src/test_logs.rs`)
   - 7.1: `run_docker_tests_capture_csv()`
   - 7.2: `convert_csv_to_yaml()`

Notes:
- These are intentionally stubs (no-op implementations) that compile and provide typed entry points for future work and unit tests.
- Aligns with scripts and Makefile targets currently in the repository.

