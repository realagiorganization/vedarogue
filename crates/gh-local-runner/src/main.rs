use anyhow::{bail, Context, Result};
use clap::{Parser, Subcommand};
use indexmap::IndexMap;
use serde::Deserialize;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

#[derive(Parser, Debug)]
#[command(name = "gh-local-runner", version, about = "Run GitHub Actions workflows locally (host-exec)")] 
struct Cli {
    /// Path to workflow file (YAML)
    #[arg(short, long, default_value = ".github/workflows/cargo-ci.yml")]
    workflow: PathBuf,
    /// Job id to run (as in YAML jobs map). If omitted, runs all top-level jobs sequentially.
    #[arg(short, long)]
    job: Option<String>,
    /// Only print what would be done, without executing steps
    #[arg(long)]
    dry_run: bool,
}

#[derive(Deserialize, Debug)]
struct Workflow {
    jobs: IndexMap<String, Job>,
}

#[derive(Deserialize, Debug)]
struct Job {
    #[serde(default)]
    steps: Vec<Step>,
    #[serde(default)]
    env: HashMap<String, String>,
}

#[derive(Deserialize, Debug)]
struct Step {
    #[serde(default)]
    name: Option<String>,
    #[serde(default)]
    r#uses: Option<String>,
    #[serde(default)]
    run: Option<String>,
    #[serde(default)]
    env: HashMap<String, String>,
    #[serde(default)]
    with: HashMap<String, serde_yaml::Value>,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let wf = load_workflow(&cli.workflow)?;
    if let Some(job_id) = cli.job.as_deref() {
        let job = wf.jobs.get(job_id).with_context(|| format!("job '{}' not found", job_id))?;
        run_job(job_id, job, &cli)?;
    } else {
        for (job_id, job) in &wf.jobs {
            println!("==> Running job: {}", job_id);
            run_job(job_id, job, &cli)?;
        }
    }
    Ok(())
}

fn load_workflow(path: &Path) -> Result<Workflow> {
    let s = fs::read_to_string(path).with_context(|| format!("reading workflow: {}", path.display()))?;
    let wf: Workflow = serde_yaml::from_str(&s).with_context(|| "parsing workflow yaml")?;
    Ok(wf)
}

fn run_job(job_id: &str, job: &Job, cli: &Cli) -> Result<()> {
    for (idx, step) in job.steps.iter().enumerate() {
        let title = step.name.as_deref().unwrap_or_else(|| step.r#uses.as_deref().unwrap_or("(run)"));
        println!("[{}:{}] {}", job_id, idx + 1, title);
        run_step(job, step, cli)?;
    }
    Ok(())
}

fn run_step(job: &Job, step: &Step, cli: &Cli) -> Result<()> {
    if let Some(uses) = step.r#uses.as_deref() {
        emulate_action(uses, step, cli)?;
        return Ok(());
    }
    if let Some(script) = step.run.as_deref() {
        run_shell(script, &merge_env(&job.env, &step.env), cli)?;
        return Ok(());
    }
    Ok(())
}

fn merge_env(a: &HashMap<String, String>, b: &HashMap<String, String>) -> HashMap<String, String> {
    let mut m = a.clone();
    for (k, v) in b {
        m.insert(k.clone(), v.clone());
    }
    m
}

fn run_shell(script: &str, env: &HashMap<String, String>, cli: &Cli) -> Result<()> {
    if cli.dry_run {
        println!("DRY: bash -lc \n{}", script);
        return Ok(());
    }
    let mut cmd = Command::new("bash");
    cmd.arg("-lc").arg(script);
    for (k, v) in env {
        cmd.env(k, v);
    }
    cmd.stdin(Stdio::inherit()).stdout(Stdio::inherit()).stderr(Stdio::inherit());
    let status = cmd.status().context("failed to spawn bash")?;
    if !status.success() { bail!("step failed with status: {}", status); }
    Ok(())
}

fn emulate_action(uses: &str, step: &Step, cli: &Cli) -> Result<()> {
    // Minimal emulation for common actions in this repo's workflow
    match uses {
        s if s.starts_with("actions/checkout@") => {
            println!("- emulate: checkout (noop, repo already present)");
            Ok(())
        }
        s if s.starts_with("dtolnay/rust-toolchain@") => {
            let comps = step.with.get("components").and_then(|v| v.as_str()).unwrap_or("");
            let script = format!("rustup toolchain install stable || true; rustup default stable || true; if [ -n '{comps}' ]; then rustup component add {comps}; fi");
            run_shell(&script, &step.env, cli)
        }
        s if s.starts_with("docker/setup-buildx-action@") => {
            println!("- emulate: docker buildx setup (noop)");
            Ok(())
        }
        s if s.starts_with("docker/login-action@") => {
            let registry = step.with.get("registry").and_then(|v| v.as_str()).unwrap_or("ghcr.io");
            let username = std::env::var("GITHUB_ACTOR").unwrap_or_else(|_| "local".to_string());
            let password = std::env::var("GITHUB_TOKEN").unwrap_or_default();
            if password.is_empty() {
                println!("- skip docker login (GITHUB_TOKEN empty)");
                return Ok(());
            }
            let script = format!("echo '${password}' | docker login {registry} -u {username} --password-stdin");
            run_shell(&script, &step.env, cli)
        }
        s if s.starts_with("actions/upload-artifact@") => {
            println!("- emulate: upload-artifact (noop; files remain in workspace)");
            Ok(())
        }
        s if s.starts_with("actions/download-artifact@") => {
            println!("- emulate: download-artifact (noop; expects local artifacts)");
            Ok(())
        }
        s if s.starts_with("softprops/action-gh-release@") => {
            println!("- emulate: create GitHub release (noop in local runner)");
            Ok(())
        }
        other => {
            println!("- unknown action '{}': skipping", other);
            Ok(())
        }
    }
}

