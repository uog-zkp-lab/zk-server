use crate::ipfs_reader::read_policy_from_ipfs;
use crate::prover;
use crate::types::{PolicyRetrievalFailed, ProofGenerationFailed, ProofRequest, ProofResponse};

use alloy_primitives::U256;
use tokio::time::{timeout, Duration};
use warp::{Rejection, Reply};

pub async fn handle_generate_proof(request: ProofRequest) -> Result<impl Reply, Rejection> {
    println!("\nGot Request: \n\n {:?}", &request);

    let _token_id: U256 = request.token_id;
    let cid = request.cid;
    let dp_attr_str = request.attributes;

    println!("Retrieving policy from ipfs...");

    // fetching policy from ipfs
    let policy = read_policy_from_ipfs(cid.clone())
        .await
        .map_err(|_| PolicyRetrievalFailed)?;

    println!("Policy retrieved: {:?}", policy);

    println!("Generating proof...");

    let result = timeout(
        Duration::from_secs(180), // timeout after 3 min
        // the reason using spawn_blocking is because generate_proof
        // is using another async api to get the proof.
        tokio::task::spawn_blocking(move || {
            prover::generate_proof(&policy, &dp_attr_str, _token_id)
        }),
    )
    .await
    .map_err(|_| warp::reject::custom(ProofGenerationFailed))?
    .unwrap()
    .unwrap();

    println!("Proof generated");
    println!("Sending proof back...");

    let (seal, token_id) = result;
    let response = ProofResponse { seal, token_id };

    Ok(warp::reply::json(&response))
}
