// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "../../../src/login/Listener.sol";

contract ListenerHarness is Listener{
    
    function _on_log(IReactive.LogRecord memory _log, address _dst) internal override{}
}
