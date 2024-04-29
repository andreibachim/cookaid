mod create;
mod step_request;
mod step_type;

pub use create::create;

use step_request::StepRequest;

use bson::oid::ObjectId;
use serde::{Deserialize, Serialize};

use self::step_type::StepType;

#[derive(Debug, Serialize, Deserialize)]
pub struct Step {
    _id: ObjectId,
    step_type: StepType,
    text: String,
}

impl From<StepRequest> for Step {
    fn from(value: StepRequest) -> Self {
        Self {
            _id: ObjectId::new(),
            step_type: value.step_type,
            text: value.text,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OutgoingStep {
    id: String,
    step_type: StepType,
    text: String,
}

impl From<Step> for OutgoingStep {
    fn from(value: Step) -> Self {
        Self {
            id: value._id.to_string(),
            step_type: value.step_type,
            text: value.text,
        }
    }
}
