use anyhow::anyhow;
use mongodb::{
    bson::{doc, Document},
    options::IndexOptions,
    Client, IndexModel,
};

use crate::{
    constants::{DATABASE_NAME, DATABASE_SESSIONS, DATABASE_USERS},
    routes::User,
    utils::hash_password,
};

pub async fn load_database(config: &config::Config) -> anyhow::Result<mongodb::Client> {
    let database_uri = config.get_string("database.uri")?;
    let database_client = mongodb::Client::with_uri_str(database_uri)
        .await
        .map_err(|err| anyhow!("Could not get database client. Reason: {}", err))?;
    perform_migrations(&database_client, config).await?;
    Ok(database_client)
}

async fn perform_migrations(client: &Client, config: &config::Config) -> anyhow::Result<()> {
    let database = client.database(DATABASE_NAME);
    let databases = database.list_collection_names(None).await?;

    //Setup the user collection
    if !databases.contains(&DATABASE_USERS.to_string()) {
        let email = config.get_string("database.admin.email")?;
        let password = hash_password(&config.get_string("database.admin.password")?)?;

        database.create_collection(DATABASE_USERS, None).await?;

        database
            .collection::<Document>(DATABASE_USERS)
            .create_index(
                IndexModel::builder()
                    .keys(doc! {"email": 1})
                    .options(IndexOptions::builder().unique(true).build())
                    .build(),
                None,
            )
            .await?;

        let admin_user = User::new(email, password);

        database
            .collection::<User>(DATABASE_USERS)
            .insert_one(admin_user, None)
            .await?;
    }

    if !databases.contains(&DATABASE_SESSIONS.to_string()) {
        database.create_collection(DATABASE_SESSIONS, None).await?;
        database
            .collection::<Document>(DATABASE_SESSIONS)
            .create_index(
                IndexModel::builder()
                    .keys(doc! {"user": 1})
                    .options(IndexOptions::builder().unique(true).build())
                    .build(),
                None,
            )
            .await?;
    };

    Ok(())
}
