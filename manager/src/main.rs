use anyhow::bail;
use anyhow::Result;
use axum::routing::get;
use axum::Router;
use serde::Deserialize;
use std::env;
use std::process::exit;
use std::process::Stdio;
use tokio::io::AsyncWriteExt;
use tokio::process::Command;
use tracing::error;
use tracing::info;

mod github;

#[derive(Deserialize)]
pub struct Config {
    pub github_access_token: String,
    pub github_org: String,
}

async fn launch_runner(config: &Config) -> Result<()> {
    // Create runner
    let org_url = format!("https://github.com/{user}", user = config.github_org);
    info!("configure runner for organization `{org_url}`");
    // Fetch creation token
    let creation_token = github::get_creation_token(config).await?;
    // Configure runner
    let mut config_handle = Command::new("./config.sh")
        .current_dir("runner/")
        .arg("--url")
        .arg(org_url)
        .arg("--token")
        .arg(creation_token)
        .stdin(Stdio::piped())
        .spawn()?;
    let config_stdin = config_handle.stdin.as_mut().unwrap();
    config_stdin.write_all(&[b'\n'; 5]).await?;
    let status = config_handle.wait().await?;
    if !status.success() {
        bail!("could not configure runner");
    }
    // Run
    let mut run_handle = Command::new("./run.sh")
        .current_dir("runner/")
        .env_remove("GITHUB_ACCESS_TOKEN")
        .spawn()?;
    run_handle.wait().await?;
    Ok(())
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    env::set_var("RUST_LOG", "info");
    tracing_subscriber::fmt::init();
    let config: Config = envy::from_env().unwrap();
    let app = Router::new()
        .route("/", get(health))
        .route("/health", get(health));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    let res = tokio::select! {
        res = launch_runner(&config) => res,
        res = async {
            axum::serve(listener, app).await?;
            Ok(())
        } => res,
    };
    match res {
        Ok(_) => info!("exiting without failure"),
        Err(error) => {
            error!(%error, "runner failure");
            exit(1);
        }
    }
}

async fn health() -> &'static str {
    "OK"
}
