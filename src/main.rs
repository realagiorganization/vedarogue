use std::env;
use std::path::PathBuf;
use std::process::{Command, Stdio};

use anyhow::{bail, Context, Result};
use clap::{Parser, Subcommand};

#[derive(Parser, Debug)]
#[command(name = "make-runner", version, about = "Run Makefile targets with stdio passthrough")] 
struct Cli {
    /// Working directory where the Makefile lives (default: repo root / CWD)
    #[arg(short, long)]
    workdir: Option<PathBuf>,

    #[command(subcommand)]
    cmd: CommandKind,
}

#[derive(Subcommand, Debug)]
enum CommandKind {
    /// Run a Make target (or multiple targets)
    Run { targets: Vec<String> },
    /// Show Makefile targets (maps to `make list`)
    List,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let workdir = cli.workdir.unwrap_or(env::current_dir()?);
    let make = env::var("MAKE").unwrap_or_else(|_| "make".to_string());

    // Ensure make exists
    which::which(&make).context("`make` not found in PATH. Set MAKE or install make.")?;

    let mut cmd = Command::new(make);
    cmd.current_dir(&workdir)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit());

    match cli.cmd {
        CommandKind::Run { targets } => {
            if targets.is_empty() {
                bail!("No targets provided. Example: make-runner run install-all");
            }
            cmd.args(targets);
        }
        CommandKind::List => {
            cmd.arg("list");
        }
    }

    let status = cmd.status().context("failed to spawn make")?;
    if !status.success() {
        bail!("make exited with status: {}", status);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use assert_cmd::prelude::*;

    #[test]
    fn binary_runs_without_makefile_list() -> Result<()> {
        // Skip if `make` is not available on the runner (e.g., Windows without make)
        if which::which("make").is_err() {
            return Ok(());
        }
        // Should run `make list` in repo root; our Makefile exists
        let mut cmd = Command::cargo_bin("make-runner")?;
        cmd.arg("list");
        let status = cmd.status()?;
        assert!(status.success());
        Ok(())
    }
}
