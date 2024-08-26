use alloy_primitives::U256;
use alloy_sol_types::SolValue;
use anyhow::{Context, Result};
use methods::{CHECK_POLICY_ELF, CHECK_POLICY_ID};
use risc0_ethereum_contracts::groth16;
use risc0_zkvm::{default_prover, ExecutorEnv, ProverOpts, VerifierContext};

pub fn generate_proof(
    policy_str: &str,
    dp_attr_str: &str,
    token_id: U256,
) -> Result<(Vec<u8>, U256)> {
    let token_id_bytes = token_id.abi_encode();

    // Send policy and attributes strings into the execute env
    let env = ExecutorEnv::builder()
        .write(&policy_str)?
        .write(&dp_attr_str)?
        .write_slice(&token_id_bytes)
        .build()?;

    // Obtain the default prover
    let prover = default_prover();

    // Produce a receipt by proving the specified ELF binary
    let receipt = prover
        .prove_with_ctx(
            env,
            &VerifierContext::default(),
            CHECK_POLICY_ELF,
            &ProverOpts::groth16(),
        )?
        .receipt;

    let seal = groth16::encode(receipt.inner.groth16()?.seal.clone())?;

    receipt
        .verify(CHECK_POLICY_ID)
        .expect("Failed to verify receipt");

    // Extract the journal from the receipt
    let journal = receipt.journal.bytes.clone();
    let recovered_token_id = U256::abi_decode(&journal, true).context("decoding journal data")?;
    println!("Recovered token ID: {}", recovered_token_id);
    assert!(
        recovered_token_id == token_id,
        "Recovered token ID does not match"
    );

    Ok((seal, recovered_token_id))
}
