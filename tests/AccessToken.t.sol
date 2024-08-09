pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../contracts/AccessToken.sol";
// import "risc0/IRiscZeroVerifier.sol";

// contract AccessTokenTest is Test {
//     AccessToken public accessToken;
//     IRiscZeroVerifier public verifier;

//     function setUp() public {
//         accessToken = new AccessToken(verifier);
//     }

//     function testCreateToken() public {
//         string memory policyString = "testPolicy";
//         string memory ctCid = "testCtCid";
//         string memory aPassCid = "testAPassCid";
//         string memory aFailCid = "testAFailCid";
//         uint256 tokenId = uint256(keccak256(abi.encodePacked(address(this))));
//         accessToken.createToken(policyString, ctCid, aPassCid, aFailCid);

//         assertEq(accessToken.tokenCreated(tokenId), true);
//         assertEq(accessToken.tokenOwner(tokenId), address(this));
//         (string memory policy, string memory ct, string memory aPass, string memory aFail) = accessToken.tokenIpfsData(tokenId);
//         assertEq(policy, policyString);
//         assertEq(ct, ctCid);
//         assertEq(aPass, aPassCid);
//         assertEq(aFail, aFailCid);
//     }

//     function testMintAccessTokenForDP() public {
//         bytes memory seal = abi.encodePacked("testSeal");
//         uint256 tokenId = 1;
//         uint256 ctCid = 1234;

//         accessToken.mintAccessTokenForDP(seal, tokenId, ctCid);

//         assertEq(accessToken.balanceOf(address(this), tokenId), 1);
//     }

//     function testGetBalance() public {
//         uint256 tokenId = 1;
//         accessToken.mintAccessTokenForDP(abi.encodePacked("testSeal"), tokenId, 1234);

//         assertEq(accessToken.getBalance(address(this), tokenId), 1);
//     }
// }

