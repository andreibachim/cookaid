use mongodb::bson::oid::ObjectId;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct User {
    _id: ObjectId,
    email: String,
    password: String,
}

impl User {
    pub fn new(email: String, password: String) -> Self {
        Self {
            _id: ObjectId::new(),
            email,
            password,
        }
    }

    pub fn id(&self) -> &ObjectId {
        &self._id
    }

    pub fn email(&self) -> &str {
        &self.email
    }

    pub fn password(&self) -> &str {
        &self.password
    }
}
