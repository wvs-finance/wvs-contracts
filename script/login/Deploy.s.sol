// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {MockOriginSimple} from "../../test/login/utils/MockOriginSimple.sol";
import {MockDestinationSimple} from "../../test/login/utils/MockDestinationSimple.sol";
import "../../test/fork/ForkUtils.sol";
import {SocketServer} from "../../src/login/SocketServer.sol";

contract DeployNonReactive is Script {
    function deploy() external returns(address, address){
        return run();
    }

    function run() public returns(address,address){
        vm.startBroadcast();
        address origin = address(new MockOriginSimple());
        address destination = address(new MockDestinationSimple(SYSTEM_CONTRACT,origin));
        vm.stopBroadcast();
        console2.log(origin);
        console2.log(destination);
        return (origin, destination);
    }

}

contract DeployReactive is Script{
    function deploy() external returns(address){
        run();
    }

    function run() public returns(address){
        vm.broadcast();
        address socket_server = address(new SocketServer{value: 0.5 ether}());
        console2.log(socket_server);
        return socket_server;


    }
}