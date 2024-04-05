use axum::{extract::State, http::StatusCode, response::IntoResponse, Extension, Json};
use mongodb::{
    bson::{doc, oid::ObjectId},
    ClientSession,
};
use serde::{Deserialize, Serialize};

use crate::{
    constants::{DATABASE_NAME, DATABASE_RECIPES, DATABASE_USERS},
    AppState,
};

use super::{login::Session, User};

pub async fn get_all(
    State(_app_state): State<AppState>,
    Extension(_session): Extension<Session>,
) -> impl IntoResponse {
    ().into_response()
}

pub async fn create(
    State(state): State<AppState>,
    Extension(session): Extension<Session>,
    Json(payload): Json<CreateRecipeRequest>,
) -> impl IntoResponse {
    let recipe = Recipe::new(payload.name, session.user_object_id());

    let mut db_session = state
        .mongo_client
        .start_session(None)
        .await
        .expect("Could not database session");

    db_session
        .start_transaction(None)
        .await
        .expect("Could not start new recipe transaction");

    let recipe_id = insert_recipe_transaction(&mut db_session, &recipe)
        .await
        .expect("Could not perform new recipe transaction");

    match db_session.commit_transaction().await {
        Ok(_) => (StatusCode::OK, Json(CreateRecipeResponse { recipe_id })).into_response(),
        Err(error) => {
            log::error!(
                "Could not perform new recipe transaction. Reason: {}",
                error
            );
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

async fn insert_recipe_transaction(
    session: &mut ClientSession,
    recipe: &Recipe,
) -> anyhow::Result<String> {
    let client = session.client();

    let recipe_id = client
        .database(DATABASE_NAME)
        .collection::<Recipe>(DATABASE_RECIPES)
        .insert_one_with_session(recipe, None, session)
        .await?
        .inserted_id;

    client
        .database(DATABASE_NAME)
        .collection::<User>(DATABASE_USERS)
        .update_one_with_session(
            doc! {"_id": &recipe.owner},
            doc! { "$push" : { "recipes": &recipe_id } },
            None,
            session,
        )
        .await?;

    Ok(recipe_id
        .as_object_id()
        .expect("Could not get objectId")
        .to_string())
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateRecipeRequest {
    name: String,
}

#[derive(Serialize)]
pub struct CreateRecipeResponse {
    recipe_id: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Recipe {
    _id: ObjectId,
    owner: ObjectId,
    name: String,
    description: Option<String>,
    external_referrence: Option<String>,
    ingredients: Vec<String>,
    steps: Vec<String>,
}

impl Recipe {
    fn new(name: String, owner: ObjectId) -> Self {
        Self {
            _id: ObjectId::new(),
            owner,
            name,
            description: None,
            external_referrence: None,
            ingredients: vec![],
            steps: vec![],
        }
    }
}
