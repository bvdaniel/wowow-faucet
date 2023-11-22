// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ZurfDropVesting.sol";
import "../src/CustomERC20.sol";  // Import the CustomERC20 contract you've created
contract zurfDropVestingTest is Test {
    CustomERC20 token;  // Use CustomERC20 instead of ERC20
    address owner = makeAddr("owner");
    event LogTokenBalance(string message, uint256 balance);


    address[] investors = [
        0x85CC29F41F6E9b8648442000bB1F87e7A12fd99E,
        0x89d36091F9ec93c98756eD90BCADd72A713759F7,
        0x9437Fe6385F3551850FD892D471FFbc818CF3116
    ];


    uint128 totalRoundTokens = 5000 * 731 * 1e18 ;

        uint128[] zurfTokens = [
        totalRoundTokens/10,
        totalRoundTokens*2/10,
        totalRoundTokens*7/10
    ];

    address triggerAddress = 0x092E67E9dbc47101760143f95056569CB0b3324f;

    uint40 cliffMonths = 0;
    uint40 vestingMonths = 25;
    //uint40 vestingMonthsLargeInvestor = 48;

    zurfDropVesting zurfVest;

    function setUp() public {
        // Deploy the CustomERC20 token contract
        token = new CustomERC20();
        // Transfer totalRoundTokens to the vesting contract
      
        // Deploy ZurfRound0Vesting contract
        zurfVest = new zurfDropVesting(address(token));
        token.transfer(address(zurfVest), totalRoundTokens);

        // Whitelist the trigger (replace with the actual function call)
        zurfVest.whitelistZurfTrigger(triggerAddress);
        assert(zurfVest.s_triggerWhitelisted(triggerAddress));
      
        assert(token.balanceOf(address(zurfVest)) == totalRoundTokens);

       
    }

    // Test loading data into the contract
    function testLoadData() public {
      uint128 allocatedTokens;
        vm.prank(triggerAddress);
        // Store the current number of events emitted
        // uint256 initialEventCount = vm.eventsCount();
        zurfVest.loadVestingData(investors, zurfTokens, cliffMonths, vestingMonths, false);
        // Calculate the number of events emitted after the function call
        for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the ZurfRound0Vesting contract
        allocatedTokens = zurfVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding zurfTokens in the array
        assert(allocatedTokens == zurfTokens[i]);
        }
    }
    function testdropVest() public {
        uint128 allocatedTokens;
        vm.prank(triggerAddress);
        // Store the current number of events emitted
        // uint256 initialEventCount = vm.eventsCount();
        zurfVest.loadVestingData(investors, zurfTokens, cliffMonths, vestingMonths, true);
        // Calculate the number of events emitted after the function call
        for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the ZurfRound0Vesting contract
        allocatedTokens = zurfVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding zurfTokens in the array
        assert(allocatedTokens == zurfTokens[i]);
        }
        emit log_uint(block.timestamp);
        vm.prank(triggerAddress);
        zurfVest.dropTokens();

    // Check if the tokens are dropped
    for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the ZurfRound0Vesting contract
        allocatedTokens = zurfVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding zurfTokens in the array
        assert(allocatedTokens == zurfTokens[i]);
        // _claimableAmount is 0
        // claimedTokens is allocation/vestingMonths

        (,uint128 _claimableAmount,,,) = zurfVest.allocations(investors[i]);
        assert(_claimableAmount == 0);
        (,,uint128 claimedTokens,,) = zurfVest.allocations(investors[i]);
        assert(claimedTokens == zurfTokens[i]/vestingMonths);
        uint256 investorBalance = token.balanceOf(investors[i]);
        // Assert that the investor's balance has increased by the allocatedTokens amount
        assert(investorBalance == zurfTokens[i]/vestingMonths);
    }
    // Advance 31 days dont drop, check claimable amount is equal to one vesting
    vm.warp(31 days);
        // Check if the tokens are dropped
    for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the ZurfRound0Vesting contract
        allocatedTokens = zurfVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding zurfTokens in the array
        assert(allocatedTokens == zurfTokens[i]);
        // _claimableAmount is allocation/vestingMonths
        // claimedTokens is allocation/vestingMonths
        uint128 vestedAmount = zurfVest.calculateVestedAmount(investors[i]);
        assert(vestedAmount == 2*zurfTokens[i]/vestingMonths);
        (,,uint128 claimedTokens,,) = zurfVest.allocations(investors[i]);
        assert(claimedTokens == zurfTokens[i]/vestingMonths);
        uint256 investorBalance = token.balanceOf(investors[i]);
        // Assert that the investor's balance remains the same 
        assert(investorBalance == zurfTokens[i]/vestingMonths);
    }

    vm.prank(triggerAddress);
    zurfVest.dropTokens();
      for (uint256 i = 0; i < investors.length; i++) {
        // Get the investor's allocation struct from the ZurfRound0Vesting contract
        allocatedTokens = zurfVest.getMyAllocation(investors[i]);
        // Assert that the allocatedTokens match the corresponding zurfTokens in the array
        assert(allocatedTokens == zurfTokens[i]);
        // _claimableAmount is 2*allocation/vestingMonths
        // claimedTokens is 2*allocation/vestingMonths
        uint128 vestedAmount = zurfVest.calculateVestedAmount(investors[i]);
        assert(vestedAmount == 2*zurfTokens[i]/vestingMonths);
        (,,uint128 claimedTokens,,) = zurfVest.allocations(investors[i]);
        assert(claimedTokens == 2*zurfTokens[i]/vestingMonths);
        uint256 investorBalance = token.balanceOf(investors[i]);
        // Assert that the investor's balance remains the same 
        assert(investorBalance == 2*zurfTokens[i]/vestingMonths);
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
