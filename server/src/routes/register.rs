use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use serde::{Deserialize, Serialize};

use crate::{constants::DATABASE_NAME, utils::hash_password, AppState};

use super::User;

pub async fn register(
    State(app_state): State<AppState>,
    Json(payload): Json<RegisterRequest>,
) -> impl IntoResponse {
    let collection = app_state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<User>("users");

    let password = match hash_password(&payload.password) {
        Ok(password) => password,
        Err(err) => {
            log::error!("{err}");
            return (StatusCode::INTERNAL_SERVER_ERROR).into_response();
        }
    };

    let user = User::new(payload.email, password);

    match collection.insert_one(&user, None).await {
        Ok(_) => {
            log::info!(
                "Succesfully create a new user with email '{}'",
                user.email()
            );
            StatusCode::OK
        }
        Err(write_error) if write_error.kind.to_string().contains("E11000") => {
            log::warn!("An user with the '{}' email already exists", user.email());
            StatusCode::CONFLICT
        }
        Err(error) => {
            log::error!("Could not insert new user. Reason: {}", error);
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
    .into_response()
}

#[derive(Serialize, Deserialize, Debug)]
pub struct RegisterRequest {
    email: String,
    password: String,
}
