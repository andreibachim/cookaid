use std::str::FromStr;

use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Extension, Json,
};
use mongodb::{
    bson::{doc, oid::ObjectId, Document},
    ClientSession,
};
use serde::{Deserialize, Serialize};

use crate::{
    constants::{DATABASE_NAME, DATABASE_RECIPES, DATABASE_USERS},
    AppState,
};

use super::{
    ingredient::{Ingredient, OutgoingIngredientDetails},
    login::Session,
    step::{OutgoingStep, Step},
    User,
};

pub async fn get(
    State(state): State<AppState>,
    Path(recipe_id): Path<String>,
) -> impl IntoResponse {
    let database = state.mongo_client.database(DATABASE_NAME);
    match database
        .collection::<Recipe>(DATABASE_RECIPES)
        .find_one(
            doc! {"_id":  ObjectId::from_str(&recipe_id).unwrap() },
            None,
        )
        .await
    {
        Ok(recipe_option) => match recipe_option {
            Some(recipe) => Json(OutgoingRecipeDetails::from(recipe)).into_response(),
            None => StatusCode::NOT_FOUND.into_response(),
        },
        Err(error) => {
            log::error!("Could not get recipe details. Reason: {}", error);
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

pub async fn get_all(
    State(state): State<AppState>,
    Extension(session): Extension<Session>,
) -> impl IntoResponse {
    let database = state.mongo_client.database(DATABASE_NAME);

    let recipes_of_user = match database
        .collection::<User>(DATABASE_USERS)
        .find_one(doc! {"_id": session.user_object_id() }, None)
        .await
    {
        Ok(user_option) => user_option.map(|user| user.recipes()).unwrap_or(vec![]),
        Err(_error) => return StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    };

    match state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<Recipe>(DATABASE_RECIPES)
        .find(doc! {"_id": { "$in" : recipes_of_user }}, None)
        .await
    {
        Ok(mut cursor) => {
            let mut recipe_ids: Vec<OutgoingRecipe> = vec![];
            while cursor.advance().await.expect("Could not advance cursor") {
                let _ = cursor.deserialize_current().and_then(|recipe| {
                    recipe_ids.push(OutgoingRecipe::from(recipe));
                    Ok(())
                });
            }
            Json(recipe_ids).into_response()
        }
        Err(_error) => return StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    }
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
        .expect("Could not convert to ObjectId")
        .to_string())
}

pub async fn update(
    State(state): State<AppState>,
    Extension(session): Extension<Session>,
    Path(recipe_id): Path<String>,
    Json(payload): Json<UpdateRecipeRequest>,
) -> impl IntoResponse {
    let recipe_id = match ObjectId::from_str(&recipe_id) {
        Ok(id) => id,
        Err(error) => {
            log::error!(
                "Could not process recipe_id path segment. Reason: {}",
                error
            );
            return StatusCode::BAD_REQUEST.into_response();
        }
    };

    //Update the recipe in the database
    match state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<Recipe>(DATABASE_RECIPES)
        .update_one(
            doc! {"_id": recipe_id, "owner": session.user_object_id() },
            doc! { "$set": Document::from(payload) },
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
            log::error!("Could not update recipe. Reason: {}", error);
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
    .into_response()
}

pub async fn remove(
    State(state): State<AppState>,
    Extension(session): Extension<Session>,
    Path(recipe_id): Path<String>,
) -> impl IntoResponse {
    let recipe_id = match ObjectId::from_str(&recipe_id) {
        Ok(object_id) => object_id,
        Err(error) => {
            log::error!(
                "Could not process recipe_id path segment. Reason: {}",
                error
            );
            return StatusCode::INTERNAL_SERVER_ERROR;
        }
    };

    match state
        .mongo_client
        .database(DATABASE_NAME)
        .collection::<Recipe>(DATABASE_RECIPES)
        .delete_one(
            doc! {"_id": recipe_id, "owner": session.user_object_id()},
            None,
        )
        .await
    {
        Ok(result) => {
            log::info!("{:#?}", result);
            StatusCode::OK
        }
        Err(error) => {
            log::error!(
                "Could not delete recipe {}. Reason: {}",
                recipe_id.to_string(),
                error
            );
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateRecipeRequest {
    name: String,
}

#[derive(Serialize)]
pub struct CreateRecipeResponse {
    recipe_id: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct UpdateRecipeRequest {
    description: Option<String>,
    external_reference: Option<String>,
    name: Option<String>,
}

impl From<UpdateRecipeRequest> for Document {
    fn from(value: UpdateRecipeRequest) -> Self {
        let mut document = Self::new();
        if value.name.is_some() {
            document.insert("name", value.name);
        }

        if value.description.is_some() {
            document.insert("description", value.description);
        }

        if value.external_reference.is_some() {
            document.insert("external_reference", value.external_reference);
        }
        document
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Recipe {
    _id: ObjectId,
    owner: ObjectId,
    status: RecipeStatus,
    name: String,
    description: Option<String>,
    external_reference: Option<String>,
    ingredients: Vec<Ingredient>,
    steps: Vec<Step>,
}

impl Recipe {
    fn new(name: String, owner: ObjectId) -> Self {
        Self {
            _id: ObjectId::new(),
            owner,
            status: RecipeStatus::DRAFT,
            name,
            description: None,
            external_reference: None,
            ingredients: vec![],
            steps: vec![],
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
enum RecipeStatus {
    DRAFT,
    COMPLETED,
}

#[derive(Serialize)]
pub struct OutgoingRecipeDetails {
    id: String,
    status: RecipeStatus,
    name: String,
    description: Option<String>,
    external_reference: Option<String>,
    ingredients: Vec<OutgoingIngredientDetails>,
    steps: Vec<OutgoingStep>,
}

impl From<Recipe> for OutgoingRecipeDetails {
    fn from(value: Recipe) -> Self {
        Self {
            id: value._id.to_string(),
            status: value.status,
            name: value.name,
            description: value.description,
            external_reference: value.external_reference,
            ingredients: value
                .ingredients
                .into_iter()
                .map(OutgoingIngredientDetails::from)
                .collect(),
            steps: value.steps.into_iter().map(OutgoingStep::from).collect(),
        }
    }
}

#[derive(Serialize)]
pub struct OutgoingRecipe {
    name: String,
    recipe_id: String,
    status: RecipeStatus,
}

impl From<Recipe> for OutgoingRecipe {
    fn from(value: Recipe) -> Self {
        Self {
            name: value.name,
            recipe_id: value._id.to_string(),
            status: value.status,
        }
    }
}
