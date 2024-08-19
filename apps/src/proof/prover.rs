use alloy_primitives::U256;
use alloy_sol_types::{SolInterface, SolValue};
use anyhow::{Context, Result};
use methods::CHECK_POLICY_ELF;
use risc0_ethereum_contracts::groth16;
use risc0_zkvm::{default_prover, ExecutorEnv, ProverOpts, VerifierContext};

pub fn generate_proof(
    policy_str: &str,
    dp_attr_str: &str,
    token_id: U256,
    ct_cid: u32,
) -> Result<(Vec<u8>, U256)> {
    let ct_cid_bytes = ct_cid.abi_encode();

    // Send policy and attributes strings into the execute env
    let env = ExecutorEnv::builder()
        .write(&policy_str)?
        .write(&dp_attr_str)?
        .write_slice(&ct_cid_bytes)
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

    // Extract the journal from the receipt
    let journal = receipt.journal.bytes.clone();

    // Decode the journal and extract the verified `ct_cid`
    let verified_ct_cid = U256::abi_decode(&journal, true).context("decoding journal data")?;

    Ok((seal, verified_ct_cid))
}
