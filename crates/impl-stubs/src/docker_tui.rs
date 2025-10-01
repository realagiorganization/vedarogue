//! 3. Dockerized TUIs – stubs reflecting scripts/run_tuis_docker.sh

use crate::Result;

/// 3.1 Resolve image from profile/registry
pub fn resolve_tui_image(_profile: Option<&str>) -> Result<String> { Ok(String::new()) }

/// 3.2 Run a TUI command in container
pub fn run_tui_in_container(_image: &str, _workdir: &str, _cmd: &str) -> Result<()> { Ok(()) }

/// 3.3 Run TUIs from a list file
pub fn run_tuis_from_file(_path: &str, _default_profile: Option<&str>) -> Result<()> { Ok(()) }

