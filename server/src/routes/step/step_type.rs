use std::time::Duration;

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub enum StepType {
    NORMAL,
    TIMER(Duration),
}
