// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DiamondCutFacet} from "Compose/src/diamond/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "Compose/src/diamond/DiamondLoupeFacet.sol";
import {LibDiamond} from "Compose/src/diamond/LibDiamond.sol";
import {IHedgeSubscriptionManager} from "./HedgeSubscriptionManager.sol";

// TODO: This also needs to interact with the DiamondLoupeFacet

interface IHedgeAggregator{

    function diamond_loupe() external returns(address);
    function diamond_cut() external returns(address);

    // function set_hedge_subscription_manager(address) external;
}
contract HedgeAggregator is IHedgeAggregator{
    error FunctionNotFound(bytes4 selector);

    bytes32 constant HEDGE_AGGREGATOR_STORAGE_POSITION = keccak256("wvs.hedge-aggregator");

    struct HedgeAggregatorStorage{
        address diamond_loupe;
        address diamond_cut;
    }

    function getStorage() internal pure returns (HedgeAggregatorStorage storage s) {
        bytes32 position = HEDGE_AGGREGATOR_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function diamond_cut() public view returns(address){
        HedgeAggregatorStorage storage $ = getStorage();
        return $.diamond_cut;
    }

    function diamond_loupe() public view returns(address){
        HedgeAggregatorStorage storage $ = getStorage();
        return $.diamond_loupe;
    }



    constructor(
        // address _owner,
        address _diamond_loupe,
        address _diamond_cut    
    )
    {   
        HedgeAggregatorStorage storage $ = getStorage();
        $.diamond_cut = _diamond_cut;
        $.diamond_loupe = _diamond_loupe;
        // DiamondCutFacet.OwnerStorage storage o$= DiamondCutFacet($.diamond_cut).getOwnerStorage();
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