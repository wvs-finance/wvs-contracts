// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {AbstractCallback} from "reactive-lib/abstract-base/AbstractCallback.sol";
import {IHedgeSubscriptionManager} from "wvs-finance-hedging/HedgeSubscriptionManager.sol";

interface IListenerCallback{
    function on_log(bytes calldata _event_data) external;
    function hedge_aggregator() external returns(address);
    function __init__(address _hedge_aggregator) external;
}

contract ListenerCallback is IListenerCallback{
    
    bytes32 constant LISTENER_CALLBACK_POSITION = keccak256("wvs.hedge-login.ListenerCallback");
    
    struct ListenerCallbackStorage{
        address hedge_aggregator;
    }

    function getStorage() internal pure returns (ListenerCallbackStorage storage s) {
        bytes32 position = LISTENER_CALLBACK_POSITION;
        assembly ("memory-safe"){
            s.slot := position
        }
    }

    // constructor(address _callback_sender) AbstractCallback(_callback_sender){}

    function __init__(address _hedge_aggregator) external{
        ListenerCallbackStorage storage $ = getStorage();
        $.hedge_aggregator = _hedge_aggregator; 
    }

    function hedge_aggregator() public view returns(address){
        ListenerCallbackStorage storage $ = getStorage();
        return $.hedge_aggregator;
    }

    function on_log(bytes calldata _event_data) external{
        (uint256 _token_id, address _lp_account) =_validate_event_data(_event_data);
        IHedgeSubscriptionManager(hedge_aggregator()).subscribe(_token_id, _lp_account);
    }

    function _validate_event_data(bytes calldata _event_data) internal virtual returns(uint256,address){}


}