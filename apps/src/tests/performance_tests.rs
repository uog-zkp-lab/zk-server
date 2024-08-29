pub mod tests {
    use crate::prover;
    use alloy_primitives::U256;
    use dotenv::dotenv;
    use serde_json::json;
    use std::time::Duration;
    use std::time::Instant;
    use tokio::time::timeout;

    fn generate_random_attributes(num_attributes: usize) -> String {
        let attributes: Vec<serde_json::Value> = (0..num_attributes)
            .map(|i| {
                let key = format!("Attr{}", i);
                let value = format!("Value{}", i);
                json!({ key: value })
            })
            .collect();
        json!({ "attributes": attributes }).to_string()
    }

    #[tokio::test]
    async fn test_proof_generation_performance() {
        // if you want to test locally, comment this out to enable your local ZKVM
        // However, be sure your machine is using x86_64 architecture, since the
        // risc0-zkvm is not yet supported on non-x86_64 architectures. (i.e. M-series Macs)
        dotenv().ok();

        let test_cases_1 = vec![
            10, 50, 100, 500, 1000, 5000, 10000, 20000, 25000, 30000, 35000,
        ];
        let iterations = 5;

        for num_attributes in test_cases_1 {
            let mut total_duration = Duration::new(0, 0);
            let mut success_count = 0;

            for _ in 0..iterations {
                let attributes = generate_random_attributes(num_attributes);
                let policy = r#""Attr1:Value1""#;
                let token_id = U256::from(1234); // Example token ID

                let start_time = Instant::now();

                let result = timeout(
                    Duration::from_secs(600), // 10-minute timeout
                    tokio::task::spawn_blocking(move || {
                        prover::generate_proof(&policy, &attributes, token_id)
                    }),
                )
                .await;

                match result {
                    Ok(Ok(Ok(_))) => {
                        let duration = start_time.elapsed();
                        total_duration += duration;
                        success_count += 1;
                    }
                    Ok(Ok(Err(e))) => {
                        println!(
                            "Error generating proof for {} attributes: {:?}",
                            num_attributes, e
                        );
                    }
                    Ok(Err(e)) => {
                        println!("Task panicked for {} attributes: {:?}", num_attributes, e);
                    }
                    Err(_) => {
                        println!("Timeout reached for {} attributes", num_attributes);
                    }
                }
            }

            if success_count > 0 {
                let average_duration = total_duration.as_secs_f64() / success_count as f64;
                println!(
                    "Average time taken for {} attributes: {:.2} seconds",
                    num_attributes, average_duration
                );
            } else {
                println!(
                    "No successful proofs generated for {} attributes",
                    num_attributes
                );
            }
        }
    }
}
