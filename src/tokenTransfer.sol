// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract tokenTransfer is Ownable {
    mapping(address => bool) public s_triggerWhitelisted;  // Whitelisted triggers
    address token;
    modifier onlyTrigger() {
        require(
            s_triggerWhitelisted[msg.sender] == true,
            "OnlyTriggers"
        );
        _;
    }
    constructor(address owner, address _token) Ownable(owner) {
        token = _token;
    }

    function transferTo(uint256 amount, address _to) public onlyTrigger{
        IERC20(token).transfer(_to, amount);
    }

     /**
     * @dev Sets the wav3s trigger addresses. This can only be called by the contract owner.
     * @param _trigger The new wav3s trigger address.
     */

    function whitelistTrigger(address _trigger) external onlyOwner {
        s_triggerWhitelisted[_trigger] = true;
    }
}
