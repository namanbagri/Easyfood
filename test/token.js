const exchange = artifacts.require("exchange");
const token = artifacts.require("token");

contract('exchange', (accounts) => {
    let owner = accounts[0];
    const accountone =accounts[1];
    let tokenInstance = null;
    let exchangeInstance = null;
    before(async() =>{
        tokenInstance = await token.deployed();
        exchangeInstance = await exchange.deployed(tokenInstance.address);
        await tokenInstance.setaddress(exchangeInstance.address);
        
    });
    it('should get tokens', async () => {
        await exchangeInstance.getTokens(100, {
            from: accountone,
            value: '1000000000000000000'
        });
        const Balance = (await tokenInstance.balanceOf.call(accounts[1])).toNumber();
        assert.equal(Balance,100, "tokens not given");
    });
    it("should not get tokens", async () => {
        try{
            await exchangeInstance.getTokens(200, {
                from: accountone,
                value: '1000000000000000000'
            })
            assert.fail("Revert: shouldnt get tokens- exception was expected")  
        }catch(err){
          assert.include(err.message, "revert", "The error message should contain 'revert'");
        }
    
    });

});
