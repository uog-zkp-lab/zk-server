use alloy_primitives::U256;
use alloy_sol_types::{sol, SolInterface, SolValue};
use anyhow::{Context, Result};
use clap::Parser;
use ethers::prelude::*;
use methods::CHECK_POLICY_ELF;
use risc0_ethereum_contracts::groth16;
use risc0_zkvm::{default_prover, ExecutorEnv, ProverOpts, VerifierContext};
use std::fmt::Debug;

// `IEvenNumber` interface automatically generated via the alloy `sol!` macro.
sol! {
    interface IAccessToken {
        function mintAccessTokenForDP(
            bytes calldata seal,
            uint256 tokenId,
            uint256 ctCid
        );
    }
}

/// Wrapper of a `SignerMiddleware` client to send transactions to the given
/// contract's `Address`.
pub struct TxSender {
    chain_id: u64,
    client: SignerMiddleware<Provider<Http>, Wallet<k256::ecdsa::SigningKey>>,
    contract: Address,
}

impl TxSender {
    /// Creates a new `TxSender`.
    pub fn new(chain_id: u64, rpc_url: &str, private_key: &str, contract: &str) -> Result<Self> {
        let provider = Provider::<Http>::try_from(rpc_url)?;
        let wallet: LocalWallet = private_key.parse::<LocalWallet>()?.with_chain_id(chain_id);
        let client = SignerMiddleware::new(provider.clone(), wallet.clone());
        let contract = contract.parse::<Address>()?;

        Ok(TxSender {
            chain_id,
            client,
            contract,
        })
    }

    /// Send a transaction with the given calldata.
    pub async fn send(&self, calldata: Vec<u8>) -> Result<Option<TransactionReceipt>> {
        let tx = TransactionRequest::new()
            .chain_id(self.chain_id)
            .to(self.contract)
            .from(self.client.address())
            .data(calldata);

        log::info!("Transaction request: {:?}", &tx);

        let tx = self.client.send_transaction(tx, None).await?.await?;

        log::info!("Transaction receipt: {:?}", &tx);

        Ok(tx)
    }
}

/// Arguments of the publisher CLI.
#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct Args {
    /// Ethereum chain ID
    #[clap(long)]
    chain_id: u64,

    /// Ethereum Node endpoint.
    #[clap(long, env)]
    eth_wallet_private_key: String,

    /// Ethereum Node endpoint.
    #[clap(long)]
    rpc_url: String,

    /// Application's contract address on Ethereum
    #[clap(long)]
    contract: String,
}

fn main() -> Result<()> {
    env_logger::init();
    // Parsing CLI Arguments
    let args = Args::parse();

    // Create a new transaction sender using the parsed arguments.
    let tx_sender = TxSender::new(
        args.chain_id,
        &args.rpc_url,
        &args.eth_wallet_private_key,
        &args.contract,
    )?;

    // TODO: obtain all these from DP side (using an api)
    //       zkserver gets
    //          1. dp_attributes
    //          2. tokenId
    //       and it is able to read policy and ct_cid from smart contract.
    //       ct_cid has to send into guest code to make the commitment
    //       and ct_cid will be send to verifier to make sure
    //       "The ct_cid that send into guest code == the one send to blockchain"

    let policy_str = include_str!("../../../template_data/policy.json");
    let dp_attr_str = include_str!("../../../template_data/attr/attr_pass.json");
    // let dp_attr_str = include_str!("../../../template_data/attr/attr_fail.json");
    let token_id = <U256>::from(12345_u16);
    let _ct_cid = (1234).abi_encode();

    // send policy and attributes strings into the execute env
    let env = ExecutorEnv::builder()
        .write(&policy_str)
        .unwrap()
        .write(&dp_attr_str)
        .unwrap()
        .write_slice(&_ct_cid)
        .build()
        .unwrap();

    // Obtain the default prover
    let prover = default_prover();

    // Produce a receipt by proving the specified ELF binary.
    let receipt = prover
        .prove_with_ctx(
            env,
            &VerifierContext::default(),
            CHECK_POLICY_ELF,
            &ProverOpts::groth16(),
        )?
        .receipt;

    let seal = groth16::encode(receipt.inner.groth16()?.seal.clone())?;

    // extracting the journal from the receipt
    let journal = receipt.journal.bytes.clone();

    // after receive the proof, decodes the journal and extract
    // the verified `ct_cid`. This make sure the `ct_cid`
    // sending to the blockchain consist with the one send to
    // prover
    let ct_cid = U256::abi_decode(&journal, true).context("decoding journal data")?;

    let calldata = IAccessToken::IAccessTokenCalls::mintAccessTokenForDP(
        IAccessToken::mintAccessTokenForDPCall {
            seal: seal.into(),
            tokenId: token_id,
            ctCid: ct_cid,
        },
    )
    .abi_encode();

    let runtime = tokio::runtime::Runtime::new()?;
    runtime.block_on(tx_sender.send(calldata))?;

    Ok(())
}
