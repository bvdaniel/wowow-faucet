pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Faucet {
    uint256 public tokenAmount;
    uint256 public waitTime;
    address public owner;

    ERC20 public tokenInstance;
    
    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance) {
        require(_tokenInstance != address(0));
        tokenInstance = ERC20(_tokenInstance);
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner");
        _;
    }

    function requestTokens(address _receiver) public {
        require(allowedToWithdraw(_receiver));
        tokenInstance.transfer(_receiver, tokenAmount);
        lastAccessTime[_receiver] = block.timestamp + waitTime;
    }

    function setDelay (uint256 _waitTime) public onlyOwner {
            waitTime = _waitTime * 1 minutes;
    }

    function setAmount (uint256 _tokenAmount) public onlyOwner {
            tokenAmount = _tokenAmount;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}