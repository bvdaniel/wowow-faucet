pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract tokenDeployer is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner, string memory name, string memory symbol, uint256 amount, uint256 _decimals) Ownable(initialOwner) ERC20(name, symbol) {
        _mint(initialOwner, amount * 10 ** _decimals);
       // transferOwnership(0xc59456f40E0d6fB484b0e83502f07fa7B9A75f37);
    }
}