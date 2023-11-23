// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/tokenDirectSale.sol";
contract TokenSaleTest is Test {
    uint256 polygonFork;
    string MAINNET_RPC_URL = vm.envString("POLYGON_MAINNET_RPC_URL");
    tokenDirectSale tokenSale;
   
    address owner = makeAddr("owner");
    address token = 0x28C043116B7E11776Bd27a945E8d9700222B8804;
    address _owner = 0xc59456f40E0d6fB484b0e83502f07fa7B9A75f37;
    address vault = 0x89d36091F9ec93c98756eD90BCADd72A713759F7;
    address usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    uint256 tokenRate = 2500;
    event LogTokenBalance(string message, uint256 balance);


    address[] investors = [
        0xC2628eDdDB676c4cAF68aAD55d2191F6c9668624,
        0x89d36091F9ec93c98756eD90BCADd72A713759F7,
        0x9437Fe6385F3551850FD892D471FFbc818CF3116
    ];

    uint256[] toInvest = [
        1000000,
        300000000,
        300000000
    ];
    uint256 totalRoundTokens = 10000 * 1e18 ;

    function setUp() public {
        polygonFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(polygonFork);
        vm.rollFork(49257792);
        assertEq(block.number, 49257792);
        IERC20 Token = IERC20(token);
        // Deploy tokenSale contract
        tokenSale = new tokenDirectSale(address(token), address(usdt), address(_owner));
        vm.prank(_owner);
        Token.transfer(address(tokenSale), totalRoundTokens);
        assert(Token.balanceOf(address(tokenSale)) == totalRoundTokens);
        emit LogTokenBalance("Tokens in contract", Token.balanceOf(address(tokenSale)));


        // Whitelist the trigger (replace with the actual function call)
        vm.prank(_owner);
        tokenSale.setMinPurchase(1000000);
        assert(tokenSale.minPurchase() == 1000000);
        vm.prank(_owner);
        tokenSale.setTokenRate(tokenRate);
        assert(tokenSale.tokenRate() == tokenRate);
        vm.prank(_owner);
        tokenSale.setTokenAmount(10000 * 1e18);
        assert(tokenSale.tokenAmount() == 10000 * 1e18);
        vm.prank(_owner);
        tokenSale.setVault(vault);
        assert(tokenSale.vault() == vault);
    }

    // Test loading data into the contract
    function testBuyAllocation() public {
      uint256 allocatedTokens;
        vm.prank(investors[0]);
        IERC20 usdtToken = IERC20(usdt);
        IERC20 Token = IERC20(token);

        uint256 whaleCurrencyBalance = usdtToken.balanceOf(investors[0]);
        emit LogTokenBalance("Investor USDTs", whaleCurrencyBalance);

        uint256 whaleTokenBalance = Token.balanceOf(investors[0]);
        emit LogTokenBalance("Investor Tokens", whaleTokenBalance);

        vm.prank(investors[0]);
        // approve moving tokens to wav3sInstance
        usdtToken.approve(address(tokenSale), toInvest[0]);
        // Store the current number of events emitted
        vm.prank(investors[0]);
        tokenSale.buyAllocation(toInvest[0]);
        // Calculate the number of events emitted after the function call
        allocatedTokens = tokenSale.getMyAllocation(investors[0]);
        // Assert that the allocatedTokens match the corresponding zurfTokens in the array
        assert(allocatedTokens == toInvest[0]*tokenRate*1e12);

        uint256 whaleCurrencyBalanceAfter = usdtToken.balanceOf(investors[0]);
        assert(whaleCurrencyBalanceAfter == whaleCurrencyBalance - toInvest[0]);
        uint256 whaleTokenBalanceAfter = Token.balanceOf(investors[0]);
        assert(whaleTokenBalanceAfter == whaleTokenBalance + allocatedTokens);
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
