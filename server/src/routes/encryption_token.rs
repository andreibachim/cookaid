use axum::{extract::State, response::IntoResponse, Json};
use serde::{Deserialize, Serialize};

use crate::AppState;

pub async fn get(State(app_state): State<AppState>) -> impl IntoResponse {
    let config = app_state.config;
    Json(EncryptionTokenResponse {
        secret: config
            .get_string("client.encryption_token")
            .unwrap_or_default(),
    })
}

#[derive(Serialize, Deserialize)]
pub struct EncryptionTokenResponse {
    secret: String,
}
