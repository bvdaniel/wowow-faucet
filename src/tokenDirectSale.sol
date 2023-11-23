// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PresaleEvents} from "./PresaleEvents.sol";

/**
 * @title TokenSale
 * @dev A smart contract for handling a token sale using USDT (Tether).
 */
contract tokenDirectSale {
    address public token;  // Address of the token contract
    address public usdt;  // Address of the USDT contract
    address public owner;  // Address of the contract owner
    address public vault;    // The address of the vault contract.
    uint256 public minPurchase;    // Minimum purchase amount in USDT
    uint256 public tokenRate;  // Tokens per USDT 
    uint256 public tokenAmount;  // Total supply of tokens for sale

    struct Allocation {
        uint256 amountBought;  // Amount of USDT bought by the investor
        uint256 allocatedTokens; // Amount of tokens allocated to the investor
    }

    mapping(address => Allocation) public allocations;  // Allocations for each investor
    uint256 public investorsCount;  // Total count of investors
    mapping(uint256 => address) public investorIndex;  // Investor index to retrieve addresses
    mapping(address => bool) s_isInvestor; // True if investor already invested


    // PresaleEvents
    /**
     * @dev Emitted when a new investment is made by an investor during the token sale.
     * @param investor The Ethereum address of the investor who made the investment.
     * @param capital The amount of USDT invested by the investor.
     * @param allocation The number of tokens allocated to the investor as a result of the investment.
     */
    event NewInvestment(
        address investor,
        uint256 capital,
        uint256 allocation
    );

    /**
     * @dev Emitted when a round of the Zurf token presale finishes successfully.
     */
    event RoundFinished();


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor(address _token, address _usdt, address _owner) {
        token = _token;
        usdt = _usdt;
        owner = _owner;
    }
    /**
     * @dev Allows an investor to buy Zurf token allocations using USDT.
     * @param usdtAmount The amount of USDT to invest.
     */
    function buyAllocation(uint256 usdtAmount) external {
        // Ensure that the investment amount meets the minimum purchase requirement
        require(usdtAmount >= minPurchase, "Not enough minimum buying amount USDT.");
        // Calculate the amount of Zurf tokens to allocate based on the token rate
        uint256 tokens = (usdtAmount*1E12) * tokenRate;  
        // Ensure that there are enough remaining Zurf tokens for allocation
        require(tokens <= getRemainingTokens(), "Insufficient tokens available for allocation.");
        // Get the allocation data for the current investor
        Allocation storage allocation = allocations[msg.sender];
        // Update the investor's allocation details
        allocation.amountBought += usdtAmount;
        allocation.allocatedTokens += tokens;
        
        // Only count new investors if they are new investors
        if(s_isInvestor[msg.sender]==false){
        investorsCount++;
        investorIndex[investorsCount] = msg.sender;
        s_isInvestor[msg.sender] = true;
        }
        // Transfer fee amount in USDT from the caller to the vault
        IERC20(usdt).transferFrom(msg.sender, vault, usdtAmount);
        // Transfer token amount from the contract to the investor
        IERC20(token).transfer(msg.sender, tokens);
      
        emit PresaleEvents.NewInvestment(
            msg.sender,
            usdtAmount,
            tokens);

        // Check if the round is finished
        if(getRemainingTokens() == 0) {
             emit PresaleEvents.RoundFinished();
        }
    }

    /**
     * @dev Returns the allocated Zurf tokens for a specific investor.
     * @param investor The Ethereum address of the investor.
     * @return The number of Zurf tokens allocated to the investor.
     */
    function getMyAllocation(address investor) external view returns (uint256) {
        return allocations[investor].allocatedTokens;
    }

    /**
     * @dev Calculates the remaining Zurf tokens that are available for allocation.
     * @return The number of Zurf tokens remaining for allocation.
     */
    function getRemainingTokens() internal view returns (uint256) {
        return tokenAmount - getTotalAllocatedTokens();
    }

    /**
     * @dev Calculates the total number of Zurf tokens that have been allocated to all investors.
     * @return The total number of allocated Zurf tokens.
     */
    function getTotalAllocatedTokens() internal view returns (uint256) {
        uint256 total = 0;
        // Iterate through each investor's allocation to sum up allocated tokens
        for (uint256 i = 1; i <= investorsCount; i++) {
            address investor = investorIndex[i];
            total += allocations[investor].allocatedTokens;
        }
        return total;
    }

    /**
     * @dev Allows the contract owner to perform a backdoor withdrawal of both USDT and Zurf tokens to a specified vault address.
     * Only the contract owner can call this function.
     * @param vaultAddress The address to which the USDT and Zurf token balances will be transferred.
     */
    function withdrawTokens(address vaultAddress) external onlyOwner {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(vaultAddress, tokenBalance);
    }

    /**
     * @dev Sets the minimum purchase requirement for investments.
     * Only the contract owner can call this function.
     * @param _minPurchase The new minimum purchase requirement in USDT.
     */
    function setMinPurchase(uint256 _minPurchase) external onlyOwner {
        minPurchase = _minPurchase;
    }

    /**
     * @dev Sets the total token amount available for the presale.
     * Only the contract owner can call this function.
     * @param _tokenAmount The new total token amount for the presale.
     */
    function setTokenAmount(uint256 _tokenAmount) external onlyOwner {
        tokenAmount = _tokenAmount;
    }

    /**
     * @dev Sets the token rate that determines how many Zurf tokens an investor receives per USDT.
     * Only the contract owner can call this function.
     * @param _tokenRate The new token rate, representing Zurf tokens per USDT.
     */
    function setTokenRate(uint256 _tokenRate) external onlyOwner {
        tokenRate = _tokenRate;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /** @notice To be able to pay and fallback
     */
    receive() external payable {}

    fallback() external payable {}
}