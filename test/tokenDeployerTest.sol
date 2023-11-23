// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/tokenDeployer.sol";
contract tokenDeployerTest is Test {
    uint256 polygonFork;
    string MAINNET_RPC_URL = vm.envString("POLYGON_MAINNET_RPC_URL");
    tokenDeployer _tokenDeployer;
   
    address owner = makeAddr("owner");
    string name = "newToken";
    string symbol = "NTK";
    uint256 amount = 10000;
    uint256 decimals = 18;
    address _owner = 0xc59456f40E0d6fB484b0e83502f07fa7B9A75f37;

    function setUp() public {
        polygonFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(polygonFork);
        vm.rollFork(49257792);
        // Deploy tokenSale contract
        _tokenDeployer = new tokenDeployer(address(_owner), name, symbol, amount, decimals);
   }

    function testOwnership() public{
      // check balance of owner

        // Get the deployed ERC20 token address
        address tokenAddress = address(_tokenDeployer);
        // check balance of the deployed ERC20 token
        assertEq(ERC20(tokenAddress).balanceOf(_owner), amount * 10**decimals, "Incorrect initial balance");
        // check ownership of owner
        assertEq(address(_tokenDeployer.owner()), _owner, "Incorrect owner");
   
    }



    // Helper function to convert uint to string
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        temp = value;
        
        while (temp != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        
        return string(buffer);
    }
}
