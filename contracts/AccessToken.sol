// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol"; // auto-generated

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/// @title Access token contract for ZK CP-ABE system
contract AccessToken is ERC1155 {
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
    mapping (address doAddr => uint256[] tokenIds) private _ownerTokens;

    event TokenCreated(uint256 tokenId, address owner);
    event AccessTokenMinted(address indexed dpAddress, uint256 tokenId);
    event DPRegistered(address indexed dpAddress, bytes32 attributesHash);

    uint256 private _tokenIdCounter;

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
    function setIpfsHash(
        uint256 tokenId,
        string memory cid
    ) public onlyTokenOwner(tokenId) {
        tokenIpfsHash[tokenId] = cid;
    }

    /// @dev create token for data owner with cid
    function createToken(
        string memory cid
    ) public {
        _tokenIdCounter++;
        uint256 tokenId = uint256(keccak256(abi.encodePacked(msg.sender, _tokenIdCounter)));
        require(tokenOwner[tokenId] == address(0), "This Token Id Has Been Created.");
        
        tokenOwner[tokenId] = msg.sender;
        _ownerTokens[msg.sender].push(tokenId);

        setIpfsHash(tokenId, cid);
        emit TokenCreated(tokenId, msg.sender);
    }

    /// @dev a function to get cid of a token
    function getCid(uint256 tokenId) public view returns (string memory cid) {
        return tokenIpfsHash[tokenId];
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
        uint256 tokenId,
        bytes32 attributesHash
    ) public {
        require(tokenOwner[tokenId] != address(0), "TokenId has not been created");
        require(dpAttrHash[msg.sender] != bytes32(0), "Data processor has not been registered");
        require(dpAttrHash[msg.sender] == attributesHash, "Invalid attributes hash");

        // tokenId is committed in the proof
        bytes memory journal = abi.encode(tokenId);
        verifier.verify(seal, imageId, sha256(journal));
        _mint(msg.sender, tokenId, 1, "");
        emit AccessTokenMinted(msg.sender, tokenId);
    }

    /// @dev get balance for data processor
    function getDPBalance(
        address dpAddr,
        uint256 tokenId,
        bytes memory signature
    ) public view returns (bool) {
        address signer = ECDSA.recover(keccak256(abi.encodePacked(tokenId)), signature);
        require(signer == msg.sender, "Invalid signature"); // only the holder can check the balance
        return balanceOf(dpAddr, tokenId) > 0;
    }


    /// @dev get all tokens for an owner
    function getOwnerTokens(address owner) public view returns (uint256[] memory) {
        return _ownerTokens[owner];
    }
}
