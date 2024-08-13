// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./nftmarketplace.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    uint256 public itemsSold;
    
    
    uint256 listPrice = 100 * 10 ** 18;
    IERC20 public customToken;
    carbonToken public nftContract;

    struct listedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
        uint256 amount;
    }

    event TokenListedSuccess(
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed,
        uint256 amount
    );

    event TokenListingCancelled(
        uint256 indexed tokenId,
        address indexed owner
    );

    mapping(uint256 => listedToken) private idToListedToken;

    constructor(address customTokenAddress, address nftContractAddress, address initialOwner) Ownable(initialOwner)  {
        itemsSold = 0;
        customToken = IERC20(customTokenAddress);
        nftContract = carbonToken(nftContractAddress);
    }

    function updateListPrice(uint256 _listPrice) public onlyOwner {
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns (listedToken memory) {
        return idToListedToken[nftContract.getTokenCounter()];
    }

    function getListedTokenForId(uint256 tokenId) public view returns (listedToken memory) {
        return idToListedToken[tokenId];
    }

    function createToken(string memory tokenURI, uint256 price, uint256 totalSupply) public returns (uint256) {
        require(price > 0, "Price must be positive");
        require(customToken.transferFrom(msg.sender, address(this), listPrice), "Insufficient listing fee");

        uint256 newTokenId = nftContract.createToken(tokenURI, totalSupply);
        uint256 amount = totalSupply;

        idToListedToken[newTokenId] = listedToken(
            newTokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true,
            amount
        );

        nftContract.safeTransferFrom(msg.sender, address(this), newTokenId, amount, "");

        emit TokenListedSuccess(
            newTokenId,
            address(this),
            msg.sender,
            price,
            true,
            amount
        );

        return newTokenId;
    }

    function cancelList(uint256 tokenId, uint256 amount) public {
        require(idToListedToken[tokenId].currentlyListed, "Token is not listed");
        require(idToListedToken[tokenId].seller == msg.sender, "Only the seller can cancel the listing");

        nftContract.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        idToListedToken[tokenId].currentlyListed = false;

        emit TokenListingCancelled(tokenId, msg.sender);
    }

    function executeSale(uint256 tokenId, uint256 amount) public {
        require(idToListedToken[tokenId].amount > 0, "insufficient token amount");
        uint256 price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(customToken.transferFrom(msg.sender, seller, price), "Insufficient token balance");

        idToListedToken[tokenId].currentlyListed = false;
        idToListedToken[tokenId].seller = payable(msg.sender);
        itemsSold += 1;
        idToListedToken[tokenId].amount -= amount;

        nftContract.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        customToken.transfer(address(this), listPrice);
    }

    

    function getAllNFTs() public view returns (listedToken[] memory) {
        uint256 tokenCounter = nftContract.getTokenCounter();
        listedToken[] memory tokens = new listedToken[](tokenCounter);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < tokenCounter; i++) {
            listedToken storage currentItem = idToListedToken[i];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return tokens;
    }

    function getMyNFTs() public view returns (listedToken[] memory) {
        uint256 totalItemCount = nftContract.getTokenCounter();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender) {
                itemCount += 1;
            }
        }

        listedToken[] memory items = new listedToken[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender) {
                uint256 currentId = i;
                listedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function burnNFTCarbon(uint256 tokenId,uint256 amount) public{
        require(idToListedToken[tokenId].owner == msg.sender, "only owner can burn nft");
        require(idToListedToken[tokenId].amount > 0, "carbon is expire");
        nftContract.burnCarbonToken(tokenId, amount);
    }

    // function getTokens() public {
    //     uint256 amount = 10 * 10 ** 18; // Amount of tokens to mint
    //     require(customToken.transfer(msg.sender, amount), "Token transfer failed");
    // }
}
