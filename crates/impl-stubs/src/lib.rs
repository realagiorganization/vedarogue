//! Stub implementations for features that are or could be testable.
//! See README.implementations.rust.md for the index (1.x.y references).

pub mod tui_install;
pub mod env_sync;
pub mod docker_tui;
pub mod wsl;
pub mod win_container;
pub mod ci_deployments;
pub mod test_logs;

/// Common error type for stubs
pub type Result<T> = anyhow::Result<T>;

