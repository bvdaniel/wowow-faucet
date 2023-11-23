// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/tokenDropVesting.sol";
import "../src/CustomERC20.sol";  // Import the CustomERC20 contract you've created
contract tokenDropVestingTest is Test {
    CustomERC20 token;  // Use CustomERC20 instead of ERC20
    address owner = makeAddr("owner");
    event LogTokenBalance(string message, uint256 balance);


    address[] investors = [
        0x85CC29F41F6E9b8648442000bB1F87e7A12fd99E,
        0x89d36091F9ec93c98756eD90BCADd72A713759F7,
        0x9437Fe6385F3551850FD892D471FFbc818CF3116
    ];


    uint128 totalRoundTokens = 5000 * 731 * 1e18 ;

        uint128[] tokens = [
        totalRoundTokens/10,
        totalRoundTokens*2/10,
        totalRoundTokens*7/10
    ];

    address triggerAddress = 0x092E67E9dbc47101760143f95056569CB0b3324f;

    uint40 cliffMonths = 0;
    uint40 vestingMonths = 25;
    //uint40 vestingMonthsLargeInvestor = 48;

    tokenDropVesting tokenVest;

    function setUp() public {
        // Deploy the CustomERC20 token contract
        token = new CustomERC20();
        // Transfer totalRoundTokens to the vesting contract
      
        // Deploy tokenDropVesting contract
        tokenVest = new tokenDropVesting(address(token));
        token.transfer(address(tokenVest), totalRoundTokens);

        // Whitelist the trigger (replace with the actual function call)
        tokenVest.whitelistTrigger(triggerAddress);
        assert(tokenVest.s_triggerWhitelisted(triggerAddress));
      
        assert(token.balanceOf(address(tokenVest)) == totalRoundTokens);

       
    }

    // Test loading data into the contract
    function testLoadData() public {
      uint128 allocatedTokens;
        vm.prank(triggerAddress);
        // Store the current number of events emitted
        // uint256 initialEventCount = vm.eventsCount();
        tokenVest.loadVestingData(investors, tokens, cliffMonths, vestingMonths, false);
        // Calculate the number of events emitted after the function call
        for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the tokenDropVesting contract
        allocatedTokens = tokenVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        }
    }
    function testdropVest() public {
        uint128 allocatedTokens;
        vm.prank(triggerAddress);
        // Store the current number of events emitted
        // uint256 initialEventCount = vm.eventsCount();
        tokenVest.loadVestingData(investors, tokens, cliffMonths, vestingMonths, true);
        // Calculate the number of events emitted after the function call
        for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the tokenDropVesting contract
        allocatedTokens = tokenVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        }
        emit log_uint(block.timestamp);
        vm.prank(triggerAddress);
        tokenVest.dropTokens();

    // Check if the tokens are dropped
    for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the tokenDropVesting contract
        allocatedTokens = tokenVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        // _claimableAmount is 0
        // claimedTokens is allocation/vestingMonths

        (,uint128 _claimableAmount,,,) = tokenVest.allocations(investors[i]);
        assert(_claimableAmount == 0);
        (,,uint128 claimedTokens,,) = tokenVest.allocations(investors[i]);
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
        allocatedTokens = tokenVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        // _claimableAmount is allocation/vestingMonths
        // claimedTokens is allocation/vestingMonths
        uint128 vestedAmount = tokenVest.calculateVestedAmount(investors[i]);
        assert(vestedAmount == 2*tokens[i]/vestingMonths);
        (,,uint128 claimedTokens,,) = tokenVest.allocations(investors[i]);
        assert(claimedTokens == tokens[i]/vestingMonths);
        uint256 investorBalance = token.balanceOf(investors[i]);
        // Assert that the investor's balance remains the same 
        assert(investorBalance == tokens[i]/vestingMonths);
    }

    vm.prank(triggerAddress);
    tokenVest.dropTokens();
      for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the tokenDropVesting contract
        allocatedTokens = tokenVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding tokens in the array
        assert(allocatedTokens == tokens[i]);
        // _claimableAmount is 2*allocation/vestingMonths
        // claimedTokens is 2*allocation/vestingMonths
        uint128 vestedAmount = tokenVest.calculateVestedAmount(investors[i]);
        assert(vestedAmount == 2*tokens[i]/vestingMonths);
        (,,uint128 claimedTokens,,) = tokenVest.allocations(investors[i]);
        assert(claimedTokens == 2*tokens[i]/vestingMonths);
        uint256 investorBalance = token.balanceOf(investors[i]);
        // Assert that the investor's balance remains the same 
        assert(investorBalance == 2*tokens[i]/vestingMonths);
    }
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
