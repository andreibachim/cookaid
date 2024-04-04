use axum::{extract::State, routing::post};

use crate::AppState;

mod check_session;
mod login;
mod register;

mod user;
pub use user::User;

pub fn get(State(app_state): State<AppState>) -> axum::Router {
    axum::Router::new()
        .route("/health-check", axum::routing::get(()))
        .route("/register", post(register::register))
        .route("/login", post(login::login))
        .route("/check-session", post(check_session::check_session))
        .with_state(app_state)
}
