use std::io::Read;
use alloy_primitives::U256;
use alloy_sol_types::SolValue;
use rabe::utils::policy::pest::{parse, serialize_policy, PolicyLanguage::HumanPolicy, PolicyType};
use rabe::utils::tools::traverse_policy;
use risc0_zkvm::guest::env;
use guests::utils;

fn main() {
    let policy_str: String = env::read();
    let dp_attr_str: String = env::read();

    // read cid_bytes and recover it from abi.encoded bytes
    let mut input_bytes = Vec::<u8>::new();
    env::stdin().read_to_end(&mut input_bytes).unwrap();
    let token_id = <U256>::abi_decode(&input_bytes, true).unwrap();

    println!("policy_str: {:?}", policy_str);
    println!("dp_attr_str: {:?}", dp_attr_str);
    println!("recovered_token_id: {:?}", token_id);

    // can use serialized_parse to print the policy
    let policy_parsed = parse(&policy_str, HumanPolicy).unwrap();
    println!("policy_parsed: {:?}", serialize_policy(&policy_parsed, HumanPolicy, None));

    let attr_vector = utils::extract_attributes(&dp_attr_str);
    println!("attr_vector: {:?}", attr_vector);

    let satisfied = traverse_policy(&attr_vector, &policy_parsed, PolicyType::Leaf);
    println!("Attributes satisfy the policy: {}", satisfied);

    if !satisfied {
        panic!("The Attributes Does Not Satisfy the Policy!!!");
    }

    env::commit_slice(token_id.abi_encode().as_slice());
}
