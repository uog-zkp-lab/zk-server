use anyhow::Result;
use dotenv::dotenv;
use reqwest;
use std::env;

pub async fn read_policy_from_ipfs(cid: String) -> Result<String> {
    dotenv().ok();
    let ipfs_url = format!("{}{}", env::var("IPFS_GATEWAY").unwrap(), cid);
    let res = reqwest::get(ipfs_url).await.unwrap().text().await.unwrap();
    let policy: serde_json::Value = serde_json::from_str(&res).unwrap();
    let policy_str = policy["policy"].as_str().unwrap();
    let trimmed = trim_policy(policy_str.to_string()).unwrap();
    Ok(trimmed)
}

// trims the '"'s & '\'s in the ipfs return data
// this is due to string formatting
fn trim_policy(policy: String) -> Result<String> {
    // Unescape the string multiple times
    let mut clean_policy_str = policy;
    while clean_policy_str.starts_with('"') && clean_policy_str.ends_with('"') {
        clean_policy_str = serde_json::from_str::<String>(&clean_policy_str)
            .unwrap_or_else(|_| clean_policy_str.clone());
    }
    Ok(clean_policy_str)
}
