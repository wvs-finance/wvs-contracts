// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "../../src/hedging/HedgeSubscriptionManager.sol";
import "../../src/hedging/HedgeLPMetrics.sol";
import "../fork/ForkUtils.sol";
import "../ForkTest.sol";

contract HedgeLPSubscriptionManagerForkTest is ForkTest{

    address hedge_lp_metrics_impl;
    address hedge_subscription_manager;
    address admin;


    function setUp() public override{
        super.setUp();
        vm.deal(USDC_WHALE, 10 ether);
           
        
        hedge_subscription_manager = address(new HedgeSubscriptionManager());
        hedge_lp_metrics_impl = address(new HedgeLPMetrics());
        vm.makePersistent(hedge_subscription_manager, POSITION_MANAGER,hedge_lp_metrics_impl);


        
    }

    function test__fork__subscriptionManagerInit() external{
        IHedgeSubscriptionManager(hedge_subscription_manager).__init__(POSITION_MANAGER);
        assertEq(IHedgeSubscriptionManager(hedge_subscription_manager).lpm(), POSITION_MANAGER);

        
        IHedgeSubscriptionManager(hedge_subscription_manager).set_lp_metrics_implementation(hedge_lp_metrics_impl);
    }

    function test__fork__mustMint() external{

    }   


    function mint_liquidity_default(address _minter) internal returns(uint256 _tokenId){
        
    }

}


