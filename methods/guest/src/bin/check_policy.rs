// use json::parse;
// use json_core::Outputs;
use rabe::utils::tools::traverse_policy;
use risc0_zkvm::{
    guest::env,
    sha::{Impl, Sha256},
};

use rabe::utils::policy::pest::{
    parse, serialize_policy, PolicyLanguage::JsonPolicy, PolicyType, PolicyValue,
};
use serde_json;

fn extract_attribute_names(attrs: &serde_json::Value) -> Vec<String> {
    attrs
        .get("attributes")
        .and_then(|a| a.as_array())
        .map(|attributes| {
            attributes
                .iter()
                .filter_map(|attr| {
                    attr.get("name")
                        .and_then(serde_json::Value::as_str)
                        .map(String::from)
                })
                .collect()
        })
        .unwrap_or_default()
}

fn main() {
    let policy_str: String = env::read();
    let dp_attr_str: String = env::read();

    let policy_parsed = parse(&policy_str, JsonPolicy).unwrap();

    // printing out the policy
    // println!(
    //     "policy: {:?}",
    //     serialize_policy(&policy_parsed, JsonPolicy, None)
    // );

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

    let result = if satisfied { "1" } else { "0" };
    env::commit(&result);
}
