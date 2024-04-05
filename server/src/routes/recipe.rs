use axum::{extract::State, response::IntoResponse, Extension};

use crate::AppState;

use super::login::Session;

pub async fn get_all(
    State(_app_state): State<AppState>,
    Extension(_session): Extension<Session>,
) -> impl IntoResponse {
    ().into_response()
}
