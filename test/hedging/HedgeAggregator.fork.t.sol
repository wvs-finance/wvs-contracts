// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "../../src/hedging/HedgeAggregator.sol";
import "../../src/hedging/HedgeSubscriptionManager.sol";
import "../../src/login/ListenerCallback.sol";
import "../ForkTest.sol";
import "../fork/ForkUtils.sol";

import {LibDiamond} from "Compose/src/diamond/LibDiamond.sol";

contract HedgeAggregatorForkTest is ForkTest{
    


    address hedge_aggregator;
    address hedge_subscription_manager;
    address diamond_loupe;
    address diamond_cut;
    address admin;
    bytes4[] hedge_subscription_manager_interface = new bytes4[](uint256(0x06));
    LibDiamond.FacetCut subscription_manager;
    function setUp() public override{
        super.setUp();
        admin = address(this);
        vm.label(admin, "admin");
        
        
        
        // address hedge_aggregator = address(new HedgeAggregator());
        hedge_subscription_manager = address(new HedgeSubscriptionManager());

        hedge_subscription_manager_interface[0x00] = IHedgeSubscriptionManager.__init__.selector;
        hedge_subscription_manager_interface[0x01] = IHedgeSubscriptionManager.subscribe.selector;
        hedge_subscription_manager_interface[0x02] = IHedgeSubscriptionManager.metrics_factory.selector;
        hedge_subscription_manager_interface[0x03] = IHedgeSubscriptionManager.set_lp_metrics_implementation.selector;
        hedge_subscription_manager_interface[0x04] = IHedgeSubscriptionManager.lpm.selector;
        hedge_subscription_manager_interface[0x05] = IHedgeSubscriptionManager.position_metrics_lens.selector;
        
        subscription_manager = LibDiamond.FacetCut(
            hedge_subscription_manager,
            LibDiamond.FacetCutAction.Add,
            hedge_subscription_manager_interface
        );

        diamond_loupe = address(new DiamondLoupeFacet());
        diamond_cut = address(new DiamondCutFacet());

        vm.makePersistent(hedge_aggregator);
        // IHedgeAggregator(hedge_aggregator).__init__(admin);

    }

    function test__fork__addHedgeSubscriptionFunctionsSuccess() public{
        vm.selectFork(unichain_fork);
        
        LibDiamond.diamondCut(
            subscription_manager,
            hedge_subscription_manager,
            bytes("")
        );

        // IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);


    }




}