# zkServer

## Setting up

Before the zkServer is used, it should be executed locally by the data processors themselves; otherwise, data processors' attributes might leak to other parties.

To build locally, run `cargo build -r` first:

Afterwards, the ELF binary that represent the instructions inside `guest code` would be generated. And a unique identifier called `ImageId` would also be generated in the cargo building phase. `ImageId` represents guest code that zkServer uses, which means if anyone wants to generate a fake proof using another zkServer with the incorrect code, it will not pass the verification due to the incorrect `ImageId`.

## Structure

![zkserver](https://i.imgur.com/cN2pF0j.png)

The current structure is based on `risc0-foundry-template`.

---

## In the flow of ABE system

A zero knowledge virtual machine as the server to obtain:

1. Attributes
2. Token id (designed to be `keccak256(abi.encodePacked(address(data_owner_address, token_id_count)))`)
3. CID: the content identifier of IPFS, which is a hash value.

This zkServer would then retrieve the `policy` from IPFS, check if the attributes satisfy the policy by traversing it. If the attributes do not satisfy the policy, zkServer will panic with no proof generated.

Meanwhile, the `token_id` is going to be committed in the guest code (which is the code that would be proved).

If the check passes, zkServer would generate a proof, which is a receipt in RISC0 ZKVM. The receipt is composed of 2 parts: `seal` and `journal`. These two parts would both send into the smart contract. `seal`

## Steps to execute this

1. Run `cp .env.example .env` in root directory.
2. Fill in your `BONSAI_API_URL`, `BONSAI_API_KEY` and `IPFS_GATEWAY` in `.env`.
3. Run `cargo run --bin server`.

A normal usage would be like:

```shell
    Finished `release` profile [optimized + debuginfo] target(s) in 1m 14s
     Running `target/release/server`
Server started at http://localhost:5566

Got Request: 

 ProofRequest { attributes: "{\"attributes\":[{\"Role\":\"Doctor\"},{\"Age\":\"40\"},{\"Department\":\"Oncology\"},{\"medical_license\":\"ML123456\"},{\"speciality_cardiology\":\"certified\"},{\"hospital_affiliation\":\"Central Hospital\"},{\"patient_consent\":\"granted\"},{\"scheduled_appointment\":\"2023-08-15T10:00:00Z\"}]}", token_id: 0xecf7f8bb72870307f32a9c5868994b315b928aa539d8b54a537332a6cfc0efed_U256, cid: "bafkreidomnodxaa37xkeiehlxrmtfe2bmuw2fcvu3jacwmlyfb3dr3asou" }
Retrieving policy from ipfs...
policy_str: "(\"Role:Doctor\" and \"Department:Oncology\") or (\"Role:Doctor\" and \"Department:XXX\")"
Policy retrieved: "(\"Role:Doctor\" and \"Department:Oncology\") or (\"Role:Doctor\" and \"Department:XXX\")"
Generating proof...
Recovered token ID: 107183960177316301302241880581336344215219240409990108434358097158748491542509
Proof generated
Sending proof back...
```

---

## Tests

There are two types of tests in the project.

### Performance tests

1. Performance test - proof generating time
    `cargo test tests::test_proof_generation_performance --release -- --nocapture` to run performance test to measure the time of generating proof in different size of attributes.

    Result would be like:

    ```shell
    running 1 test
    test tests::performance_tests::tests::test_proof_generation_performance has been running for over 60 seconds
    Average time taken for 10 attributes: 33.03 seconds
    Average time taken for 50 attributes: 32.77 seconds
    Average time taken for 100 attributes: 36.44 seconds
    Average time taken for 500 attributes: 38.42 seconds
    Average time taken for 1000 attributes: 43.74 seconds
    Average time taken for 5000 attributes: 77.42 seconds
    Average time taken for 10000 attributes: 89.21 seconds
    Average time taken for 20000 attributes: 86.16 seconds
    Average time taken for 25000 attributes: 79.40 seconds
    Average time taken for 30000 attributes: 77.57 seconds
    Average time taken for 35000 attributes: 78.69 seconds
    test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 3629.85s
        Running unittests src/bin/server.rs (target/release/deps/server-a06c265b53e1a975)
    ```

    It is expected to run in a long time, so don't be panic if it runs for too long.
