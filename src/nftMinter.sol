// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract nftMinter is ERC721URIStorage, Ownable {
    mapping(uint256 => string) idToTokenURI;
    uint256 nextId = 1;
    mapping(address => bool) public s_triggerWhitelisted;  // Whitelisted triggers

    modifier onlyTrigger() {
        require(
            s_triggerWhitelisted[msg.sender] == true,
            "OnlyTriggers"
        );
        _;
    }

    constructor(address initialOwner) ERC721("Kritties", "KTRS") Ownable(initialOwner) {}

    function mintNFT(address user, uint256 _nftId)
        public 
    {
        _mint(user, nextId);
        _setTokenURI(nextId, idToTokenURI[_nftId]);
        nextId++;
    }

    function registerNFT(uint256 _nftId, string memory _tokenURI) public {
        idToTokenURI[_nftId] = _tokenURI;
    }
         /**
     * @dev Sets the trigger addresses. This can only be called by the contract owner.
     * @param _trigger The new trigger address.
     */

    function whitelistTrigger(address _trigger) external  {
        s_triggerWhitelisted[_trigger] = true;
    }
}