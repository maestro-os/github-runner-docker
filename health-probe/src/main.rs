use axum::routing::get;
use axum::Router;
use std::process::exit;
use std::process::Command;

#[tokio::main]
async fn main() {
    let mut cmd_handle = Command::new("./run.sh").spawn().unwrap();
    tokio::spawn(async move {
        let status = cmd_handle.wait().unwrap().code().unwrap();
        exit(status);
    });
    let app = Router::new()
        .route("/", get(health))
        .route("/health", get(health));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    let res = axum::serve(listener, app).await;
    let status = match res {
        Ok(_) => 0,
        Err(_) => 1,
    };
    exit(status);
}

async fn health() -> &'static str {
    "OK"
}
