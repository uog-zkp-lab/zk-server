// // SPDX-License-Identifier: Apache-2.0

// pragma solidity ^0.8.20;

// import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
// import {ImageID} from "./ImageID.sol"; // auto-generated

// import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
// import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';

// /// @title Access token contract for ZK CP-ABE system
// contract AccessToken is ERC1155, ERC1155Burnable {
//     /// RISC Zero verifier contract address.
//     IRiscZeroVerifier public immutable verifier;
    
//     /// @notice Image ID of the only zkVM binary to accept verification from.
//     ///         The image ID is similar to the address of a smart contract.
//     ///         It uniquely represents the logic of that guest program,
//     ///         ensuring that only proofs generated from a pre-defined guest program
//     bytes32 public constant imageId = ImageID.CHECK_POLICY_ID;

//     mapping (uint256 tokenId => string cid) public tokenCid;
//     mapping (uint256 tokenId => bool created) public tokenCreated;
//     mapping (uint256 tokenId => address owner) public tokenOwner;

//     // modifiers
//     modifier onlyTokenOwner(uint256 tokenId) {
//         require(tokenOwner[tokenId] == msg.sender, "Only Token Owner is able to access to the token");
//         _;
//     }

//     modifier tokenNotCreated(uint256 tokenId) {
//         require(!tokenCreated(tokenCreated[tokenId]));
//         _;
//     }

//     /// @notice Initialize the contract, binding it to a specified RISC Zero verifier.
//     constructor(IRiscZeroVerifier _verifier) {
//         verifier = _verifier;
//     }

//     /// @dev A function for token owners to set the cid of each token 
//     function setCID(uint256 tokenId, string memory cid) public onlyTokenOwner{
//         _setCID(tokenId, cid);
//     }

//     /// @dev create token for data owner
//     function createToken() public tokenNotCreated {
//         uint256 tokenId = sha256(abi.encodePacked(address(msg.sender)));
//         ;
//         tokenCreated[tokenId] = true;
//         tokenOwner[tokenId] = msg.sender;
//     }

//     /// @dev create token for data owner with cid
//     function createToken(string memory cid) public tokenNotCreated {
//         uint256 tokenId = sha256(abi.encodePacked(msg.sender));
//         tokenCreated[tokenId] = true;
//         tokenOwner[tokenId] = msg.sender;
//         setCID(tokenId, cid);
//     }

//     /// @dev mint the access token for data processor
//     function mintAccessTokenForDP(
//         bytes calldata seal,
//         bytes32 tokenId
//     ) public {
//         // should pass the verification first
//         // bytes memory journal = abi.encode();
//         // verifier.verify(seal, imageId, );
//         _mint(msg.sender, tokenId, 1);
//     }

//     /// @dev get balance for data processor
//     // function getBalance(
//     //     address dpAddress,
//     //     string tokenId
//     // ) view returns (bool) {
//     //     return balance(dpAddress, tokenId) > 0;
//     // }

//     /// @dev a private function for setting cid for tokenId
//     function _setCID(uint256 tokenId, string memory cid) private {
//         tokenCid[tokenId] = cid;
//     }
// } 
