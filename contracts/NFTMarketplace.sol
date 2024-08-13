// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721URIStorage {

    uint256 public tokenCounter;
    uint256 public itemsSold;
    address payable owner;
    uint256 listPrice = 0.01 ether;
    IERC20 public customToken;

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    event TokenListingCancelled(
        uint256 indexed tokenId,
        address indexed owner
    );

    mapping(uint256 => ListedToken) private idToListedToken;

    constructor(address customTokenAddress) ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
        tokenCounter = 0;
        itemsSold = 0;
        customToken = IERC20(customTokenAddress);
    }

    function updateListPrice(uint256 _listPrice) public {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        return idToListedToken[tokenCounter];
    }

    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return tokenCounter;
    }

    function createToken(string memory tokenURI, uint256 price) public returns (uint) {
        require(price > 0, "Price must be positive");
        require(customToken.transferFrom(msg.sender, owner, listPrice), "Insufficient listing fee");

        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        idToListedToken[newTokenId] = ListedToken(
            newTokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), newTokenId);

        emit TokenListedSuccess(
            newTokenId,
            address(this),
            msg.sender,
            price,
            true
        );

        tokenCounter += 1;

        return newTokenId;
    }

    function cancelList(uint256 tokenId) public {
        // Check if the token is listed and the caller is the owner
        require(idToListedToken[tokenId].currentlyListed, "Token is not listed");
        require(idToListedToken[tokenId].seller == msg.sender, "Only the seller can cancel the listing");

        // Transfer the token back to the owner
        _transfer(address(this), msg.sender, tokenId);

        // Mark the token as not listed
        idToListedToken[tokenId].currentlyListed = false;

        // Emit an event for the cancellation
        emit TokenListingCancelled(tokenId, msg.sender);
    }

    function executeSale(uint256 tokenId) public {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(customToken.transferFrom(msg.sender, seller, price), "Insufficient token balance");

        idToListedToken[tokenId].currentlyListed = false;
        idToListedToken[tokenId].seller = payable(msg.sender);
        itemsSold += 1;

        _transfer(address(this), msg.sender, tokenId);

        customToken.transfer(owner, listPrice);
    }
    function sellNFT(uint256 tokenId, uint256 price) public {

    require(!idToListedToken[tokenId].currentlyListed, "Token is already listed");

    idToListedToken[tokenId] = ListedToken({
        tokenId: tokenId,
        owner:payable(address(this)),
        seller: payable(msg.sender),
        price: price,
        currentlyListed: true
    });

      _transfer(msg.sender, address(this), tokenId);

        emit TokenListedSuccess(
           tokenId,
            address(this),
            msg.sender,
            price,
            true
        );
}


    function getAllNFTs() public view returns (ListedToken[] memory) {
        ListedToken[] memory tokens = new ListedToken[](tokenCounter);
        uint currentIndex = 0;

        for (uint i = 0; i < tokenCounter; i++) {
            ListedToken storage currentItem = idToListedToken[i];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return tokens;
    }

    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = tokenCounter;
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender) {
                itemCount += 1;
            }
        }

        ListedToken[] memory items = new ListedToken[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender) {
                uint currentId = i;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function getTokens() public {
        uint256 amount = 10 * 10 ** 18; // Amount of tokens to mint
        require(customToken.transfer(msg.sender, amount), "Token transfer failed");     
    }
}
