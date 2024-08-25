use alloy_primitives::keccak256;
use alloy_sol_types::SolValue;
use rabe::utils::policy::pest::PolicyLanguage::{HumanPolicy, JsonPolicy, self};

pub fn extract_attributes(attrs_str: &str) -> Vec<String> {
    let parsed: serde_json::Value = match serde_json::from_str(attrs_str) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("JSON parsing error: {}", e);
            return Vec::new();
        }
    };

    parsed["attributes"]
        .as_array()
        .map(|attrs| {
            attrs
                .iter()
                .filter_map(|obj| {
                    if let serde_json::Value::Object(map) = obj {
                        map.iter().next().map(|(key, value)| {
                            format!("{}:{}", key, value.as_str().unwrap_or_default())
                        })
                    } else {
                        None
                    }
                })
                .collect()
        })
        .unwrap_or_else(Vec::new)
}

pub fn determine_policy_type(policy: &str) -> PolicyLanguage {
    if policy.trim_start().starts_with("{") {
        return JsonPolicy;
    }
    return HumanPolicy;
}

pub fn calculate_attr_hash(dp_attr_str: &str) -> String {
    let encoded = dp_attr_str.abi_encode();
    keccak256(encoded).to_string()
}