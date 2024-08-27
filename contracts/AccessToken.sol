// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol"; // auto-generated

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

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
    mapping (bytes32 attributesHash => bool hasMinted) private dpHasMinted;

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
        bytes32 nullifier = keccak256(abi.encodePacked(msg.sender, tokenId));
        require(dpAttrHash[msg.sender] != bytes32(0), "Data processor has not been registered");
        require(dpAttrHash[msg.sender] == attributesHash, "Invalid attributes hash");
        require(!dpHasMinted[nullifier], "Token has been minted");

        // tokenId is committed in the proof
        bytes memory journal = abi.encode(tokenId);
        verifier.verify(seal, imageId, sha256(journal));
        _mint(msg.sender, tokenId, 1, "");
        dpHasMinted[nullifier] = true;
        emit AccessTokenMinted(msg.sender, tokenId);
    }

    /// @dev get balance for data processor
    function getDPBalance(
        address dpAddr,
        uint256 tokenId,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 msgHash = getMessageHash(dpAddr, tokenId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(msgHash);
        address signer = recoverSigner(ethSignedMessageHash, signature);
        require(signer == dpAddr, "Invalid signature"); // only the holder can check the balance
        return balanceOf(dpAddr, tokenId) > 0;
    }

    /// @dev get all tokens for an owner
    function getOwnerTokens(address owner) public view returns (uint256[] memory) {
        return _ownerTokens[owner];
    }

    // helper functions for ecdsa
    function getMessageHash(
        address _addr,
        uint256 _tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _tokenId));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public 
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _sig
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
