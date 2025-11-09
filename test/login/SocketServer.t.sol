// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {Test,console2} from "forge-std/Test.sol";
import "../../src/login/Socket.sol";
import "../../src/login/Listener.sol";
import "./utils/SocketServerHarness.sol";

contract SocketServerTest is Test{
    
    address socket_server;
    
    function setUp() public {
        address socket_server = address(new SocketServerHarness());
    }
    

}