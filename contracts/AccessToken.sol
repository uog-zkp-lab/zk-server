// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol"; // auto-generated

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol'; // to prevent reentrancy attack
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/// @title Access token contract for ZK CP-ABE system
contract AccessToken is ERC1155, ERC1155Burnable, ReentrancyGuard {
    /// RISC Zero verifier contract address.
    IRiscZeroVerifier public immutable verifier;
    
    /// @notice Image ID of the only zkVM binary to accept verification from.
    ///         The image ID is similar to the address of a smart contract.
    ///         It uniquely represents the logic of that guest program,
    ///         ensuring that only proofs generated from a pre-defined guest program
    bytes32 public constant imageId = ImageID.CHECK_POLICY_ID;

    mapping (uint256 tokenId => string cid) public tokenIpfsHash;
    mapping (uint256 tokenId => address owner) public tokenOwner;
    mapping (address dpAddr => bytes32 attributesHash) internal dpAttrHash;

    event TokenCreated(uint256 tokenId, address owner);
    event AccessTokenMinted(address indexed dpAddress, uint256 tokenId, bytes seal);
    event DPRegistered(address indexed dpAddress, bytes32 attributesHash);

    /// modifiers
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
        string memory cid
    ) public onlyTokenOwner(tokenId) {
        tokenIpfsHash[tokenId] = cid;
    }

    /// @dev create token for data owner with cid
    function createToken(
        string memory cid
    ) public {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(address(msg.sender))));
        require(tokenOwner[tokenId] == address(0), "This Token Id Has Been Created.");
        tokenOwner[tokenId] = msg.sender;
        setIpfsData(tokenId, cid);
        emit TokenCreated(tokenId, msg.sender);
    }

    /// @dev data processor register with their attributes
    function registerDP(
        bytes32 attributesHash
    ) public {
        dpAttrHash[msg.sender] = attributesHash;
        emit DPRegistered(msg.sender, attributesHash);
    }

    /// @dev mint the access token for data processor
    function mintAccessTokenForDP(
        bytes calldata seal,
        bytes32 attributesHash,
        uint256 tokenId,
        string memory cid
    ) public nonReentrant {
        // should pass the verification first
        require(tokenOwner[tokenId] != address(0), "TokenId has not been created");
        require(checkCidEquality(tokenId, cid), "TokenId and cid does not match!");
        require(dpAttrHash[msg.sender] == attributesHash, "Attributes does not match!");

        bytes memory journal = abi.encode(cid);
        verifier.verify(seal, imageId, sha256(journal));
        _mint(msg.sender, tokenId, 1, "");
        emit AccessTokenMinted(msg.sender, tokenId, journal);
    }

    /// @dev get balance for data processor
    function getDPBalance(
        uint256 tokenId,
        bytes32 messageHash,
        bytes memory signature
    ) public view returns (uint256) {
        address signer = ECDSA.recover(messageHash, signature);
        require(signer == msg.sender, "Invalid signature"); // only the holder can check the balance
        return balanceOf(msg.sender, tokenId);
    }

    function checkCidEquality(
        uint256 tokenId, 
        string memory cid
    ) private view returns (bool) {
        string memory storedCid = tokenIpfsHash[tokenId];
        // comparing the length to optimize the gas cost
        if (bytes(storedCid).length != bytes(cid).length) {
            return false;
        }
        return keccak256(abi.encodePacked(storedCid)) == keccak256(abi.encodePacked(cid));
    }
}
