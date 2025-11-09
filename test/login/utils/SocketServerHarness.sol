// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "../../../src/login/SocketServer.sol";

contract SocketServerHarness is SocketServer{
    
    function set_socket_subscription(address _socket, address _listener, address _target, bytes32 _event_selector) external {
        _set_socket_subscription(_socket,_listener,_target,_event_selector);
    }

    function get_socket_subscription(address _socket) external returns(SocketSubscription memory _socket_subscription){
        _socket_subscription =_get_socket_subscription(_socket);
    }

    function increment_nonce(address _user) external{
        _increment_nonce(_user);
    }

    function nonce_harness(address _user) external returns(uint256 _nonce){
        _nonce = nonce(_user);
    }
}

