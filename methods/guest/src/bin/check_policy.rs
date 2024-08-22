use alloy_primitives::U256;
use alloy_sol_types::SolValue;
use rabe::utils::policy::pest::{parse, PolicyLanguage::JsonPolicy, PolicyType};
use rabe::utils::tools::traverse_policy;
use risc0_zkvm::guest::env;
use serde_json;
use std::io::Read;
use guests::utils::extract_attribute_names;

fn main() {
    let policy_str: String = env::read();
    let dp_attr_str: String = env::read();
    let mut ct_cid_bytes = Vec::<u8>::new();
    env::stdin().read_to_end(&mut ct_cid_bytes).unwrap();
    
    let ct_cid = <U256>::abi_decode(&ct_cid_bytes, true).unwrap();
    
    // can use serialized_parse to print the policy
    let policy_parsed = parse(&policy_str, JsonPolicy).unwrap();

    let dp_attrs: serde_json::Value =
        serde_json::from_str(&dp_attr_str).expect("JSON was not well-formatted");

    // converting the attributes into Vec<String>
    let attr_vector = extract_attribute_names(&dp_attrs);
    println!("attributes vector: {:?}\n\n", attr_vector);

    let satisfied = traverse_policy(&attr_vector, &policy_parsed, PolicyType::Leaf);
    println!("Attributes satisfy the policy: {}", satisfied);

    if !satisfied {
        panic!("The Attributes Does Not Satisfy the Policy!!!");
    }

    env::commit_slice(ct_cid.abi_encode().as_slice());
}
