use impl_stubs::{
    ci_deployments::*,
    docker_tui::*,
    env_sync::*,
    test_logs::*,
    tui_install::*,
    win_container::*,
    wsl::*,
};

#[test]
fn tui_install_stubs_ok() {
    assert!(install_diskonaut().is_ok());
    assert!(install_gdu().is_ok());
    assert!(install_ncdu().is_ok());
    assert!(install_xplr().is_ok());
    assert!(install_wego().is_ok());
    assert!(install_nemu().is_ok());
    assert!(install_kitty().is_ok());
    assert!(install_iterm2().is_ok());
    assert!(install_distrobox_tui().is_ok());
    assert!(install_gif_for_cli().is_ok());
    assert!(install_ttyper().is_ok());
    assert!(install_tray_tui().is_ok());
    assert!(install_tlock().is_ok());
}

#[test]
fn env_sync_stubs_ok() {
    assert!(generate_kitty_env().is_ok());
    assert!(generate_iterm_launcher().is_ok());
    assert!(generate_iterm_dynamic_profile().is_ok());
}

#[test]
fn docker_tui_stubs_ok() {
    assert!(resolve_tui_image(None).is_ok());
    assert!(run_tui_in_container("image", "/work", "echo ok").is_ok());
    assert!(run_tuis_from_file("/dev/null", None).is_ok());
}

#[test]
fn wsl_stubs_ok() {
    assert!(ensure_wsl().is_ok());
    assert!(launch_wsl_like_container().is_ok());
}

#[test]
fn windows_container_stubs_ok() {
    assert!(build_windows_image().is_ok());
    assert!(run_windows_container().is_ok());
}

#[test]
fn ci_deployments_stubs_ok() {
    assert!(generate_deployments_catalog().is_ok());
    assert!(generate_release_body().is_ok());
}

#[test]
fn test_logs_stubs_ok() {
    assert!(run_docker_tests_capture_csv().is_ok());
    assert!(convert_csv_to_yaml().is_ok());
}

