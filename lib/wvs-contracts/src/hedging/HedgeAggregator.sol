// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DiamondCutFacet} from "Compose/src/diamond/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "Compose/src/diamond/DiamondLoupeFacet.sol";
import {LibDiamond} from "Compose/src/diamond/LibDiamond.sol";
import {IHedgeSubscriptionManager} from "./HedgeSubscriptionManager.sol";

// TODO: This also needs to interact with the DiamondLoupeFacet

interface IHedgeAggregator{
    function __init__() external;
    function set_hedge_subscription_manager(address) external;
}


contract HedgeAggregator is  IHedgeAggregator{
    error FunctionNotFound(bytes4 selector);

    bytes32 constant HEDGE_AGGREGATOR_STORAGE_POSITION = keccak256("wvs.hedge-aggregator");

    struct HedgeAggregatorStorage{
        address diamond_loupe;
        address diamond_cut;
    }

    function __init__() external{
        HedgeAggregatorStorage storage $ = getStorage();
        $.diamond_cut = address(new DiamondCut());
        $.diamond_loupe = address(new DiamondLoupeFacet());
        
        // bytes4[] memory _diamond_cut_facet_selectors = ;
        
        LibDiamond.diamondCut(
            new FacetCut(
                $.diamond_cut,
                LibDiamond.FacetCutAction.Add,
                [DiamondCut.diamondCut.selector]
            ),
            $.diamond_cut,
            bytes("")
        );
    }

    function getStorage() internal pure returns (HedgeAggregatorStorage storage s) {
        bytes32 position = HEDGE_AGGREGATOR_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
    
 
    
    function set_hedge_subscription_manager(address _impl) external{
        OwnerStorage storage $ = getOwnerStorage();
        $.owner = address(this);

        bytes4[] memory  _interface = new bytes4[](uint256(0x07));

        _interface[0x00] = IHedgeSubscriptionManager.__init__.selector;
        _interface[0x01] = IHedgeSubscriptionManager.subscribe.selector;
        _interface[0x02] = IHedgeSubscriptionManager.metrics_factory.selector;
        _interface[0x03] = IHedgeSubscriptionManager.set_lp_metrics_implementation.selector;
        _interface[0x04] = IHedgeSubscriptionManager.lpm.selector;
        _interface[0x05] = IHedgeSubscriptionManager.position_metrics_lens.selector;
        _interface[0x06] = IHedgeSubscriptionManager.position_lp_account.selector;

        DiamondCutFacet.FacetCut[] memory _cut = new DiamondCutFacet.FacetCut[](uint256(0x01));
        _cut[0x00] = DiamondCutFacet.FacetCut(_impl, DiamondCutFacet.FacetCutAction.Add, _interface);
        this.diamondCut(_cut, address(0x00), abi.encode("0x00"));
    }

    





    
    



    constructor(
        // address _owner,

    )
    {   
        // HedgeAggregatorStorage storage $ = getStorage();        // DiamondCutFacet.OwnerStorage storage o$= DiamondCutFacet($.diamond_cut).getOwnerStorage();
        // o$.owner = _owner;
    }

    // Add the facet associated with creating subscriptions



    fallback() external payable {
        LibDiamond.DiamondStorage storage s = LibDiamond.getStorage();
        address facet = s.facetAndPosition[msg.sig].facet;
        if (facet == address(0)) revert FunctionNotFound(msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
            case 0 { revert(0, size) }
            default { return(0, size) }
        }
    }

    receive() external payable {}


}