const AssetsContract = artifacts.require("Assets");
const MarketContract = artifacts.require("InGameMarket")
const DBTContract = artifacts.require("Digibytes")
const { assert } = require("chai");
const {
    catchRevert,            
    catchOutOfGas,          
    catchInvalidJump,       
    catchInvalidOpcode,     
    catchStackOverflow,     
    catchStackUnderflow,   
    catchStaticStateChange
} = require("../../../utils/catch_error.js")


contract('Game Assets Market', async (accounts)=>{
    let assets;
    let DBT;
    let market;
    let userSeller = accounts[9];
    let userBuyer = accounts[8];
    let owner = accounts[0];
    let layer = 10;
    let part = 0;
    before(async () => {
        assets = await AssetsContract.new()
        DBT = await DBTContract.new()
        market = await MarketContract.new()
        await market.setAssets(assets.address)
        await market.setDBT(DBT.address)
        //create asset
        await assets.addAssetByOwner(
            (layer).toString(),
            (part).toString(),
            `https://someURL/0`,
            "0",
            {from: owner}
        )
        //adding user to asset
        await assets.addUserToAssetOwner("0", userSeller, {from: owner})
        await DBT.transfer(userBuyer, web3.utils.toWei("1"), {from: owner})
    })

    it("Should create market item", async () => {
        //approve asset to market contract
        await assets.approveAsset(market.address, "0", {from: userSeller})
        //creating market item of this asset
        await market.createMarketAssetItem(0, web3.utils.toWei("1"), {from: userSeller})
        //checks of really added
        assert.equal((await market.fetchMarketAssetsItems()).length, 1, "Really added")
    })

    it("Should buy market item", async () => {
        //approve using DBT of buyer by market contract 
        await DBT.approve(market.address, web3.utils.toWei("1"), {from: userBuyer})
        //buying asset
        await market.createMarketAssetSale(1, {from: userBuyer})
        //checks if asset added to buyer
        assert.equal(
            (await assets.assetToOwner(userBuyer, 0)).toString(),
            "1",
            "Really added to user 1"
        )
        assert.equal(
            (await assets.getOwnerAssetCount(userBuyer)).toString(),
            "1",
            "Really added to user 2"
        )
        //checking balance of seller
        //should be +1 DBT
        assert.equal(
            (await DBT.balanceOf(userSeller)).toString(),
            web3.utils.toWei("1"),
            "Balance"
        )
    })
}
)