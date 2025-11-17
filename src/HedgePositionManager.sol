// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155Facet} from "Compose/src/token/ERC1155/ERC1155Facet.sol";
import {LibERC1155} from "Compose/src/token/ERC1155/LibERC1155.sol";
import "./types/Shared.sol";
import "./adapters/base/BaseAdapter.sol";

interface IHedgePositionManager{
   

    function write_contract(HedgeType, HedgeConfig calldata) external;
    function set_vix_adapter(address _vix_adapter) external;
    function set_greek_fi_adapter(address _greek_fi_adapter) external;

}

contract HedgePositionManager is IHedgePositionManager, ERC1155Facet{
    
    
    bytes32 constant HEDGE_POSM_STORAGE_POSITION = keccak256("wvs.hedge-selector");
    
    struct HedgePOSMStorage {
        address multi_asset_vault; // stores the collateral and the underlyings
        // per lp account 
        mapping(uint256 => mapping(HedgeType => uint256[])) hedges_by_position;     
        address vix_adapter;
        address greek_fi_adapter;
    }

    function getHedgePOSMStorage() internal pure returns (HedgePOSMStorage storage s) {
        bytes32 position = HEDGE_POSM_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    
    //NOTE: Must have adapters set 
    function write_contract(HedgeType _hedge_type, HedgeConfig calldata _hedge_config) external {
        HedgePOSMStorage storage s = getHedgePOSMStorage();
        // Check the hedge type and call the correct adapter
        if (_hedge_type == HedgeType.OPTION) {
            // Use GreekFi adapter
            IAdapter(s.greek_fi_adapter).create_hedge(_hedge_config);
        } else if (_hedge_type == HedgeType.VARIANCE_SWAP) {
               // Use VIX adapter
            IAdapter(s.vix_adapter).create_hedge(_hedge_config);
        } else {
            revert("Invalid hedge type");
        }
    }

    function set_vix_adapter(address _vix_adapter) external{
        HedgePOSMStorage storage s = getHedgePOSMStorage();
        s.vix_adapter = _vix_adapter;
    }

    function set_greek_fi_adapter(address _greek_fi_adapter) external{
        HedgePOSMStorage storage s = getHedgePOSMStorage();
        s.greek_fi_adapter = _greek_fi_adapter;
    }


}





    
    
    

