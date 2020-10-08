var Token = artifacts.require("token");
var Exchange = artifacts.require("exchange");
var Register = artifacts.require("registration");
var Order = artifacts.require("order_platform");
module.exports = function(deployer) {

    deployer.then(async () => {
        await deployer.deploy(Token);
        await deployer.deploy(Exchange, Token.address);
        await deployer.deploy(Register, Token.address);
        await deployer.deploy(Order, Token.address,Register.address);
        //...
    });
};