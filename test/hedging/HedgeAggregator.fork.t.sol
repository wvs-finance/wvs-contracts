// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import "../../src/hedging/HedgeAggregator.sol";
import "../../src/hedging/HedgeSubscriptionManager.sol";
import "../ForkTest.sol";
import "../fork/ForkUtils.sol";
import "./HedgeLPMetrics.fork.t.sol";
import {LibDiamond} from "Compose/src/diamond/LibDiamond.sol";
import {DiamondCutFacet} from "Compose/src/diamond/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "Compose/src/diamond/DiamondLoupeFacet.sol";

contract Foo{

    uint256 bar;

    function foo() external{
        bar++;
    }
}


contract HedgeAggregatorForkTest is HedgeLPSubscriptionManagerForkTest{
    


    address hedge_aggregator;
    

    //-----diamond-seeds
    address diamond_cut = address(new DiamondCutFacet());
    address diamond_loupe = address(new DiamondLoupeFacet());

    //=========================CALLDATA=======================================
    
    bytes ZERO_BYTES= bytes("");

    //======================================================================


    function setUp() public override{
        super.setUp();
        
        
        
        hedge_aggregator = address(new HedgeAggregator());

    

        vm.makePersistent(hedge_aggregator);
        // IHedgeAggregator(hedge_aggregator).__init__(admin);

    }

    function test__fork__initializeDiamondFacetsSuccess() public{
        //===============PRE-CONDITIONS=======================
        //====================================================
        //=====================TEST===========================
        vm.selectFork(unichain_fork);
        IHedgeAggregator(hedge_aggregator).__init__(address(this));
        
        //======================================================
    
        //================POST-CONDITIONS======================
        // NOTE: Verify the diamond contracts have not zero addresses and that
        // they hold code on them

        assertNotEq(address(0x00), IHedgeAggregator(hedge_aggregator).diamond_cut());
        assertNotEq(address(0x00), IHedgeAggregator(hedge_aggregator).diamond_loupe());
        assertNotEq(uint256(0x00), IHedgeAggregator(hedge_aggregator).diamond_loupe().code.length);
        assertNotEq(uint256(0x00), IHedgeAggregator(hedge_aggregator).diamond_cut().code.length);
        
        // note: Verfy the owner is address(this) and the it is stored on
        // the hedge aggreagator contract
        address _diamond_cut = IHedgeAggregator(hedge_aggregator).diamond_cut();
        address _diamond_loupe = IHedgeAggregator(hedge_aggregator).diamond_loupe();
        assertEq(_diamond_loupe, DiamondLoupeFacet(hedge_aggregator).facetAddress(DiamondLoupeFacet.facetAddress.selector));
        assertEq(_diamond_cut,DiamondLoupeFacet(hedge_aggregator).facetAddress(DiamondCutFacet.diamondCut.selector));

        vm.label(user, "invalid_caller");
        vm.expectRevert();
        vm.startPrank(user);

        (DiamondCutFacet.FacetCut[] memory __diamondCut, address _init, bytes memory _calldata) = _build_any_diamond_cut();
        
        DiamondCutFacet(hedge_aggregator).diamondCut(
            __diamondCut,
            _init,
            _calldata
        );

        vm.stopPrank();

    }

    

    function _build_any_diamond_cut() internal returns(DiamondCutFacet.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata){
        _diamondCut = new DiamondCutFacet.FacetCut[](uint256(0x01));
        
        
        _diamondCut[0x00] = DiamondCutFacet.FacetCut(
            address(new Foo()),
            DiamondCutFacet.FacetCutAction.Add,
            new bytes4[](uint256(0x01))
        );
        _diamondCut[0x00].functionSelectors[0x00] = Foo.foo.selector;
        _init = address(0x00);
        _calldata = abi.encode("0x00");

    }

    // function test__fork__addHedgeSubscriptionFunctionsSuccess() public{
    //     //===============PRE-CONDITIONS=======================
    //     //====================================================
    //     //=====================TEST===========================
    //     vm.selectFork(unichain_fork);
    //     IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);
    //     //======================================================
    //     //================POST-CONDITIONS======================

        

    // }

    // function test__fork__subscriptionManagerInitDelegateSuccess() public{
    //     //================PRE-CONDITIONS====================
    //     vm.selectFork(unichain_fork); 
    //     IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);

    //     //================================================
        
    //     //================TEST========================
    //     vm.startPrank(USDC_WHALE);

    //     uint256 _position_token_id = mint_liquidity_default(USDC_WHALE);
    //     IHedgeSubscriptionManager(hedge_aggregator).__init__(POSITION_MANAGER);
    //     vm.stopPrank();
   
    //     address _lp_metrics_factory = IHedgeSubscriptionManager(hedge_aggregator).metrics_factory();  
   
    //     //=========================================================
    //     // ===================POST-CONDITIONS=======================
    //     assertEq(IHedgeSubscriptionManager(hedge_aggregator).lpm(), POSITION_MANAGER);
    //     assertEq(USDC_WHALE,IERC721(POSITION_MANAGER).ownerOf(_position_token_id));
    //     assertNotEq(address(0x00), _lp_metrics_factory);
    //     assertEq(GenericFactory(_lp_metrics_factory).upgradeAdmin(),hedge_aggregator);


    // }



    // function test__fork__subscriptionManagerSetLPMetricsImplDelegateSuccess() public{
    //     //===================PRE-CONDITIONS=============================
    //     vm.selectFork(unichain_fork);
    //     IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);
    //     vm.startPrank(USDC_WHALE);
    //     uint256 _position_token_id = mint_liquidity_default(USDC_WHALE);
    //     IHedgeSubscriptionManager(hedge_aggregator).__init__(POSITION_MANAGER);
    //     address _lp_metrics_factory = IHedgeSubscriptionManager(hedge_aggregator).metrics_factory(); 
    //     vm.stopPrank();

        
    //     //==============================================================
    //     //======================TEST====================================

    //     IHedgeSubscriptionManager(hedge_aggregator).set_lp_metrics_implementation(hedge_lp_metrics_impl);
    //     address _lp_metrics_implementation = GenericFactory(_lp_metrics_factory).implementation();
        
    //     //===================================================================
    //     //====================POST-CONDITIONS===========================
    //     assertNotEq(_lp_metrics_implementation,address(0x00));
    //     assertEq(IHedgeLPMetrics(_lp_metrics_implementation).factory(), address(0x00));



    //     //==============================================================

    // }



    // function test__fork__subscriptionManagerSubscribeSucess() public {

    //     //===================PRE-CONDITIONS====================
    //     vm.selectFork(unichain_fork); 
    //     IHedgeAggregator(hedge_aggregator).set_hedge_subscription_manager(hedge_subscription_manager);

    //     vm.startPrank(USDC_WHALE);
    //     uint256 _position_token_id = mint_liquidity_default(USDC_WHALE);

    //     IHedgeSubscriptionManager(hedge_aggregator).__init__(POSITION_MANAGER);
    //     IERC721(POSITION_MANAGER).approve(hedge_aggregator, _position_token_id);

    //     vm.stopPrank();

    //     IHedgeSubscriptionManager(hedge_aggregator).set_lp_metrics_implementation(hedge_lp_metrics_impl);
    
    //     //================================================

    //         ///===================TEST=============================
    //     vm.startPrank(USDC_WHALE);
    //     IHedgeSubscriptionManager(hedge_aggregator).subscribe(_position_token_id, USDC_WHALE);
    //     vm.stopPrank();
    //    //====================================================
    //    //====================POST-CONDITIONS================= 



        
    // }




}