pragma solidity ^0.6.12;

import 'openZeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract token is ERC20 {
    address manager;
    address _contract;
    constructor () public ERC20("EasyFood", "EAF") {
        manager=msg.sender;
        
    }
    modifier OnlyManager(){
        require(msg.sender==manager,"Only manager can call");
        _;
    }
    function setaddress(address _exchange) OnlyManager public {
        _contract=_exchange;
    }
    modifier onlyExchange(){
        require(msg.sender==_contract,"only exchange can call");
        _;
    }
    function mint(uint _tokens) onlyExchange public{
        _mint(msg.sender,_tokens);
    }
}

contract exchange {
    token foodtoken;
    address tokenaddress;
    constructor(address _tokenaddress) public payable {
        tokenaddress=_tokenaddress;
        foodtoken= token(tokenaddress);
        
    }
    
    event getToken(address _to,uint amount);
    //ether to tokens
    function getTokens(uint _amt)  public payable{
        uint tokens=msg.value / 10**16;// convert to ether and then tokens
        require(_amt<=tokens,"insufficient amount to buy tokens");
        uint extra=msg.value-(_amt*10**16);
        foodtoken.mint(_amt);
        foodtoken.transfer(msg.sender,_amt);//contract should have tokens
        msg.sender.transfer(extra);
        emit getToken(msg.sender,tokens);
    }
}