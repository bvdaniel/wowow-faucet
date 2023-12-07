// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/tokenPreSaleAndDropVesting.sol";
import "../src/CustomERC20.sol";  // Import the CustomERC20 contract you've created
contract tokenPreSaleAndDropVestingTest is Test {
    uint256 polygonFork;
    string MAINNET_RPC_URL = vm.envString("POLYGON_MAINNET_RPC_URL");
    CustomERC20 token;  // Use CustomERC20 instead of ERC20 for company currency
    CustomERC20 usdtToken;  // Use CustomERC20 instead of ERC20 for payment currency

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
    uint256 cliffMonths = 3;
    uint256 largeInvestorVestedDuration = 48;
    uint256 regularInvestorVestedDuration = 24;
    uint256 investorThreshold = 5; // in percentage
    uint256 minPurchase = 100*1E6; // 100 USDT
    uint256 initialFork = 49_257_792;
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
        //polygonFork = vm.createFork(MAINNET_RPC_URL);
        //vm.selectFork(polygonFork);
        // Days to go back
        uint256 beforeTimestamp = calculateTimestampBefore(initialFork,5);
        // Calculate the new timestamp after advancing N days
        //vm.rollFork(beforeTimestamp);
        // Deploy the CustomERC20 token contract
        token = new CustomERC20();
        usdtToken = new CustomERC20();
        // Transfer totalRoundTokens to the vesting contract
        // Deploy tokenDropVesting contract
        tokenPreSaleAndDrop = new tokenPreSaleAndDropVesting(
            address(token),
            address(usdtToken),
            ROUND_SUPPLY,
            TOTAL_SUPPLY,
            TOKEN_RATE,
            largeInvestorVestedDuration,
            regularInvestorVestedDuration,
            investorThreshold);

        token.transfer(address(tokenPreSaleAndDrop), ROUND_SUPPLY);
        usdtToken.transfer(address(investors[0]), tokens[0]);
        usdtToken.transfer(address(investors[1]), tokens[1]);
        usdtToken.transfer(address(investors[2]), tokens[2]);


        // Whitelist the trigger (replace with the actual function call)
        tokenPreSaleAndDrop.whitelistTrigger(triggerAddress);
        tokenPreSaleAndDrop.setMinPurchase(minPurchase);
        assert(tokenPreSaleAndDrop.s_triggerWhitelisted(triggerAddress));
        assert(token.balanceOf(address(tokenPreSaleAndDrop)) == ROUND_SUPPLY);
    }

    function calculateTimestampBefore(uint256 initialTimestamp, uint256 monthsAgo) internal pure returns (uint256) {
    // Calculate the number of seconds in 5 months
    uint256 secondsAgo = monthsAgo * 30 days; // 1 day = 86400 seconds

    // Calculate the new timestamp by subtracting the seconds in 5 months
    return initialTimestamp - secondsAgo;
}


    // Test buying allocation
    function testBuyAllocation() public {
      uint256 allocatedTokens;
        IERC20 _currency = IERC20(address(usdtToken));
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
        // Get allocated tokens
        allocatedTokens = tokenPreSaleAndDrop.getMyAllocation(investors[0]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[0]*TOKEN_RATE*1e12);

        uint256 whaleCurrencyBalanceAfter = _currency.balanceOf(investors[0]);
        assert(whaleCurrencyBalanceAfter == whaleCurrencyBalance - tokens[0]);

        (,,,uint256 vestedDuration) = tokenPreSaleAndDrop.allocations(investors[0]);

        // Check if regular investor, should have a regularInvestorVestedDuration
        if (allocatedTokens < investorThreshold * TOTAL_SUPPLY /100){
            assert(vestedDuration ==regularInvestorVestedDuration );
        } else assert(vestedDuration == largeInvestorVestedDuration );



        /* This is for drop
        uint256 whaleTokenBalanceAfter = Token.balanceOf(investors[0]);
        assert(whaleTokenBalanceAfter == whaleTokenBalance + allocatedTokens);*/
        
    }
    
    function testDropTokensUnsetCliff() public {
        uint128 allocatedTokens;
        //buy allocation
        testBuyAllocation();
        vm.prank(triggerAddress);
        vm.expectRevert("Cliff not set yet");
        tokenPreSaleAndDrop.dropTokens();
        //Should fail if the cliff is not set yet

    }

    function testDropTokensSetCliff() public {
        IERC20 Token = IERC20(token);
        //buy allocation
        testBuyAllocation();
        uint256 investorBalanceBefore = Token.balanceOf(investors[0]);

        //vm.prank(triggerAddress);
        tokenPreSaleAndDrop.setCliffEnd(0);
        vm.prank(triggerAddress);
        tokenPreSaleAndDrop.dropTokens();
        //Should drop no tokens
        (,,uint256 claimedTokens,) = tokenPreSaleAndDrop.allocations(investors[0]);
        assert(claimedTokens == 0);
        //Investor balance should not change
        uint256 investorBalanceAfter = Token.balanceOf(investors[0]);
        // Assert that the investor's balance has increased by the allocatedTokens amount
        assert(investorBalanceAfter == investorBalanceBefore);

        uint256 initialWarp = 31 days;
        // Roll the fork to the new timestamp
        emit LogValue("Initial block.timestamp: ", block.timestamp);
        vm.warp(initialWarp);
        emit LogValue("After warp block.timestamp: ", block.timestamp);

        
        uint256 vestedTokens = tokenPreSaleAndDrop.calculateVestedAmount(investors[0]);
        emit LogValue("vestedTokens", vestedTokens);

        (,uint256 allocatedTokens,,) = tokenPreSaleAndDrop.allocations(investors[0]);
        assert(allocatedTokens == tokens[0]*TOKEN_RATE*1e12);

        assert(vestedTokens == tokens[0]*TOKEN_RATE*1e12/regularInvestorVestedDuration);

        //Check 2 months
        vm.warp(initialWarp*2);
        emit LogValue("After 2nd warp block.timestamp: ", block.timestamp);
        vm.prank(triggerAddress);
        tokenPreSaleAndDrop.dropTokens();
   
        vestedTokens = tokenPreSaleAndDrop.calculateVestedAmount(investors[0]);
        emit LogValue("vestedTokens", vestedTokens);

        assert(vestedTokens == tokens[0]*TOKEN_RATE*1e12/regularInvestorVestedDuration*2);

        //Investor balance should change
        investorBalanceAfter = Token.balanceOf(investors[0]);
        // Assert that the investor's balance has increased by the allocatedTokens amount
        assert(investorBalanceAfter == vestedTokens);

        //Final drop
        vm.warp(initialWarp*regularInvestorVestedDuration);
        emit LogValue("After final warp block.timestamp: ", block.timestamp);
        vm.prank(triggerAddress);
        tokenPreSaleAndDrop.dropTokens();
   
        vestedTokens = tokenPreSaleAndDrop.calculateVestedAmount(investors[0]);
        emit LogValue("vestedTokens", vestedTokens);

        assert(vestedTokens == tokens[0]*TOKEN_RATE*1e12);
        //Investor balance should change
        investorBalanceAfter = Token.balanceOf(investors[0]);
        // Assert that the investor's balance has increased by the allocatedTokens amount
        assert(investorBalanceAfter == vestedTokens);

    }
        // Function to calculate the timestamp after advancing N days
    function calculateTimestamp(uint256 initialTimestamp, uint256 daysToAdvance) internal pure returns (uint256) {
        return initialTimestamp + daysToAdvance * 1 days; // 1 day = 86400 seconds
    }

    /* Check if the tokens are dropped
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
