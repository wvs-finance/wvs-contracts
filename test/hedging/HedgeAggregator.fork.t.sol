// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import "../../src/hedging/HedgeAggregator.sol";
import "../../src/hedging/HedgeSubscriptionManager.sol";
import "../../src/login/ListenerCallback.sol";
import "../ForkTest.sol";
import "../fork/ForkUtils.sol";
import "./HedgeLPMetrics.fork.t.sol";
import {LibDiamond} from "Compose/src/diamond/LibDiamond.sol";

contract HedgeAggregatorForkTest is HedgeLPSubscriptionManagerForkTest{
    


    address hedge_aggregator;
    //=========================CALLDATA=======================================
    
    bytes ZERO_BYTES= bytes("");

    //======================================================================


    function setUp() public override{
        super.setUp();
        
        
        
        hedge_aggregator = address(new HedgeAggregator());
    

        vm.makePersistent(hedge_aggregator);
        // IHedgeAggregator(hedge_aggregator).__init__(admin);

    }

    function test__fork__addHedgeSubscriptionFunctionsSuccess() public{
        //===============PRE-CONDITIONS=======================
        //====================================================
        //=====================TEST===========================
        vm.selectFork(unichain_fork);
        IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);
        //======================================================
        //================POST-CONDITIONS======================

        

    }

    function test__fork__subscriptionManagerInitDelegateSuccess() public{
        //================PRE-CONDITIONS====================
        vm.selectFork(unichain_fork); 
        IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);

        //================================================
        
        //================TEST========================
        vm.startPrank(USDC_WHALE);

        uint256 _position_token_id = mint_liquidity_default(USDC_WHALE);
        IHedgeSubscriptionManager(hedge_aggregator).__init__(POSITION_MANAGER);
        vm.stopPrank();
   
        address _lp_metrics_factory = IHedgeSubscriptionManager(hedge_aggregator).metrics_factory();  
   
        //=========================================================
        // ===================POST-CONDITIONS=======================
        assertEq(IHedgeSubscriptionManager(hedge_aggregator).lpm(), POSITION_MANAGER);
        assertEq(USDC_WHALE,IERC721(POSITION_MANAGER).ownerOf(_position_token_id));
        assertNotEq(address(0x00), _lp_metrics_factory);
        assertEq(GenericFactory(_lp_metrics_factory).upgradeAdmin(),hedge_aggregator);


    }



    function test__fork__subscriptionManagerSetLPMetricsImplDelegateSuccess() public{
        //===================PRE-CONDITIONS=============================
        vm.selectFork(unichain_fork);
        IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);
        vm.startPrank(USDC_WHALE);
        uint256 _position_token_id = mint_liquidity_default(USDC_WHALE);
        IHedgeSubscriptionManager(hedge_aggregator).__init__(POSITION_MANAGER);
        address _lp_metrics_factory = IHedgeSubscriptionManager(hedge_aggregator).metrics_factory(); 
        vm.stopPrank();

        
        //==============================================================
        //======================TEST====================================

        IHedgeSubscriptionManager(hedge_aggregator).set_lp_metrics_implementation(hedge_lp_metrics_impl);
        address _lp_metrics_implementation = GenericFactory(_lp_metrics_factory).implementation();
        
        //===================================================================
        //====================POST-CONDITIONS===========================
        assertNotEq(_lp_metrics_implementation,address(0x00));
        assertEq(IHedgeLPMetrics(_lp_metrics_implementation).factory(), address(0x00));



        //==============================================================

    }



    function test__fork__subscriptionManagerSubscribeSucess() public {

        //===================PRE-CONDITIONS====================
        vm.selectFork(unichain_fork); 
        IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);

        vm.startPrank(USDC_WHALE);
        uint256 _position_token_id = mint_liquidity_default(USDC_WHALE);

        IHedgeSubscriptionManager(hedge_aggregator).__init__(POSITION_MANAGER);
        IERC721(POSITION_MANAGER).approve(hedge_aggregator, _position_token_id);

        vm.stopPrank();

        IHedgeSubscriptionManager(hedge_aggregator).set_lp_metrics_implementation(hedge_lp_metrics_impl);
    
        //================================================

            ///===================TEST=============================
        vm.startPrank(USDC_WHALE);
        IHedgeSubscriptionManager(hedge_aggregator).subscribe(_position_token_id, USDC_WHALE);
        vm.stopPrank();
       //====================================================
       //====================POST-CONDITIONS================= 



        
    }




}