// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import "../../src/login/SocketServer.sol";
import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";
import {DeployReactive} from "./Deploy.s.sol";
import "../../test/fork/ForkUtils.sol";
// import {AbstractPayer} from "reactive-lib/";

contract Login is Script{
    

    bytes4[] public mock_event_selectors = new bytes4[](uint256(0x01));

    function login() external{
        run();
    }

    function run() public{
        bytes4 mock_event_selector = bytes4(keccak256("Stimulus(uint256 indexed)"));
        mock_event_selectors[0x00] = mock_event_selector;
        address socket_server = DevOpsTools.get_most_recent_deployment(
            "SocketServer",
            block.chainid
        );
        
        address _destination = DevOpsTools.get_most_recent_deployment(
            "MockDestinationSimple",
            SEPOLIA_CHAIN_ID
        );

        if (socket_server == address(0x00)){
            vm.broadcast();
            socket_server = address(new SocketServer());
        }

        vm.startBroadcast();
        // AbstractPayer(socket_server).coverDebt();
        ISocketServer(socket_server).listen(
            SEPOLIA_CHAIN_ID,
            msg.sender,
            _destination,
            mock_event_selectors
        );

        vm.stopBroadcast();
    }

    function direct_socket_deployment() external{
        
    }
}