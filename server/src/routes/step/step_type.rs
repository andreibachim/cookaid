use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub enum StepType {
    Normal,
    Timer(u64),
}
