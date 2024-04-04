mod constants;
mod database;
mod routes;
mod utils;

use anyhow::anyhow;
use axum::extract::State;
use database::load_database;
use tokio::net::TcpListener;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    env_logger::builder()
        .filter_level(log::LevelFilter::Info)
        .init();
    log::info!("Starting application...");

    let config = load_config()?;

    let mongo_client = load_database(&config).await?;

    let app_state = AppState {
        config,
        mongo_client,
    };

    let app = axum::Router::new().nest("/api", routes::get(State(app_state)));

    log::info!("Listening on port '8080'");
    axum::serve(TcpListener::bind("0.0.0.0:8080").await?, app).await?;

    log::info!("Gracefully shutting down...");

    Ok(())
}

#[derive(Clone)]
pub struct AppState {
    pub config: config::Config,
    pub mongo_client: mongodb::Client,
}

fn load_config() -> anyhow::Result<config::Config> {
    config::Config::builder()
        .add_source(config::File::with_name("Config.toml"))
        .add_source(config::Environment::with_prefix("cookaid"))
        .build()
        .map_err(|err| anyhow!("Could not initialize configuration. Reason: {}", err))
}
