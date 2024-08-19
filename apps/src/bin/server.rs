use std::env;
use std::fmt::Debug;
use std::sync::Arc;

use alloy_primitives::{hex, U256};
use anyhow::Result;
use dotenv::dotenv;

use ethers::types::transaction::response;
// for api
use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;
use tokio::time::{timeout, Duration};
use warp::{filters::log, Filter, Rejection, Reply};

// for proof generation
use apps::proof::prover;

#[derive(Debug, Deserialize, Serialize)]
struct ProofRequest {
    policy: String,
    attributes: String,
    token_id: U256,
    ct_cid: u32,
}

#[derive(Serialize)]
struct ProofResponse {
    seal: Vec<u8>,
    ct_cid: U256,
}

#[derive(Debug)]
struct InvalidTokenId;
impl warp::reject::Reject for InvalidTokenId {}

#[derive(Debug)]
struct ProofGenerationFailed;
impl warp::reject::Reject for ProofGenerationFailed {}

async fn handle_generate_proof(request: ProofRequest) -> Result<impl Reply, Rejection> {
    // let token_id = U256::from(&request.token_id)
    // .map_err(|_| warp::reject::custom(InvalidTokenId))?;

    println!("\nGot Request: \n\n {:?}", &request);

    println!("Generating proof...");
    let result = timeout(
        Duration::from_secs(180), // timeout after 3 min
        // the reason using spawn_blocking is because generate_proof
        // is using another async api to get the proof.
        tokio::task::spawn_blocking(move || {
            prover::generate_proof(
                &request.policy,
                &request.attributes,
                request.token_id,
                request.ct_cid,
            )
        }),
    )
    .await
    .map_err(|_| warp::reject::custom(ProofGenerationFailed))?
    .unwrap()
    .unwrap();

    println!("Proof generated");

    // let result = prover::generate_proof(
    //     &request.policy,
    //     &request.attributes,
    //     request.token_id,
    //     request.ct_cid,
    // )
    // .map_err(|_| warp::reject::custom(ProofGenerationFailed))?;

    println!("Sending proof back...");
    let (seal, ct_cid) = result;
    let response = ProofResponse { seal, ct_cid };

    Ok(warp::reply::json(&response))
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenv().ok(); // load .env file

    let bonsai_api_url = env::var("BONSAI_API_URL")?;
    let bonsai_api_key = env::var("BONSAI_API_KEY")?;

    // Use the API URL and key as needed
    println!("Bonsai API URL: {}", bonsai_api_url);
    println!("Bonsai API Key: {}", bonsai_api_key);

    env_logger::init();

    // TODO: obtain all these from DP side (using an api)
    //       zkserver gets
    //          1. dp_attributes
    //          2. tokenId
    //       and it is able to read policy and ct_cid from smart contract.
    //       ct_cid has to send into guest code to make the commitment
    //       and ct_cid will be send to verifier to make sure
    //       "The ct_cid that send into guest code == the one send to blockchain"

    tokio::task::block_in_place(|| {});

    let generate_proof_route = warp::post()
        .and(warp::path("api"))
        .and(warp::path("generate_proof"))
        .and(warp::body::json())
        .and_then(handle_generate_proof);

    let cors = warp::cors()
        .allow_origin("http://localhost:3000")
        .allow_methods(vec!["GET", "POST", "OPTIONS"])
        .allow_headers(vec!["Content-Type"])
        .allow_credentials(true);

    let routes = generate_proof_route.with(cors);

    // State the server here
    let port = 8080;
    println!("Server started at http://localhost:{}", port);
    warp::serve(routes).run(([127, 0, 0, 1], port)).await;
    Ok(())
}
