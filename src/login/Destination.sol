// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {AbstractCallback} from "reactive-lib/abstract-base/AbstractCallback.sol"; 
import {IReactive} from "reactive-lib/interfaces/IReactive.sol";



interface IDestination{

    function on_log(
        address _rvm_id ,
        bytes memory _log_data,
        bytes[] memory _origin_data
    ) external;
}


library LibDestination{
    /// @dev Storage position determined by the keccak256 hash of the diamond storage identifier.
    bytes32 constant STORAGE_POSITION = keccak256("erc8042:wvs.Destination");
    
    struct DestinationStorage{
        bytes4 event_selector;
    }

    function getStorage() internal pure returns (DestinationStorage storage $){
        bytes32 position = STORAGE_POSITION;
        assembly("memory-safe"){
            $.slot := position
        }
    }

}


abstract contract Destination is IDestination, AbstractCallback{
    
    /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.Destination
     */

    bytes32 constant public STORAGE_SLOT = 0x3ff7ff80a107badef667c448ff0a700282ef47359027d67a66a78790b63577e7;
    
    struct DestinationStorage{
        bytes4 event_selector;
    }

    function getStorage() internal pure returns (DestinationStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

    constructor(address _callback_sender) AbstractCallback(_callback_sender){}


    function on_log(
        address _rvm_id,
        bytes memory _log_data,
        bytes[] memory _data
    ) external rvmIdOnly(_rvm_id){
        _on_log(_log_data, _data);
    }

    function _on_log(bytes memory _log_data, bytes[] memory _data) internal virtual;


}
