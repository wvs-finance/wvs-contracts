// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


import "../../../src/login/Socket.sol";

contract SocketHarness is Socket{
    function metadata() external pure returns(Port memory _port, SocketSubscription memory _subscription){
        (_port, _subscription) = _metadata();
    }
}