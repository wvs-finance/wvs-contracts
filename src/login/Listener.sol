// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {IReactive} from "reactive-lib/interfaces/IReactive.sol";

// import {AbstractCallback} from ""
// import {AccessControl} from 
// import {EnumerableMap} from 
// import {ISubscriber}
// import {INotifier}
// import {IReactive}


interface IListener{
    function get_event_selector() external returns(bytes4);
    function set_event_selector(bytes32 _event_selector) external;
    function on_log(IReactive.LogRecord memory _log, address _dst) external;
}


library LibListener{
    /// @dev Storage position determined by the keccak256 hash of the diamond storage identifier.
    bytes32 constant STORAGE_POSITION = keccak256("erc8042:wvs.listener");
    
    struct ListenerStorage{
        bytes4 event_selector;
    }

    function getStorage() internal pure returns (ListenerStorage storage $){
        bytes32 position = STORAGE_POSITION;
        assembly("memory-safe"){
            $.slot := position
        }
    }
}


abstract contract Listener is IListener{
    
    /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.listener
     */

    bytes32 constant public STORAGE_SLOT = 0x3ff7ff80a107badef667c448ff0a700282ef47359027d67a66a78790b63577e7;
    
    struct ListenerStorage{
        bytes4 event_selector;
    }

    function getStorage() internal pure returns (ListenerStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

    function get_event_selector() external returns(bytes4){
        ListenerStorage storage $ = getStorage();
        return $.event_selector;
    }
    
    function set_event_selector(bytes32 _event_selector) external {
        ListenerStorage storage $ = getStorage();
        $.event_selector = bytes4(_event_selector);
    }

    function on_log(IReactive.LogRecord memory _log, address _dst) external{
        _on_log(_log, _dst);
    }

    function _on_log(IReactive.LogRecord memory _log, address _dst) internal virtual;
}
