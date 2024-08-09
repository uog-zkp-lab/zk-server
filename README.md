# zkServer

## Setting up

Before the zkServer is used, it has to be deployed. 

The ELF binary that represent the instructions inside `guest code` would be generated. And a unique identifier called `ImageId` would also be generated in the cargo building phase. `ImageId` represents guest code that zkServer uses, which means if anyone wants to generate a fake proof using another zkServer with the incorrect code, it will not pass the verification due to the incorrect `ImageId`.

---

## In the flow of ABE system

A zero knowledge virtual machine as the server to obtain:

1. attributes
2. tokenId (designed to be `keccak256(abi.encodePacked(address(do' address)))`)

This zkServer would then retrieve the `policy` from smart contract, check if the attributes satisfy the policy by traversing it.

Meanwhile, the `ct_cid` is going to be committed in the guest code (which is the code that would be proved).

If the check passes, zkServer would generate a proof, which is a receipt in RISC0 ZKVM. The receipt is composed of 2 parts: `seal` and `journal`. These two parts would both send into the smart contract. `seal` 
Otherwise, the code would panic, and the proof would not be generated. 