pragma solidity ^0.6.12;

import './token.sol';

contract registration{
    token foodtoken;
    address order_contract;
    address manager;
    constructor(address _tokenaddress) public {
        foodtoken= token(_tokenaddress);
        manager=msg.sender;
    }
    
    uint agent_count = 0;
    uint public restaurant_count = 0;
    uint user_count = 0;
    uint order_count = 0;
    
    struct user{
        uint id;
        uint cur_order;
        uint last_order;
        uint tokens;
    }
    
    struct restaurant {
        uint id;
        uint stake;
        mapping(uint => uint) item_price;
        uint item_count;
        uint avg_rating;
        uint order_count;
        address r;
    }
    
    struct agent {
        uint id;
        uint cur_order;
        uint stake;
        uint avg_rating;
        uint order_count;
        address a;
    }
    
    mapping(uint => user) user_details;
    mapping(uint => restaurant) restaurant_details;
    mapping(uint => agent) agent_details;
    
    mapping(address => uint) get_user_id;
    mapping(address => uint) get_restaurant_id;
    mapping(address => uint ) get_agent_id;
    
    
    modifier onlyManager(){
        require(msg.sender==manager,"Can only be called by Manager");
        _;
    }
    
    modifier onlyOrder(){
        require(msg.sender==order_contract,"Can only be called by order contract");
        _;
    }
    
    modifier user_exist() {
        require(get_user_id[msg.sender] > 0, "You are not registered");
        _;
    }
    
    modifier agent_exist() {
        require(get_agent_id[msg.sender] > 0, "You are not registered");
        _;
    }
    
    modifier restaurant_exist() {
        require(get_restaurant_id[msg.sender] > 0, "You are not registered");
        _;
    }
    
    modifier has_ordered() {
        require(user_details[get_user_id[msg.sender]].cur_order != 0, "You do not have any active orders");
        _;
    }
    
    function setaddress(address _contract) onlyManager public {
        order_contract=_contract;
    }
    //registering user
    function register_user() public returns(bool) {
        require(get_user_id[msg.sender] == 0, "User already registered");
        user_count++;
        user storage u = user_details[user_count];
        u.id = user_count;
        u.cur_order = 0;
        user_details[u.id] = u;
        get_user_id[msg.sender] = u.id;
        return true;
    }
    
    //registering Restaurant
    function register_restaurant() public returns(bool) {
        require(get_restaurant_id[msg.sender] == 0, "Restaurant already registered");
        restaurant_count++;
        restaurant storage r = restaurant_details[restaurant_count];
        r.id = restaurant_count;
        r.stake=0;
        r.avg_rating=0;
        r.order_count=0;
        r.item_count=0;
        r.r=msg.sender;
        restaurant_details[r.id] = r;
        get_restaurant_id[msg.sender] = r.id;
        return true;
    }
    
    //adding item to restaurant menu,increasing stake,tokens involved.
    function additem (uint item_no,uint price,uint stake_token) restaurant_exist public returns (bool){
        require(stake_token>=5*price,"stake should be minimum five times the price");
        require(foodtoken.balanceOf(msg.sender)>=stake_token,"not enough balance");//require statement to check if the person as stake_token amount of EasyFood tokens 
        uint id = get_restaurant_id[msg.sender];
        restaurant storage r=restaurant_details[id];
        r.stake+= 5*(price);
        foodtoken.transferFrom(msg.sender,address(this),stake_token);// taking stake
        r.item_price[item_no]=price;
        r.item_count++;
        return true;
    }
    function get_item_count(uint rest_id) public view returns (uint){
        return restaurant_details[rest_id].item_count;
    }
    
    //checking if an item exists or not
    function item_exist(uint items,uint res_id) public view returns(bool){
         if (items<=restaurant_details[res_id].item_count) 
            return true;
        else
            return false;
    }
    
    //registering agent
    function register_agent() public returns(bool) {
        require(get_agent_id[msg.sender] == 0, "Agent already registered");
        agent_count++;
        agent storage c = agent_details[agent_count];
        c.id = agent_count;
        c.stake=0;
        c.a=msg.sender;
        agent_details[c.id] = c;
        get_agent_id[msg.sender] = c.id;
        return true;
    }
    
    //increasing stake of agent ,tokens involved
    function increase_stake(uint stake_amt) agent_exist public returns (bool){
        require(foodtoken.balanceOf(msg.sender)>=stake_amt,"not enough balance");//require statement to check if it has sufficient amt of EasyFood tokens
        foodtoken.transferFrom(msg.sender,address(this),stake_amt);
        uint id=get_agent_id[msg.sender];
        agent storage a =agent_details[id];
        a.stake+=stake_amt;
        return true;
    } 
    
    //To check user exists,for order platform
    function user_check (address _user) public view returns (bool){
        if (get_user_id[_user] > 0)
            return true;
        else
            return false;
    }
    
    //To check agent exists,for order platform
    function agent_check (address _agent) public view returns (bool){
        if (get_agent_id[_agent] > 0)
            return true;
        else
            return false;
    }
    
    //To check restaurant exists,for order platform
    function rest_check (address _rest) public view returns (bool){
        if (get_restaurant_id[_rest] > 0)
            return true;
        else
            return false;
    }
    
    //to return rest id,for order platform
    function return_rest_id(address _rest) public view returns (uint){
        return get_restaurant_id[_rest];
    }
    
    //return user id,for order platform
    function return_user_id(address _user) public view returns (uint){
        return get_user_id[_user];
    }
    
    //to return agent id,for order platform
    function return_agent_id(address _agent) public view returns (uint){
        return get_agent_id[_agent];
    }
    
    //check user order,for order platform
    function check_user_order(address _user) public view returns (bool){
        if (user_details[get_user_id[_user]].cur_order == 0){
            return true;
        }
        else {
            return false;
        }
    }
    
    //to check agent current order,for order platform
    function check_agent_order(address _agent) public view returns (bool){
        if (agent_details[get_agent_id[_agent]].cur_order == 0){
            return true;
        }
        else {
            return false;
        }
    }
    
    //return user current order,for order platform
    function return_user_order(address _user) public view returns(uint){
        return user_details[get_user_id[_user]].cur_order;
    }
    
    //return agent current order,for order platform
    function return_agent_order(address _agent) public view returns(uint){
        return agent_details[get_agent_id[_agent]].cur_order;
    }
    
    //update user current order for placing order and after delivery,for order platform
    function update_user_order(address _user,uint order_id) onlyOrder public {
        user_details[get_user_id[_user]].cur_order =order_id;
    }
    
    //updated agent cuurent order after accepting delivery,for order platform
    function update_agent_order(address _agent,uint order_id) onlyOrder public {
        agent_details[get_agent_id[_agent]].cur_order = order_id;
    }
    
    //update agent order count ,for order platform
    function update_agent_count(address _agent) onlyOrder public {
         agent_details[get_agent_id[_agent]].order_count=agent_details[get_agent_id[_agent]].order_count+1;
    }
    
    //update restaurant order count ,for order platform
    function update_rest_count(address _rest) onlyOrder public {
          restaurant_details[get_restaurant_id[_rest]].order_count=restaurant_details[get_restaurant_id[_rest]].order_count+1;
    }
    
    //delete restaurant from mapping
    function delete_rest(uint restid) onlyOrder public returns (bool){
        delete get_restaurant_id[restaurant_details[restid].r];
        delete restaurant_details[restid];
        return true;
    }
    
    //delete agent from mapping
    function delete_agent (uint agentid) onlyOrder public returns (bool){
        delete get_agent_id[agent_details[agentid].a];
        delete agent_details[agentid];
        return true;
    }
    
    //returns cost of an item
    function item_cost(uint restid,uint _item) public view returns(uint){
        return restaurant_details[restid].item_price[_item];
    }
    
    //request allowance from order contract to registration contract so that user can be refunded in case of agent or rest fault
    function request_allowance(address _contract,uint _tokens) onlyOrder public {
        foodtoken.increaseAllowance(_contract,_tokens);
    }
    
    //checking the last order for user
    function check_last_order(address _user) public view returns (bool){
        if (user_details[get_user_id[_user]].last_order != 0){
            return true;
        }
        else{
            return false;
        }
    }
    
    //return user last order
    function return_last_order(address _user) public view returns (uint){
        return user_details[get_user_id[_user]].last_order;
    }
    
    //update last order for user
    function update_last_order(address _user,uint order_id) onlyOrder public {
        user_details[get_user_id[_user]].last_order=order_id;
    }
    
    //change rest rating after delivery
    function rest_rating(uint restid,uint rating) onlyOrder public {
        restaurant_details[restid].avg_rating=(restaurant_details[restid].avg_rating* restaurant_details[restid].order_count+rating)/(restaurant_details[restid].order_count+1);
    }
    
    //change agent rating after delivery
    function agent_rating(uint agentid,uint rating) onlyOrder public {
        agent_details[agentid].avg_rating=(agent_details[agentid].avg_rating* agent_details[agentid].order_count+rating)/(agent_details[agentid].order_count+1);
        if(agent_details[agentid].avg_rating<=2)
        {
            delete get_agent_id[agent_details[agentid].a];
            delete agent_details[agentid];
        
        }
    }
    
    
    
    
    
}










contract order_platform {
    
    address regaddress;
    token foodtoken;
    
    registration reg;
    
    constructor (address _tokenaddress,address _registeraddress) public {
        foodtoken= token(_tokenaddress);
        regaddress=_registeraddress;
        reg= registration(_registeraddress);
    }
    
    uint order_count = 0;
    
    enum OrderStatus {ordered, accepted, agent_found, prepared, picked, delivered,refunded}
    
    struct Order {
        uint id;
        uint[] items;
        uint price;
        uint rest;
        uint agent;
        uint user;
        uint time;
        OrderStatus status;
        uint agent_rating;
        uint rest_rating;
    }
    
    mapping(uint => Order) order_details;
    
    event order_update(uint order_id, OrderStatus status);
    
    modifier user_exist() {
        require(reg.user_check(msg.sender)==true, "You are not registered");
        _;
    }
    
    modifier agent_exist() {
        require(reg.agent_check(msg.sender)==true, "You are not registered");
        _;
    }
    
    modifier restaurant_exist() {
        require(reg.rest_check(msg.sender)==true, "You are not registered");
        _;
    }
    
    modifier has_ordered() {
        require(reg.check_user_order(msg.sender)==false, "You do not have any active orders");
        _;
    }
    
    //user places order and it checks the amount of token and restaurants items exists or not,tokens involved
    function place_order(uint[] memory items, uint restaurant_id,uint tokens) user_exist  public returns(bool) {
        require(restaurant_id <= reg.restaurant_count(), "Restaurant doesn't exist");
        require(reg.check_user_order(msg.sender)==true, "Already placed order");
        require(foodtoken.balanceOf(msg.sender)>=tokens,"not enough balance");//check amt of tokens
        uint i;
        uint price=0;
        for (i = 0; i < items.length; i++) {
            require(reg.item_exist(items[i], restaurant_id) == true, "Item doesn't exist");
            price+=reg.item_cost(restaurant_id,items[i]);
        }
        require(tokens==price,"not enough tokens");//require statement to check if token are enough or not
        foodtoken.transferFrom(msg.sender,address(this),tokens);
        order_count++;
        Order storage o = order_details[order_count];
        o.id = order_count;
        o.items = items;
        o.price = price;
        o.status = OrderStatus.ordered;
        o.rest = restaurant_id;
        o.user = reg.return_user_id(msg.sender);
        reg.update_user_order(msg.sender,o.id);
        emit order_update(o.id, o.status);
        return true;
    }
    
    //Restaurant accepts order
    function accept_order(uint order_id) restaurant_exist public returns (bool) {
        uint restaurant_id = reg.return_rest_id(msg.sender);
        require(order_details[order_id].rest == restaurant_id, "Not your order");
        require(order_details[order_id].status == OrderStatus.ordered, "Already accepted this order");
        emit order_update(order_id, OrderStatus.accepted);
        order_details[order_id].status = OrderStatus.accepted;
        reg.update_rest_count(msg.sender);
        return true;
    }
    
    //agent accepts the delivery request
    function accept_delivery(uint order_id) agent_exist public returns (bool) {
        uint agent_id = reg.return_agent_id(msg.sender);
        require(reg.check_agent_order(msg.sender)==true, "Already delivering another order");
        require(order_details[order_id].status == OrderStatus.accepted, "Already claimed");
        emit order_update(order_id, OrderStatus.agent_found);
        order_details[order_id].status = OrderStatus.agent_found;
        order_details[order_id].agent = agent_id;
        reg.update_agent_order(msg.sender,order_id);
        reg.update_agent_count(msg.sender);
        order_details[order_id].time=now;
        return true;
    }
    
    //restaurant starts preparing
    function prepare_food(uint order_id) restaurant_exist public returns (bool) {
        uint restaurant_id = reg.return_rest_id(msg.sender);
        require(order_details[order_id].rest == restaurant_id, "Not your order");
        require(order_details[order_id].status == OrderStatus.agent_found, "Agent not found");
        emit order_update(order_id, OrderStatus.prepared);
        order_details[order_id].status = OrderStatus.prepared;
        order_details[order_id].time=now;
        return true;
    }
    
    // agent collects the food from the restaurant
    function agent_collect (uint order_id) agent_exist public returns (bool) {
        require(reg.return_agent_order(msg.sender) == order_id, "Not your order");
        require(order_details[order_id].status == OrderStatus.prepared, "Food not yet made");
        emit order_update(order_id, OrderStatus.picked);
        order_details[order_id].status = OrderStatus.picked;
        return true;
    }
    
     //user confirms accepting the delivery
    function  user_delivery_confirm  (uint order_id) user_exist public returns (bool) {
        require(reg.return_user_order(msg.sender) == order_id, "Not your order");
        require(order_details[order_id].status == OrderStatus.picked, "Food not yet picked");
        emit order_update(order_id, OrderStatus.delivered);
        order_details[order_id].status = OrderStatus.delivered;
        reg.update_user_order(msg.sender,0);
        reg.update_last_order(msg.sender,order_id);
        
        return true;    
    }
      
    //status of order by user
    function get_status() user_exist has_ordered public view returns (OrderStatus) {
        uint order_id = reg.return_user_order(msg.sender);
        return order_details[order_id].status;
    }

    //refund until not prepared
    function refund_user() user_exist has_ordered public returns (bool) {
        uint order_id = reg.return_user_order(msg.sender);
        if (order_details[order_id].status== OrderStatus.ordered|| order_details[order_id].status==OrderStatus.accepted){
            foodtoken.transfer(msg.sender,order_details[order_id].price);
            reg.update_user_order(msg.sender,0);
            order_details[order_id].status = OrderStatus.refunded;//add deletion for order from mapping or change in enum
            return true;
        }
        else 
            return false;
    }
    
    //refund user if restaurant takes more than an hour
    function restaurant_fault() user_exist has_ordered public returns (bool){
        uint order_id = reg.return_user_order(msg.sender);
        require(order_details[order_id].status == OrderStatus.agent_found, "agent not found");
        uint _time=now;
        uint restid=order_details[order_id].rest;
        if (_time-order_details[order_id].time> 1 hours){
            
            reg.request_allowance(address(this),order_details[order_id].price);//add request to registration contract 
            foodtoken.transferFrom(regaddress,msg.sender,order_details[order_id].price);//transfer to user
            order_details[order_id].status = OrderStatus.refunded;//order status changed
            reg.update_user_order(msg.sender,0);
            return reg.delete_rest(restid);
        }
        return false;
    }
    
    //refund user if agent takes more than an hour
    function agent_fault() user_exist has_ordered public returns (bool){
        uint order_id = reg.return_user_order(msg.sender);
        require(order_details[order_id].status == OrderStatus.picked|| order_details[order_id].status == OrderStatus.prepared , "food not prepared");
        uint _time=now;
        uint agentid=order_details[order_id].agent;
        if (_time-order_details[order_id].time> 1 hours){
            
            
            reg.request_allowance(address(this),order_details[order_id].price);//request to registration contract 
            order_details[order_id].status = OrderStatus.refunded;//order status changed//order status changed
            foodtoken.transferFrom(regaddress,msg.sender,order_details[order_id].price);//transfer to user
            reg.update_user_order(msg.sender,0);
            return reg.delete_agent(agentid);
        }
        return false;
    }
    
    //agent can collect tokens after delivery ,tokens involved
    function agent_token_collect (uint order_id) agent_exist public returns (bool) {
        require(reg.return_agent_order(msg.sender) == order_id, "Not your order");
        require(order_details[order_id].status == OrderStatus.delivered, "Food not yet delivered");
        Order storage o = order_details[order_id];
        uint amount = (o.price)/10; 
        foodtoken.transfer(msg.sender,amount);//send tokens to agent 
        reg.update_agent_order(msg.sender,0);
        return true;    
    }
    
    //restaurant can collect tokens after delivered to agent,tokens involved
    function  restaurant_token_collect  (uint order_id) restaurant_exist public returns (bool) {
        uint restaurant_id = reg.return_rest_id(msg.sender);
        require(order_details[order_id].rest == restaurant_id, "Not your order");
        require(order_details[order_id].status == OrderStatus.picked, "Agent has not picked it yet");
        Order storage o = order_details[order_id];
        uint amount = 9*(o.price)/10; 
        foodtoken.transfer(msg.sender,amount);// give EasyFood tokens to Restaurant       
        return true;
    }
    
    
    function rate_food(uint rating) user_exist() public returns (bool) {
        require(reg.check_last_order(msg.sender)==true, "You haven't ordered");
        require(rating >= 0 && rating <= 5, "Invalid rating");
        
        uint order_id = reg.return_last_order(msg.sender);
        order_details[order_id].rest_rating = rating;
        uint restid=order_details[order_id].rest;
        reg.rest_rating(restid,rating);
        return true;        
    }
    
    
    function rate_agent(uint rating) user_exist() public returns (bool) {
        require(reg.check_last_order(msg.sender)==true, "You haven't ordered");
        require(rating >= 0 && rating <= 5, "Invalid rating");
        
        uint order_id = reg.return_last_order(msg.sender);
        order_details[order_id].agent_rating = rating;
        uint agentid=order_details[order_id].agent;
        reg.agent_rating(agentid,rating);
        return true;
    }

    function status (uint  order_id) public view returns (uint) { 
        if (order_details[order_id].status==OrderStatus.picked){
            return 5;
        }
        if (order_details[order_id].status==OrderStatus.ordered){
            return 1;
        }
        if (order_details[order_id].status==OrderStatus.accepted){
            return 2;
        }
        if (order_details[order_id].status==OrderStatus.agent_found){
            return 3;
        }
        if (order_details[order_id].status==OrderStatus.prepared){
            return 4;
        }
        if (order_details[order_id].status==OrderStatus.delivered){
            return 6;
        }
        if (order_details[order_id].status==OrderStatus.refunded){
            return 7;
        }
    }
}