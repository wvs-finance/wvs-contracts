// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "../../../src/login/SocketServer.sol";

contract SocketServerHarness is SocketServer{
    
    function deploy_socket(address _caller, bytes4 _event_selector) external returns(address _socket){
        _socket = _deploy_socket( _caller, _event_selector);
    }

    function set_socket_subscription(address _socket,address _target, bytes4 _event_selector) external {
        _set_socket_subscription(_socket,_target,_event_selector);
    }



}

