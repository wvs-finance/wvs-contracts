// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../../src/login/Destination.sol";
import "./MockOriginSimple.sol";

contract MockDestinationSimple is Destination{
    address origin_simple;


    constructor(address _callback_sender, address _origin_simple) Destination (_callback_sender){
        origin_simple = _origin_simple;
    }

    function _on_log(bytes memory _log_data, bytes[] memory _data) internal override{
        IMockOriginSimple(origin_simple).action();    
    }
    
}