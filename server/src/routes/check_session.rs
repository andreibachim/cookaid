use anyhow::anyhow;
use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use mongodb::bson::doc;
use serde::{Deserialize, Serialize};

use crate::{
    constants::{DATABASE_NAME, DATABASE_SESSIONS},
    AppState,
};

use super::login::Session;

pub async fn check_session(
    State(app_state): State<AppState>,
    Json(payload): Json<CheckSessionRequest>,
) -> impl IntoResponse {
    let collection = app_state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<Session>(DATABASE_SESSIONS);

    match collection
        .find_one(doc! {"token": &payload.token}, None)
        .await
        .map_err(|error| anyhow!("Could not check session. Reason: {}", error))
        .and_then(|token_option| token_option.ok_or(anyhow!("Token not found.")))
    {
        Ok(_) => StatusCode::OK,
        Err(_) => StatusCode::NOT_FOUND,
    }
    .into_response()
}

#[derive(Serialize, Deserialize)]
pub struct CheckSessionRequest {
    pub token: String,
}
