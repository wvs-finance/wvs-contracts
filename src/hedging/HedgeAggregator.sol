// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {DiamondCutFacet} from "Compose/src/diamond/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "Compose/src/diamond/DiamondLoupeFacet.sol";
import {LibDiamond} from "Compose/src/diamond/LibDiamond.sol";
import {IHedgeSubscriptionManager} from "./HedgeSubscriptionManager.sol";

// TODO: This also needs to interact with the DiamondLoupeFacet

interface IHedgeAggregator{
    function __init__(address _authorized_caller) external;
    function diamond_cut() external view returns(address);
    function diamond_loupe() external view returns(address);
    // function set_hedge_subscription_manager(address) external;
}



interface IDiamondCutFacet{
    
    function diamondCut(LibDiamond.FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}


interface IDiamondLoupeFacet{
    struct Facet {
        address facet;
        bytes4[] functionSelectors;
    }

    function facetAddress(bytes4 _functionSelector) external view returns (address facet);
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetSelectors);
    function facets() external view returns (Facet[] memory facetsAndSelectors);
    function facetAddresses() external view returns (address[] memory allFacets);

}


contract HedgeAggregator is IHedgeAggregator{
    error FunctionNotFound(bytes4 selector);


    // TODO: Ths can use ecustom storage layount sol 0.8.29
    bytes32 constant HEDGE_AGGREGATOR_STORAGE_POSITION = keccak256("wvs.hedge-aggregator");

    struct HedgeAggregatorStorage{
        address diamond_cut;
        address diamond_loupe;
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
    

    function __init__(address _authorized_caller ) external{
        
        // NOTE: Setting the diamond cut facet
        LibDiamond.FacetCut[] memory _diamond_facets_functions = new LibDiamond.FacetCut[](uint256(0x01));
        HedgeAggregatorStorage storage $ = getStorage();

        {
            address _diamond_cut_facet = address(new DiamondCutFacet());

            assembly("memory-safe"){
                sstore(0x0a3f54f528e7e1203573e58b7506067ecaaadb5458729147354c2910780e9eaa,_authorized_caller)
            }
            
  

            _diamond_facets_functions[0x00] = LibDiamond.FacetCut(
                _diamond_cut_facet,
                LibDiamond.FacetCutAction.Add,
                new bytes4[](uint256(0x01))
            );

            _diamond_facets_functions[0x00].functionSelectors[0x00] = IDiamondCutFacet.diamondCut.selector;
            (bool _ok, bytes memory _res) = _diamond_cut_facet.delegatecall(
                abi.encodeCall(
                    IDiamondCutFacet.diamondCut,
                    (
                        _diamond_facets_functions,
                        address(0x00),
                        abi.encode("0x00")
                    )
                )
            );
            

            $.diamond_cut = _diamond_cut_facet;
        }

        // NOTE: Setting the diamond loupe facet
        {
            address _diamond_loupe_facet = address(new DiamondLoupeFacet());
            _diamond_facets_functions[0x00] = LibDiamond.FacetCut(
                _diamond_loupe_facet,
                LibDiamond.FacetCutAction.Add,
                new bytes4[](uint256(0x04))
            );
            _diamond_facets_functions[0x00].functionSelectors[0x00] = IDiamondLoupeFacet.facetAddresses.selector;
            _diamond_facets_functions[0x00].functionSelectors[0x01] = IDiamondLoupeFacet.facetFunctionSelectors.selector;
            _diamond_facets_functions[0x00].functionSelectors[0x02] = IDiamondLoupeFacet.facets.selector;
            _diamond_facets_functions[0x00].functionSelectors[0x03] = IDiamondLoupeFacet.facetAddress.selector;
            (bool _ok, bytes memory _res) = $.diamond_cut.delegatecall(
                abi.encodeCall(
                    IDiamondCutFacet.diamondCut,
                    (
                        _diamond_facets_functions,
                        address(0x00),
                        abi.encode("0x00")
                    )
                )
            );

            $.diamond_loupe = _diamond_loupe_facet;
        }
    }




    // function set_hedge_subscription_manager(address _impl) external{
    //     OwnerStorage storage $ = getOwnerStorage();
    //     $.owner = address(this);

    //     bytes4[] memory  _interface = new bytes4[](uint256(0x06));

    //     _interface[0x00] = IHedgeSubscriptionManager.__init__.selector;
    //     _interface[0x01] = IHedgeSubscriptionManager.subscribe.selector;
    //     _interface[0x02] = IHedgeSubscriptionManager.metrics_factory.selector;
    //     _interface[0x03] = IHedgeSubscriptionManager.set_lp_metrics_implementation.selector;
    //     _interface[0x04] = IHedgeSubscriptionManager.lpm.selector;
    //     _interface[0x05] = IHedgeSubscriptionManager.position_metrics_lens.selector;

    //     DiamondCutFacet.FacetCut[] memory _cut = new DiamondCutFacet.FacetCut[](uint256(0x01));
    //     _cut[0x00] = DiamondCutFacet.FacetCut(_impl, DiamondCutFacet.FacetCutAction.Add, _interface);
    //     this.diamondCut(_cut, address(0x00), abi.encode("0x00"));
    // }

    
    



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