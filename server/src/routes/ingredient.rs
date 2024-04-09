use anyhow::anyhow;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Extension, Json,
};
use mongodb::bson::{doc, oid::ObjectId, to_bson};
use serde::{Deserialize, Serialize};

use crate::{
    constants::{DATABASE_NAME, DATABASE_RECIPES},
    AppState,
};

use super::{login::Session, recipe::Recipe};

pub async fn create(
    State(state): State<AppState>,
    Extension(session): Extension<Session>,
    Path(recipe_id): Path<String>,
    Json(payload): Json<IngredientAddRequest>,
) -> impl IntoResponse {
    let recipe_id = match ObjectId::parse_str(recipe_id) {
        Ok(recipe_id) => recipe_id,
        Err(error) => {
            log::error!("Could not parse recipe_id. Reason: {}", error);
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };

    let ingredient = match Ingredient::from(payload) {
        Ok(ingredient) => ingredient,
        Err(_) => return StatusCode::BAD_REQUEST.into_response(),
    };

    let update_document = match to_bson(&ingredient) {
        Ok(doc) => doc,
        Err(error) => {
            log::error!(
                "Could not convert Ingredient struct into Bson document. Reason: {}",
                error
            );
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };

    match state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<Recipe>(DATABASE_RECIPES)
        .update_one(
            doc! { "_id": recipe_id, "owner": session.user_object_id() },
            doc! { "$push": { "ingredients": update_document }},
            None,
        )
        .await
    {
        Ok(_) => Json(OutgoingIngredientDetails::from(ingredient)).into_response(),
        Err(error) => {
            log::error!("Could not insert new recipe ingredient. Reason: {}", error);
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

pub async fn delete(
    State(state): State<AppState>,
    Extension(session): Extension<Session>,
    Path(path): Path<(String, String)>,
) -> impl IntoResponse {
    let (recipe_id, ingredient_id) = path;

    let recipe_id = match ObjectId::parse_str(recipe_id) {
        Ok(id) => id,
        Err(err) => {
            log::error!("Could not parse recipe id. Reason: {}", err);
            return StatusCode::BAD_REQUEST;
        }
    };

    let ingredient_id = match ObjectId::parse_str(ingredient_id) {
        Ok(id) => id,
        Err(error) => {
            log::error!("Could not parse ingredient id. Reason: {}", error);
            return StatusCode::BAD_REQUEST;
        }
    };

    match state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<Recipe>(DATABASE_RECIPES)
        .update_one(
            doc! { "_id": recipe_id, "owner": session.user_object_id() },
            doc! { "$pull": {"ingredients": {"_id": ingredient_id }}},
            None,
        )
        .await
    {
        Ok(result) => {
            if result.matched_count == 0 || result.modified_count == 0 {
                StatusCode::NOT_FOUND
            } else {
                StatusCode::OK
            }
        }
        Err(error) => {
            log::error!("Could not delete ingredient. Reason: {}", error);
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Ingredient {
    _id: ObjectId,
    name: String,
}

impl Ingredient {
    fn from(value: IngredientAddRequest) -> anyhow::Result<Self> {
        let _id = ObjectId::new();
        if value.name.is_empty() {
            return Err(anyhow!("Ingredient name is empty"));
        }
        let name = value.name;
        Ok(Self { _id, name })
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct IngredientAddRequest {
    name: String,
}

#[derive(Serialize)]
pub struct OutgoingIngredientDetails {
    id: String,
    name: String,
}

impl From<Ingredient> for OutgoingIngredientDetails {
    fn from(value: Ingredient) -> Self {
        Self {
            id: value._id.to_string(),
            name: value.name,
        }
    }
}
