use anyhow::anyhow;
use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use mongodb::bson::doc;
use serde::{Deserialize, Serialize};

use crate::{constants::DATABASE_NAME, AppState};

use super::User;

const USER_NOT_FOUND_ERROR_MESSAGE: &'static str = "User not found";

pub async fn login(
    State(app_state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> impl IntoResponse {
    let collection = app_state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<User>("users");

    let user = match collection
        .find_one(doc! {"email": &payload.email }, None)
        .await
        .map_err(|error| {
            anyhow!(
                "Could not retrieve the user form the database. Reason: {}",
                error
            )
        })
        .and_then(|user_option| {
            user_option.ok_or(UserNotFound::new(USER_NOT_FOUND_ERROR_MESSAGE).into())
        }) {
        Ok(user) => user,
        Err(existing_user) if existing_user.to_string().eq(USER_NOT_FOUND_ERROR_MESSAGE) => {
            log::error!("No user with the '{}' email was found", &payload.email);
            return StatusCode::BAD_REQUEST.into_response();
        }
        Err(err) => {
            log::error!(
                "Unexpected error when getting user from database. Reason: {}",
                err
            );
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };

    match argon2::verify_encoded(user.password(), payload.password.as_bytes()) {
        Ok(valid) if valid => StatusCode::OK,
        Ok(_) => StatusCode::BAD_REQUEST,
        Err(err) => {
            log::error!("Could not compare password hashes. Reason: {}", err);
            StatusCode::BAD_REQUEST
        }
    }
    .into_response()
}

#[derive(Serialize, Deserialize, Debug)]
pub struct LoginRequest {
    email: String,
    password: String,
}

#[derive(Debug)]
struct UserNotFound {
    message: &'static str,
}

impl From<UserNotFound> for anyhow::Error {
    fn from(value: UserNotFound) -> Self {
        anyhow::Error::msg(value.message)
    }
}

impl UserNotFound {
    pub fn new(message: &'static str) -> Self {
        Self { message }
    }
}
