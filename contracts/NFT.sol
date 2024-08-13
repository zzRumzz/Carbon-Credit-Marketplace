// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCarbon is ERC721URIStorage, Ownable{
    uint256 tokenCounter;

    constructor(address owner) ERC721("NFTCarbon", "NFTCBC") Ownable(owner){
        owner = payable(msg.sender);
        tokenCounter = 0;

    }

    function createCarbonToken(string memory tokenURI) public onlyOwner returns(uint256){
        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _transfer(msg.sender,address(this),newTokenId);
        tokenCounter++;
        return newTokenId;
    }
    function tokenCounters() public returns(uint256) {
        return tokenCounter;
    }
}