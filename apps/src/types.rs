use alloy_primitives::U256;
use serde::{Deserialize, Serialize};
use warp;

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ProofRequest {
    pub attributes: String,
    pub token_id: U256,
    pub cid: String,
}

#[derive(Serialize)]
pub struct ProofResponse {
    pub seal: Vec<u8>,
    pub token_id: U256,
}

#[derive(Debug)]
pub struct ProofGenerationFailed;
impl warp::reject::Reject for ProofGenerationFailed {}

#[derive(Debug)]
pub struct PolicyRetrievalFailed;
impl warp::reject::Reject for PolicyRetrievalFailed {}
