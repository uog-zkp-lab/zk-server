// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol"; // auto-generated

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @title Access token contract for ZK CP-ABE system and associating data with an IPFS CID
contract AccessToken is ERC1155, ERC1155Burnable, Ownable {
    /// RISC Zero verifier contract address.
    IRiscZeroVerifier public immutable verifier;

    /// @notice Image ID of the only zkVM binary to accept verification from.
    /// The image ID is similar to the address of a smart contract.
    /// It uniquely represents the logic of that guest program,
    /// ensuring that only proofs generated from a pre-defined guest program
    bytes32 public constant imageId = ImageID.CHECK_POLICY_ID;

    mapping(uint256 => string) public tokenCIDs;
    mapping(uint256 => bool) public tokenCreated;
    mapping(uint256 => address) public tokenOwner;

    event TokenCreated(uint256 indexed tokenId, address indexed owner, string cid);

    /// modifiers
    modifier onlyTokenOwner(uint256 tokenId) {
        require(tokenOwner[tokenId] == msg.sender, "Only Token Owner is able to access the token");
        _;
    }

    /// @notice Initialize the contract, binding it to a specified RISC Zero verifier and setting the owner.
    constructor(IRiscZeroVerifier _verifier) ERC1155("") Ownable(msg.sender) {
        verifier = _verifier;
    }

    /// @dev Create a token for the data owner with an IPFS CID
    function createToken(string memory cid) public {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(msg.sender, cid)));
        require(!tokenCreated[tokenId], "This Token ID has already been created.");

        tokenCreated[tokenId] = true;
        tokenOwner[tokenId] = msg.sender;
        tokenCIDs[tokenId] = cid;

        _mint(msg.sender, tokenId, 1, "");
        
        emit TokenCreated(tokenId, msg.sender, cid);
    }

    /// @dev Mint the access token for a data processor after verification
    function mintAccessTokenForDP(
        bytes calldata seal,
        uint256 tokenId,
        uint256 cid
    ) public {
        // Should pass the verification first
        bytes memory journal = abi.encode(cid);
        verifier.verify(seal, imageId, sha256(journal));
        _mint(msg.sender, tokenId, 1, "");
    }

    /// @dev Get the balance of a specific token ID
    function getBalance(
        address dpAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        return balanceOf(dpAddress, tokenId);
    }

    /// @notice Helper function
    /// @dev Check if the token is created
    function checkIfTokenIsCreated(uint256 tokenId) private view returns (bool) {
        return tokenCreated[tokenId];
    }

    /// @dev Check if the CID matches
    function checkCidEquality(uint256 tokenId, string memory cid) private view returns (bool) {
        return keccak256(abi.encodePacked(tokenCIDs[tokenId])) == keccak256(abi.encodePacked(cid));
    }
}
