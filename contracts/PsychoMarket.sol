// SPDX-License-Identifier: GPL-3.0

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../../Game/Psychospheres.sol";
import "./AssetsMarket.sol";

contract PsychoMarket is AssetsMarket {
     using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    Psychospheres public psychospheres;

    function setPsychospheres(address _psychospheres) public isOwner {
        psychospheres = Psychospheres(_psychospheres);
    }

    struct MarketPsychoItem {
        uint256 itemId;
        uint256 psychoId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketPsychoItem) private idToMarketPsychoItem;

    event MarketPsychoItemCreated (
        uint256 indexed itemId,
        uint256 indexed psychoId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    /* Returns the listing price of the contract */
    // function getListingPrice() public view returns (uint256) {
    //     return listingPrice;
    // }
  
  /* Places an item for sale on the marketplace */
    function createMarketPsychoItem(
        uint256 psychoId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
  
        idToMarketPsychoItem[itemId] =  MarketPsychoItem(
            itemId,
            psychoId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        psychospheres.transferPsychosphereFrom(msg.sender, address(this), psychoId);

        emit MarketPsychoItemCreated(
            itemId, 
            psychoId, 
            msg.sender, 
            address(0), 
            price, 
            false
        );
  }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
    function createMarketPsychoSale(
        uint256 itemId
    ) public payable nonReentrant {
        uint256 price = idToMarketPsychoItem[itemId].price;
        uint256 psychoId = idToMarketPsychoItem[itemId].psychoId;
        require(DBT.balanceOf(msg.sender) >= price, "Please submit the asking price in order to complete the purchase");
        require(DBT.allowance(msg.sender, address(this)) >= price, "Contract cant do transfer from your account");
        DBT.transferFrom(msg.sender, idToMarketPsychoItem[itemId].seller, price);
        psychospheres.transferPsychosphere(msg.sender, psychoId);
        idToMarketPsychoItem[itemId].owner = payable(msg.sender);
        idToMarketPsychoItem[itemId].sold = true;
        _itemsSold.increment();
    }

  /* Returns all unsold market items */
    function fetchMarketPsychoItems() public view returns (MarketPsychoItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketPsychoItem[] memory items = new MarketPsychoItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketPsychoItem[i + 1].owner == address(0)) {
                uint currentId =  i + 1;
                MarketPsychoItem storage currentItem = idToMarketPsychoItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

  /* Returns only items that a user has purchased */
    function fetchMyPsychos() public view returns (MarketPsychoItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketPsychoItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketPsychoItem[] memory items = new MarketPsychoItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketPsychoItem[i + 1].owner == msg.sender) {
                uint currentId =  i + 1;
                MarketPsychoItem storage currentItem = idToMarketPsychoItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

  /* Returns only items a user has created */
    function fetchItemsCreated() public view returns (MarketPsychoItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketPsychoItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketPsychoItem[] memory items = new MarketPsychoItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketPsychoItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketPsychoItem storage currentItem = idToMarketPsychoItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}