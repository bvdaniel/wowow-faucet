// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Faucet.sol";

contract FaucetTest is Test {
    uint256 polygonFork;
    string MAINNET_RPC_URL = vm.envString("POLYGON_MAINNET_RPC_URL");
    FaucetTest _FaucetTest;
   
    address owner = makeAddr("owner");
    string name = "newToken";
    string symbol = "NTK";
    uint256 amount = 10000;
    uint128 tokenAmount = 5000 * 1e18 ;
    uint256 decimals = 18;
    address _owner = 0xc59456f40E0d6fB484b0e83502f07fa7B9A75f37;  
    address triggerAddress = 0x092E67E9dbc47101760143f95056569CB0b3324f;
    address receiber = 0xC2628eDdDB676c4cAF68aAD55d2191F6c9668624;

    //@Events
    event LogTokenBalance(string message, uint256 balance);
    event LogValue(string message, uint256 value);
    event LogAddress(string message, address value);

    event LogVestingDuration(string message, uint256 vestingDuration);

    function setUp() public {
        polygonFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(polygonFork);
          // Deploy the CustomERC20 token contract
        //emit LogAddress("CustomERC20", address(token));

        // Transfer totalRoundTokens to the vesting contract
      
        // Deploy tokenTransfer contract
        //_FaucetTest = new FaucetTest(_owner, address(token));
        //token.transfer(address(_FaucetTest), tokenAmount);

        // Whitelist the trigger (replace with the actual function call)
        vm.prank(_owner);
        //_FaucetTest.whitelistTrigger(triggerAddress);
        //assert(_FaucetTest.s_triggerWhitelisted(triggerAddress));
      
        //assert(token.balanceOf(address(_FaucetTest)) == tokenAmount);
   }

   function testTransferTokens() public {
    vm.prank(triggerAddress);
    //_FaucetTest.transferTo(tokenAmount,receiber);
   // assert(token.balanceOf(address(receiber)) == tokenAmount);


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
