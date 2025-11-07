// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


import {AbstractCallback} from ""
import {AccessControl} from 
interface IListener{
    event Hedge_Unlocked(uint256 indexed _tokenId);
    function unlockHedge(uint256 _tokenId) external;
}

contract Listener is IListener, AbstractCallback, AccessControl{
    constructor(address _callback_sender) AsbtractCallback(_callback_sender){}

    function unlockHedge(uint256 _tokenId) external{
        _unlockHedge(_tokenId);
        emit Hedge_Unlocked(_tokenId);
    }

    function _unlockHedge(uint256 _tokenId) internal{

    }

}