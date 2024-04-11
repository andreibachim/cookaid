use serde::{Deserialize, Serialize};

use super::step_type::StepType;

#[derive(Debug, Serialize, Deserialize)]
pub struct StepRequest {
    pub step_type: StepType,
    pub text: String,
}
