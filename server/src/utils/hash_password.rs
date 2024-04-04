use anyhow::anyhow;
use mongodb::bson::Uuid;

pub fn hash_password(password: &str) -> anyhow::Result<String> {
    argon2::hash_encoded(
        password.as_bytes(),
        Uuid::new().to_string().as_bytes(),
        &argon2::Config::default(),
    )
    .map_err(|err| anyhow!("Could not hash password. Reason: {}.", err))
}
