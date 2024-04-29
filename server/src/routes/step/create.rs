use super::{Step, StepRequest};
use std::str::FromStr;

use axum::{
    extract::{Json, Path, State},
    http::StatusCode,
    response::IntoResponse,
    Extension,
};
use bson::{doc, oid::ObjectId, to_bson};

use crate::{
    constants::{DATABASE_NAME, DATABASE_RECIPES},
    routes::{login::Session, recipe::Recipe, step::OutgoingStep},
    AppState,
};

pub async fn create(
    State(state): State<AppState>,
    Extension(session): Extension<Session>,
    Path(recipe_id): Path<String>,
    Json(payload): Json<StepRequest>,
) -> impl IntoResponse {
    let recipe_id = match ObjectId::from_str(&recipe_id) {
        Ok(id) => id,
        Err(error) => {
            log::error!("Could not parse recipe id. Reason: {}", error);
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };
    let step = Step::from(payload);

    let update_document = match to_bson(&step) {
        Ok(doc) => doc,
        Err(error) => {
            log::error!("Could not convert step into bson. Reason: {}", error);
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };

    match state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<Recipe>(DATABASE_RECIPES)
        .update_one(
            doc! {"_id": recipe_id, "owner": session.user_object_id()},
            doc! {"$push": { "steps": update_document }},
            None,
        )
        .await
    {
        Ok(result) => {
            if result.matched_count == 0 || result.modified_count == 0 {
                StatusCode::NOT_FOUND.into_response()
            } else {
                Json(OutgoingStep::from(step)).into_response()
            }
        }
        Err(error) => {
            log::error!("Could not insert step to recipe. Reason: {}", error);
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}
