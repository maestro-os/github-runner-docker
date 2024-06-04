use anyhow::bail;
use anyhow::Result;
use axum::routing::get;
use axum::Router;
use config::Config;
use std::fs;
use std::io;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;
use std::process::Stdio;
use tracing::info;

mod config;
mod github;

async fn launch_runners(config: &Config) -> Result<()> {
    // Cleanup if runners already exist
    let res = fs::remove_dir_all("runners/");
    match res {
        Err(e) if e.kind() != io::ErrorKind::NotFound => bail!(e),
        _ => {}
    }
    // Create runners
    for repo in &config.repos {
        let repo_url = format!(
            "https://github.com/{user}/{repo}",
            user = config.github_user
        );
        info!("configure runner for repository `{repo_url}`");
        let path = PathBuf::from(format!("runners/{repo}"));
        fs::create_dir_all(&path)?;
        // Unzip
        let status = Command::new("tar")
            .arg("xzf")
            .arg("actions-runner.tar.gz")
            .arg("-C")
			.arg(&path)
            .status()
            .unwrap();
        if !status.success() {
            // TODO
            todo!()
        }
        // Fetch creation token
        let creation_token = github::get_creation_token(config, repo).await?;
        // Configure runner
        let mut config_handle = Command::new(path.join("config.sh"))
            .arg("--url")
            .arg(repo_url)
            .arg("--token")
            .arg(creation_token)
            .stdin(Stdio::piped())
            .spawn()?;
        let config_stdin = config_handle.stdin.as_mut().unwrap();
        config_stdin.write_all(&[b'\n'; 5])?;
        let status = config_handle.wait()?;
        if !status.success() {
            // TODO
            todo!()
        }
        // Run
        tokio::spawn(async move {
            let mut _cmd_handle = Command::new(path.join("run.sh")).spawn().unwrap();
            // TODO on failure, re-run
        });
    }
    Ok(())
}

#[tokio::main]
async fn main() {
    let config: Config = envy::from_env().unwrap();
    launch_runners(&config).await.unwrap();
    let app = Router::new()
        .route("/", get(health))
        .route("/health", get(health));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> &'static str {
    "OK"
}
