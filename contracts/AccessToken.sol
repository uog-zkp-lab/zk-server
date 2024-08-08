// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol"; // auto-generated

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';

/// @title Access token contract for ZK CP-ABE system
contract AccessToken is ERC1155, ERC1155Burnable {
    /// RISC Zero verifier contract address.
    IRiscZeroVerifier public immutable verifier;
    
    /// @notice Image ID of the only zkVM binary to accept verification from.
    ///         The image ID is similar to the address of a smart contract.
    ///         It uniquely represents the logic of that guest program,
    ///         ensuring that only proofs generated from a pre-defined guest program
    bytes32 public constant imageId = ImageID.CHECK_POLICY_ID;

    mapping (uint256 tokenId => IpfsData ipfsData) public tokenIpfsData;
    mapping (uint256 tokenId => bool created) public tokenCreated;
    mapping (uint256 tokenId => address owner) public tokenOwner;

    struct IpfsData {
        string policyString;
        // the three below are uploaded to ipfs
        string ctCid; 
        string aPassCid;
        string aFailCid;
    }

    // modifiers
    modifier onlyTokenOwner(uint256 tokenId) {
        require(tokenOwner[tokenId] == msg.sender, "Only Token Owner is able to access to the token");
        _;
    }

    /// @notice Initialize the contract, binding it to a specified RISC Zero verifier.
    constructor(IRiscZeroVerifier _verifier) ERC1155("") {
        verifier = _verifier;
    }

    /// @dev A function for token owners to set the cid of each token 
    function setIpfsData(
        uint256 tokenId, 
        string memory policyString,
        string memory ctCid,
        string memory aPassCid,
        string memory aFailCid
    ) public onlyTokenOwner(tokenId) {
        IpfsData memory ipfsData;
        ipfsData.policyString = policyString;
        ipfsData.ctCid = ctCid;
        ipfsData.aPassCid = aPassCid;
        ipfsData.aFailCid = aFailCid;
        tokenIpfsData[tokenId] = ipfsData;
    }

    /// @dev create token for data owner with cid
    function createToken(
        string memory policyString,
        string memory ctCid,
        string memory aPassCid,
        string memory aFailCid
    ) public {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(address(msg.sender))));
        require(!checkIfTokenIsCreated(tokenId), "This Token Id Has Been Created.");
        tokenCreated[tokenId] = true;
        tokenOwner[tokenId] = msg.sender;
        setIpfsData(tokenId, policyString, ctCid, aPassCid, aFailCid);
    }

    /// @dev mint the access token for data processor
    function mintAccessTokenForDP(
        bytes calldata seal,
        uint256 tokenId,
        string calldata cid
    ) public {
        // should pass the verification first
        require(checkCidEquality(tokenId, cid), "TokenId and cid does not match!");
        bytes memory journal = abi.encode("");
        verifier.verify(seal, imageId, sha256(journal));
        _mint(msg.sender, tokenId, 1, "");
    }

    /// @dev get balance for data processor
    function getBalance(
        address dpAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        return balanceOf(dpAddress, tokenId);
    }

    /// @notice helper functions
    /// @dev a private function to check if the token is created before
    function checkIfTokenIsCreated(uint256 tokenId) private view returns (bool) {
        return tokenCreated[tokenId];
    }

    function checkCidEquality(uint256 tokenId, string memory ctCid) private view returns (bool) {
        return keccak256(abi.encodePacked(tokenIpfsData[tokenId].ctCid)) == keccak256(abi.encodePacked(ctCid));
    }
} 
