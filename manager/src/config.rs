use serde::Deserialize;
use serde::Deserializer;

fn comma_separated<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Vec<String>, D::Error> {
    Ok(String::deserialize(deserializer)?
        .split(',')
        .map(|s| s.to_owned())
        .collect())
}

#[derive(Deserialize)]
pub struct Config {
    pub github_access_token: String,
    pub github_user: String,
    #[serde(deserialize_with = "comma_separated")]
    pub repos: Vec<String>,
}
