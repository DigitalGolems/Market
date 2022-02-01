const Psychospheres = artifacts.require("Psychospheres");
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


contract('Game Psycho Market', async (accounts)=>{
    let psycho;
    let DBT;
    let market;
    let userSeller = accounts[9];
    let userBuyer = accounts[8];
    let owner = accounts[0];
    let layer = 10;
    let part = 0;
    before(async () => {
        psycho = await Psychospheres.new()
        DBT = await DBTContract.new()
        market = await MarketContract.new()
        await market.setPsychospheres(psycho.address)
        await market.setDBT(DBT.address)
        //user find psycho
        await psycho.addPsychosphereByOwner(
            userSeller,
            "1",
            "0",
            {from: owner}
        )
        await DBT.transfer(userBuyer, web3.utils.toWei("1"), {from: owner})
    })

    it("Should create market item", async () => {
        //approve psycho to market contract
        await psycho.approvePsychosphere(market.address, "0", {from: userSeller})
        //creating market item of this psycho
        await market.createMarketPsychoItem(0, web3.utils.toWei("1"), {from: userSeller})
        //checks of really added
        assert.equal((await market.fetchMarketPsychoItems()).length, 1, "Really added")
    })

    it("Should buy market item", async () => {
        //approve using DBT of buyer by market contract 
        await DBT.approve(market.address, web3.utils.toWei("1"), {from: userBuyer})
        //buying psycho
        await market.createMarketPsychoSale(1, {from: userBuyer})
        //checks if psycho added to buyer
        assert.equal(
            (await psycho.getPsychospheresOwner(0)).toString(),
            userBuyer.toString(),
            "Really added to user 1"
        )
        assert.equal(
            (await psycho.getPsychospheresCount(userBuyer)).toString(),
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