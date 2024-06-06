use crate::Config;
use anyhow::Result;
use serde::Deserialize;

/// The Github API version.
const API_VERSION: &str = "2022-11-28";
/// The Github API user agent.
const USER_AGENT: &str = "maestro";

#[derive(Deserialize)]
struct GithubRegistrationToken {
    token: String,
}

pub async fn get_creation_token(config: &Config) -> Result<String> {
    let url = format!(
        "https://api.github.com/orgs/{owner}/actions/runners/registration-token",
        owner = config.github_org
    );
    let client = reqwest::Client::new();
    let body: GithubRegistrationToken = client
        .post(url)
        .header("Accept", "application/json")
        .header(
            "Authorization",
            format!("Bearer {}", config.github_access_token),
        )
        .header("User-Agent", USER_AGENT)
        .header("X-GitHub-Api-Version", API_VERSION)
        .send()
        .await?
        .json()
        .await?;
    Ok(body.token)
}
