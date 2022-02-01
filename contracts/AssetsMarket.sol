// SPDX-License-Identifier: GPL-3.0

pragma experimental ABIEncoderV2;
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../Game/Assets.sol";
import "../../Utils/Owner.sol";
import "../../Digibytes/Digibytes.sol";

contract AssetsMarket is ReentrancyGuard, Owner {
     using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    // address payable owner;
    Assets public assetsContract;
    Digibytes public DBT;

    function setAssets(address _assetsAddress) public isOwner {
        assetsContract = Assets(_assetsAddress);
    }

    function setDBT(address _DBTAddress) public isOwner {
        DBT = Digibytes(_DBTAddress);
    }

    struct MarketAssetItem {
        uint256 itemId;
        uint32 assetId;
        address seller;
        address owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketAssetItem) private idToMarketAssetItem;

    event MarketAssetItemCreated (
        uint indexed itemId,
        uint32 indexed assetId,
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
    function createMarketAssetItem(
        uint32 assetId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
  
        idToMarketAssetItem[itemId] =  MarketAssetItem(
            itemId,
            assetId,
            address(msg.sender),
            address(0),
            price,
            false
        );

        assetsContract.transferAssetFrom(msg.sender, address(this), assetId);

        emit MarketAssetItemCreated(
            itemId, 
            assetId, 
            msg.sender, 
            address(0), 
            price, 
            false
        );
  }

  //CLOSE MARKET ITEM

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
    function createMarketAssetSale(
        uint256 itemId
    ) 
        public nonReentrant 
    {
        uint256 price = idToMarketAssetItem[itemId].price;
        uint32 assetId = idToMarketAssetItem[itemId].assetId;
        require(DBT.balanceOf(msg.sender) >= price, "Please submit the asking price in order to complete the purchase");
        require(DBT.allowance(msg.sender, address(this)) >= price, "Contract cant do transfer from your account");
        DBT.transferFrom(address(msg.sender), address(idToMarketAssetItem[itemId].seller), price);
        assetsContract.transferAsset(msg.sender, assetId);
        idToMarketAssetItem[itemId].owner = payable(msg.sender);
        idToMarketAssetItem[itemId].sold = true;
        _itemsSold.increment();
    }

  /* Returns all unsold market items */
    function fetchMarketAssetsItems() public view returns (MarketAssetItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketAssetItem[] memory items = new MarketAssetItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketAssetItem[i + 1].owner == address(0)) {
                uint currentId =  i + 1;
                MarketAssetItem storage currentItem = idToMarketAssetItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

  /* Returns only items that a user has purchased */
    function fetchMyMarketAssets() public view returns (MarketAssetItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketAssetItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketAssetItem[] memory items = new MarketAssetItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketAssetItem[i + 1].owner == msg.sender) {
                uint currentId =  i + 1;
                MarketAssetItem storage currentItem = idToMarketAssetItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

  /* Returns only items a user has created */
    function fetchAssetItemsCreated() public view returns (MarketAssetItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketAssetItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketAssetItem[] memory items = new MarketAssetItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketAssetItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketAssetItem storage currentItem = idToMarketAssetItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}