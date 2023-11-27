// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/tokenPreSaleAndDropVesting.sol";
import "../src/CustomERC20.sol";  // Import the CustomERC20 contract you've created
contract tokenPreSaleAndDropVestingTest is Test {
    uint256 polygonFork;
    string MAINNET_RPC_URL = vm.envString("POLYGON_MAINNET_RPC_URL");
    CustomERC20 token;  // Use CustomERC20 instead of ERC20
    address owner = makeAddr("owner");
    event LogTokenBalance(string message, uint256 balance);
    event LogValue(string message, uint256 value);
    event LogVestingDuration(string message, uint256 vestingDuration);



    address[] investors = [
        0x505e71695E9bc45943c58adEC1650577BcA68fD9,
        0x627d05f2760118daa6264343597B9A48ff83b503,
        0x06959153B974D0D5fDfd87D561db6d8d4FA0bb0B
    ];

    address triggerAddress = 0x092E67E9dbc47101760143f95056569CB0b3324f;
    address currency = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;


    uint40 cliffMonths = 3;
    uint40 vestingMonths = 24;
    uint40 largeInvestorVestedDuration = 48;
    uint40 regularInvestorVestedDuration = 24;
    uint256 investorThreshold = 5; // in percentage
    uint256 minPurchase = 100*1E6; // 100 USDT
    uint256 public TOKEN_RATE = 666;  // Tokens per buying currency
    uint256 public ROUND_SUPPLY = 100000 * TOKEN_RATE * 1E18;  // Round supply of tokens for the presale
    uint256 public TOTAL_SUPPLY = 100000 * TOKEN_RATE * 1E18; // Total supply of issued tokens 


    uint256[] tokens = [
        investorThreshold*TOTAL_SUPPLY/(1E12)/TOKEN_RATE/100-1,
        minPurchase,
        minPurchase*30
    ];
    tokenPreSaleAndDropVesting tokenPreSaleAndDrop;

    function setUp() public {
        polygonFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(polygonFork);
        vm.rollFork(49257792);
        // Deploy the CustomERC20 token contract
        token = new CustomERC20();
        // Transfer totalRoundTokens to the vesting contract
        // Deploy tokenDropVesting contract
        tokenPreSaleAndDrop = new tokenPreSaleAndDropVesting(
            address(token),
            currency,
            ROUND_SUPPLY,
            TOTAL_SUPPLY,
            TOKEN_RATE,
            vestingMonths,
            largeInvestorVestedDuration,
            regularInvestorVestedDuration,
            investorThreshold);

        token.transfer(address(tokenPreSaleAndDrop), ROUND_SUPPLY);

        // Whitelist the trigger (replace with the actual function call)
        tokenPreSaleAndDrop.whitelistTrigger(triggerAddress);
        assert(tokenPreSaleAndDrop.s_triggerWhitelisted(triggerAddress));
        assert(token.balanceOf(address(tokenPreSaleAndDrop)) == ROUND_SUPPLY);
    }

    // Test loading data into the contract
      // Test loading data into the contract
    function testBuyAllocation() public {
      uint256 allocatedTokens;
        IERC20 _currency = IERC20(currency);
        IERC20 Token = IERC20(token);

        uint256 whaleCurrencyBalance = _currency.balanceOf(investors[0]);
        emit LogTokenBalance("Investor USDTs", whaleCurrencyBalance);

        uint256 whaleTokenBalance = Token.balanceOf(investors[0]);
        emit LogTokenBalance("Investor Tokens", whaleTokenBalance);

        vm.prank(investors[0]);
        // approve moving tokens to tokenPreSaleAndDrop
        _currency.approve(address(tokenPreSaleAndDrop), tokens[0]);
        // Store the current number of events emitted
        vm.prank(investors[0]);
        tokenPreSaleAndDrop.buyAllocation(tokens[0]);
        // Calculate the number of events emitted after the function call
        allocatedTokens = tokenPreSaleAndDrop.getMyAllocation(investors[0]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[0]*TOKEN_RATE*1e12);

        uint256 whaleCurrencyBalanceAfter = _currency.balanceOf(investors[0]);
        assert(whaleCurrencyBalanceAfter == whaleCurrencyBalance - tokens[0]);

        (,,,uint256 vestedDuration) = tokenPreSaleAndDrop.allocations(investors[0]);
        emit LogVestingDuration("Investor Vesting Duration", vestedDuration);
        emit LogValue("Token Threshold", investorThreshold /100 *TOTAL_SUPPLY);
        emit LogValue("Token Threshold", investorThreshold *TOTAL_SUPPLY /100);


        // Check if regular investor, should have a regularInvestorVestedDuration
        if (allocatedTokens < investorThreshold * TOTAL_SUPPLY /100){
            assert(vestedDuration ==regularInvestorVestedDuration );
        } else assert(vestedDuration == largeInvestorVestedDuration );

        
        /* This is for drop
        uint256 whaleTokenBalanceAfter = Token.balanceOf(investors[0]);
        assert(whaleTokenBalanceAfter == whaleTokenBalance + allocatedTokens);
        */
    }
    /*
    function testdropVest() public {
        uint128 allocatedTokens;
        vm.prank(triggerAddress);
        // Store the current number of events emitted
        // uint256 initialEventCount = vm.eventsCount();
        tokenPreSaleAndDrop.loadVestingData(investors, tokens, cliffMonths, vestingMonths, true);
        // Calculate the number of events emitted after the function call
        for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the tokenDropVesting contract
        allocatedTokens = tokenPreSaleAndDrop.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        }
        emit log_uint(block.timestamp);
        vm.prank(triggerAddress);
        tokenPreSaleAndDrop.dropTokens();

    // Check if the tokens are dropped
    for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the tokenDropVesting contract
        allocatedTokens = tokenPreSaleAndDrop.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        // _claimableAmount is 0
        // claimedTokens is allocation/vestingMonths

        (,uint128 _claimableAmount,,,) = tokenPreSaleAndDrop.allocations(investors[i]);
        assert(_claimableAmount == 0);
        (,,uint128 claimedTokens,,) = tokenPreSaleAndDrop.allocations(investors[i]);
        assert(claimedTokens == tokens[i]/vestingMonths);
        uint256 investorBalance = token.balanceOf(investors[i]);
        // Assert that the investor's balance has increased by the allocatedTokens amount
        assert(investorBalance == tokens[i]/vestingMonths);
    }
    // Advance 31 days dont drop, check claimable amount is equal to one vesting
    vm.warp(31 days);
        // Check if the tokens are dropped
    for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the tokenDropVesting contract
        allocatedTokens = tokenPreSaleAndDrop.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        // _claimableAmount is allocation/vestingMonths
        // claimedTokens is allocation/vestingMonths
        uint128 vestedAmount = tokenPreSaleAndDrop.calculateVestedAmount(investors[i]);
        assert(vestedAmount == 2*tokens[i]/vestingMonths);
        (,,uint128 claimedTokens,,) = tokenPreSaleAndDrop.allocations(investors[i]);
        assert(claimedTokens == tokens[i]/vestingMonths);
        uint256 investorBalance = token.balanceOf(investors[i]);
        // Assert that the investor's balance remains the same 
        assert(investorBalance == tokens[i]/vestingMonths);
    }

    vm.prank(triggerAddress);
    tokenPreSaleAndDrop.dropTokens();
      for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the tokenDropVesting contract
        allocatedTokens = tokenPreSaleAndDrop.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        // _claimableAmount is 2*allocation/vestingMonths
        // claimedTokens is 2*allocation/vestingMonths
        uint128 vestedAmount = tokenPreSaleAndDrop.calculateVestedAmount(investors[i]);
        assert(vestedAmount == 2*tokens[i]/vestingMonths);
        (,,uint128 claimedTokens,,) = tokenPreSaleAndDrop.allocations(investors[i]);
        assert(claimedTokens == 2*tokens[i]/vestingMonths);
        uint256 investorBalance = token.balanceOf(investors[i]);
        // Assert that the investor's balance remains the same 
        assert(investorBalance == 2*tokens[i]/vestingMonths);
    }
    }*/
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
