use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::{from_fn_with_state, Next},
    response::IntoResponse,
    routing::post,
};
use mongodb::bson::doc;

use crate::{
    constants::{DATABASE_NAME, DATABASE_SESSIONS},
    AppState,
};

mod check_session;
mod encryption_token;
mod login;
mod recipe;
mod register;

mod user;
pub use user::User;

use self::login::Session;

pub fn get(State(app_state): State<AppState>) -> axum::Router {
    axum::Router::new()
        .route("/recipe", axum::routing::get(recipe::get_all))
        .route("/recipe", axum::routing::post(recipe::create))
        .route("/recipe/:recipe_id", axum::routing::put(recipe::update))
        .route("/recipe/:recipe_id", axum::routing::get(recipe::get))
        .route_layer(from_fn_with_state(app_state.clone(), auth_filter))
        .route("/health-check", axum::routing::get(()))
        .route(
            "/encryption-token",
            axum::routing::get(encryption_token::get),
        )
        .route("/register", post(register::register))
        .route("/login", post(login::login))
        .route("/check-session", post(check_session::check_session))
        .with_state(app_state)
}

pub async fn auth_filter(
    State(state): State<AppState>,
    mut request: Request,
    next: Next,
) -> impl IntoResponse {
    let header = match request
        .headers()
        .get("Authorization")
        .map(|header_value| header_value.to_str().ok())
        .flatten()
    {
        Some(bearer_token) if bearer_token.starts_with("Bearer ") => bearer_token,
        Some(_) => return StatusCode::UNAUTHORIZED.into_response(),
        None => return StatusCode::UNAUTHORIZED.into_response(),
    };

    let token = header.replace("Bearer ", "");

    let session = state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<Session>(DATABASE_SESSIONS)
        .find_one(doc! {"token": token }, None)
        .await
        .ok()
        .flatten();

    match session {
        Some(session) => {
            request.extensions_mut().insert(session);
            next.run(request).await
        }
        None => return StatusCode::UNAUTHORIZED.into_response(),
    }
}
