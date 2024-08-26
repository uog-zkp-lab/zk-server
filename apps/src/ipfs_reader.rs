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
    println!("policy_str: {:?}", policy_str);
    Ok(policy_str.to_string())
}
