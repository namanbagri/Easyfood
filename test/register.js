const exchange = artifacts.require("exchange");
const token = artifacts.require("token");
const registration = artifacts.require("registration");
const order_platform = artifacts.require("order_platform");

contract('registration', (accounts) => {
    let owner = accounts[0];
    let tokenInstance = null;
    let exchangeInstance = null;
    let registerInstance = null; 
    let orderInstance = null; 
    before(async() =>{
        tokenInstance = await token.deployed();
        exchangeInstance = await exchange.deployed(tokenInstance.address);
        await tokenInstance.setaddress(exchangeInstance.address);
        registerInstance = await registration.deployed(tokenInstance.address);
        orderInstance = await order_platform.deployed(tokenInstance.address,registerInstance.address);
        await registerInstance.setaddress(orderInstance.address);
    });
    const user = accounts[1];
    const restaurant = accounts[2];
    const agent = accounts[3];
    it('should register user', async () => {
        await registerInstance.register_user({
            from: user
        });
        const status= await registerInstance.user_check.call(user);
        assert.equal(status,true, "user not registered");
    });
    it("User cannot register again", async () => {
        try{
            await registerInstance.register_user({
                from: user
            })
            assert.fail("Revert: registration shouldnt be possible- exception was expected")  
        }catch(err){
          assert.include(err.message, "revert", "The error message should contain 'revert'");
        }
    });

    it('should register restaurant', async () => {
        await registerInstance.register_restaurant({
            from: restaurant
        });
        const status= await registerInstance.rest_check.call(restaurant);
        assert.equal(status,true, "restaurant not registered");
    });

    it("restaurant cannot register again", async () => {
        try{
            await registerInstance.register_restaurant({
                from: restaurant
            })
            assert.fail("Revert: registration shouldnt be possible- exception was expected")  
        }catch(err){
          assert.include(err.message, "revert", "The error message should contain 'revert'");
        }
    });

    it('should register agent', async () => {
        await registerInstance.register_agent({
            from: agent
        });
        const status= await registerInstance.agent_check.call(agent);
        assert.equal(status,true, "agent not registered");
    });
    it("agent cannot register again", async () => {
        try{
            await registerInstance.register_agent({
                from: agent
            })
            assert.fail("Revert: registration shouldnt be possible- exception was expected")  
        }catch(err){
          assert.include(err.message, "revert", "The error message should contain 'revert'");
        }
    });

    it('should be able to add item', async () => {
        await exchangeInstance.getTokens(100, {
            from: restaurant,
            value: '1000000000000000000'
        });
        await tokenInstance.approve(registerInstance.address,50,{
            from: restaurant
        });
        await registerInstance.additem(1,10,50,{
            from: restaurant
        });
        const price= await registerInstance.item_cost(1,1);
        const status = await registerInstance.item_exist(1,1);
        assert.equal(status,true,"item not added");
        assert.equal(price,10,"item not added");

    });

    it('should be able to increase stake', async () => {
        await exchangeInstance.getTokens(100, {
            from: agent,
            value: '1000000000000000000'
        });
        await tokenInstance.approve(registerInstance.address,10,{
            from: agent
        });
        const amount = await tokenInstance.allowance(agent, registerInstance.address);
        assert.equal(amount,10,"stake not increased");
        
    });
});

contract('order_platform', (accounts) => {
    let owner = accounts[0];
    const user = accounts[1];
    const restaurant = accounts[2];
    const agent = accounts[3];
    let tokenInstance = null;
    let exchangeInstance = null;
    let registerInstance = null; 
    let orderInstance = null; 
    before(async() =>{
        tokenInstance = await token.deployed();
        exchangeInstance = await exchange.deployed(tokenInstance.address);
        await tokenInstance.setaddress(exchangeInstance.address);
        registerInstance = await registration.deployed(tokenInstance.address);
        orderInstance = await order_platform.deployed(tokenInstance.address,registerInstance.address);
        await registerInstance.setaddress(orderInstance.address);
        //register user
        await registerInstance.register_user({
            from: user
        });
        //register restaurant
        await registerInstance.register_restaurant({
            from: restaurant
        });
        //register agent
        await registerInstance.register_agent({
            from: agent
        });
        //restaurant adding item
        await exchangeInstance.getTokens(100, {
            from: restaurant,
            value: '1000000000000000000'
        });

        await tokenInstance.approve(registerInstance.address,50,{
            from: restaurant
        });

        await registerInstance.additem(1,10,50,{
            from: restaurant
        });
        //agent increasing stake
        await exchangeInstance.getTokens(100, {
            from: agent,
            value: '1000000000000000000'
        });
        await tokenInstance.approve(registerInstance.address,10,{
            from: agent
        });
    });
    
    

    it('should be able to place order by user', async () => {
        await exchangeInstance.getTokens(100, {
            from: user,
            value: '1000000000000000000'
        });
        await tokenInstance.approve(orderInstance.address,10,{
            from: user
        });
        await orderInstance.place_order([1],1,10,{
            from: user
        });
        const status = (await orderInstance.status(1)).toNumber();
        assert.equal(status,1,"order not placed");

    });

    it('should be able to accept order by restaurant', async () => {
        await orderInstance.accept_order(1,{
            from : restaurant
        });
        const status = (await orderInstance.status(1)).toNumber();
        assert.equal(status,2,"order not accepted");

    });

    it('should be able to accept order delivery by agent', async () => {
        await orderInstance.accept_delivery(1,{
            from: agent
        });
        const status = (await orderInstance.status(1)).toNumber();
        assert.equal(status,3,"order not accepted");

    });

    it("Restaurant cannot get tokens after accepting", async () => {
        try{
          await orderInstance.restaurant_token_collect(1,{
              from: restaurant
          })
          assert.fail("Revert: Restaurant cannot request tokens- exception was expected")  
        }catch(err){
          assert.include(err.message, "revert", "The error message should contain 'revert'");
        }
    
    });
    it('should not be able to accept order delivery by agent', async () => {
        try{
            await orderInstance.accept_delivery(1,{
                from: agent
            })
            assert.fail("Revert: Agent cannot accept another delivery- exception was expected")  
          }catch(err){
            assert.include(err.message, "revert", "The error message should contain 'revert'");
          }
    });

    it('should be able to prepare order', async () => {
        await orderInstance.prepare_food(1,{
            from: restaurant
        });
        const status = (await orderInstance.status(1)).toNumber();
        assert.equal(status,4,"should be able to request order");

    });

    it("Restaurant cannot get tokens after preparing", async () => {
        try{
          await orderInstance.restaurant_token_collect(1,{
              from: restaurant
          })
          assert.fail("Revert: Restaurant cannot request tokens- exception was expected")  
        }catch(err){
          assert.include(err.message, "revert", "The error message should contain 'revert'");
        }
    
    });

    it('should be able to collect order delivery by agent', async () => {
        await orderInstance.agent_collect(1,{
            from: agent
        });
        const status = (await orderInstance.status(1)).toNumber();
        assert.equal(status,5,"should be able to collect order");
    });

    it('should be able to collect tokens by restaurant', async () => {
        const Balance1 = (await tokenInstance.balanceOf.call(restaurant)).toNumber();
        await orderInstance.restaurant_token_collect(1,{
            from: restaurant
        });
        const Balance2 = (await tokenInstance.balanceOf.call(restaurant)).toNumber();
        assert.equal(Balance2-Balance1,9, "unable to collect tokens ");

    });

    it("Agent cannot get tokens before delivery", async () => {
        try{
          await orderInstance.agent_token_collect(1,{
              from: agent
          })
          assert.fail("Revert: Restaurant cannot request tokens- exception was expected")  
        }catch(err){
          assert.include(err.message, "revert", "The error message should contain 'revert'");
        }
    
    });

    it('should be able to confirm delivery by user', async () => {
        await orderInstance.user_delivery_confirm(1,{
            from: user
        });
        const status = (await orderInstance.status(1)).toNumber();
        assert.equal(status,6,"should be able to confirm order");
    });

    it('should be able to collect tokens by agent', async () => {
        const Balance1 = (await tokenInstance.balanceOf.call(agent)).toNumber();
        await orderInstance.agent_token_collect(1,{
            from: agent
        });
        const Balance2 = (await tokenInstance.balanceOf.call(agent)).toNumber();
        assert.equal(Balance2-Balance1,1, "unable to collect tokens ");
    });
    it('should be delist agent if rating less than 2', async () => {
        await orderInstance.rate_agent(1,{
            from: user
        });
        const status = await registerInstance.agent_check.call(agent);
        assert.equal(status,false, "agent should be delisted");
    });
    

});

contract('order_platform', (accounts) => {
    let owner = accounts[0];
    const user = accounts[1];
    const restaurant = accounts[2];
    const agent = accounts[3];
    let tokenInstance = null;
    let exchangeInstance = null;
    let registerInstance = null; 
    let orderInstance = null; 
    before(async() =>{
        tokenInstance = await token.deployed();
        exchangeInstance = await exchange.deployed(tokenInstance.address);
        await tokenInstance.setaddress(exchangeInstance.address);
        registerInstance = await registration.deployed(tokenInstance.address);
        orderInstance = await order_platform.deployed(tokenInstance.address,registerInstance.address);
        await registerInstance.setaddress(orderInstance.address);
        //register user
        await registerInstance.register_user({
            from: user
        });
        //register restaurant
        await registerInstance.register_restaurant({
            from: restaurant
        });
        //register agent
        await registerInstance.register_agent({
            from: agent
        });
        //restaurant adding item
        await exchangeInstance.getTokens(100, {
            from: restaurant,
            value: '1000000000000000000'
        });

        await tokenInstance.approve(registerInstance.address,50,{
            from: restaurant
        });

        await registerInstance.additem(1,10,50,{
            from: restaurant
        });
        //agent increasing stake
        await exchangeInstance.getTokens(100, {
            from: agent,
            value: '1000000000000000000'
        });
        await tokenInstance.approve(registerInstance.address,10,{
            from: agent
        });

        //place order
        await exchangeInstance.getTokens(100, {
            from: user,
            value: '1000000000000000000'
        });
        await tokenInstance.approve(orderInstance.address,10,{
            from: user
        });
        await orderInstance.place_order([1],1,10,{
            from: user
        });
        await orderInstance.accept_order(1,{
            from : restaurant
        });
    });

    it('should be able to collect tokens by agent', async () => {
        const Balance1 = (await tokenInstance.balanceOf.call(user)).toNumber();
        await orderInstance.refund_user({from:user});
        const Balance2 = (await tokenInstance.balanceOf.call(user)).toNumber();
        assert.equal(Balance2-Balance1,10, "unable to collect tokens ");
    });
    
});

