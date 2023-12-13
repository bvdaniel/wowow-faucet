// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/tokenDeployerV2.sol";
contract tokenDeployerTest is Test {
    uint256 polygonFork;
    string MAINNET_RPC_URL = vm.envString("POLYGON_MAINNET_RPC_URL");
    tokenDeployerV2 _tokenDeployerV2;

   
    address owner = makeAddr("owner");
    string name = "newToken";
    string symbol = "NTK";
    uint256 amount = 10000;
    uint256 decimals = 18;
    address _owner = 0xc59456f40E0d6fB484b0e83502f07fa7B9A75f37;
    address _newOwner = 0xC2628eDdDB676c4cAF68aAD55d2191F6c9668624;

    //@Events
    event LogTokenBalance(string message, uint256 balance);
    event LogValue(string message, uint256 value);
    event LogVestingDuration(string message, uint256 vestingDuration);

    function setUp() public {
        polygonFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(polygonFork);
        vm.rollFork(49257792);
        // Deploy tokenSale contract
        //_tokenDeployer = new tokenDeployer(address(_owner), name, symbol, amount, decimals);
        _tokenDeployerV2 = new tokenDeployerV2(address(_owner), name, symbol, amount, decimals);
   }

    function testSettings() public {
    assertEq(_tokenDeployerV2.name(), name, "name not set");
   }

    function testOwnership() public{
      // check balance of owner

        // Get the deployed ERC20 token address
        address tokenAddress = address(_tokenDeployerV2);
        // check balance of the deployed ERC20 token
        assertEq(ERC20(tokenAddress).balanceOf(_owner), amount * 10**decimals, "Incorrect initial balance");
        emit LogTokenBalance("Owner tokenBalance: ", ERC20(tokenAddress).balanceOf(_owner));
        // check ownership of owner
        assertEq(address(_tokenDeployerV2.owner()), _owner, "Incorrect owner");
   
    }

    function testMint() public{
        // check balance of owner

        // Get the deployed ERC20 token address
        address tokenAddress = address(_tokenDeployerV2);
        // Try to mint newMint amount 
        uint256 newMint = 2 * 10**decimals;
        vm.prank(_owner);
        _tokenDeployerV2.mint(_owner, newMint);

        assertEq(ERC20(tokenAddress).balanceOf(_owner),newMint +amount * 10**decimals, "Incorrect new balance");
        emit LogTokenBalance("Owner tokenBalance: ", ERC20(tokenAddress).balanceOf(_owner));
   
    }

     function testTransferOwnership() public{
        // check balance of owner
        // Try to mint newMint amount 
        address newOwner = _newOwner;
        vm.prank(_owner);
        _tokenDeployerV2.transferOwnership(newOwner);
        assertEq(address(_tokenDeployerV2.owner()), newOwner, "Incorrect new owner");   
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
