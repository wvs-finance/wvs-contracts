// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DiamondCutFacet} from "Compose/src/diamond/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "Compose/src/diamond/DiamondLoupeFacet.sol";


// TODO: This also needs to interact with the DiamondLoupeFacet

contract HedgeAggregator is  DiamondCutFacet{
    error FunctionNotFound(bytes4 selector);


    function __init__(address _crud_admin) external{
        OwnerStorage storage $ = getOwnerStorage();
        $.owner = _crud_admin;
    }


    fallback() external payable {
        DiamondStorage storage s = getDiamondStorage();
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