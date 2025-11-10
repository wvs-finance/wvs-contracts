// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";

import "./utils/SocketHarness.sol";
import "./utils/ListenerHarness.sol";

import {MockEndpoint} from "./utils/MockEndpoint.sol";

import "../fork/ForkUtils.sol";

contract SocketTest is Test{



    address socket;
    
    address endpoint;
    bytes32 mock_event_selector;
    address listener;
    


    function setUp() public {
        
        mock_event_selector = keccak256("MockEvent()");
        // NOTE: This is deployed on reactive network
        
        socket = address(new SocketHarness());
        
        // NOTE: This is deployed on Unichain
        
        endpoint = address(new MockEndpoint());
        listener = address(new ListenerHarness());
        
    }

    function test__socket__metadata() external{
        IListener(listener).set_event_selector(mock_event_selector);

        Port memory mock_port = Port({
            origin_chain_id: UNICHAIN_CHAIN_ID,
            endpoint: endpoint
        });

        SocketSubscription memory mock_socket_subscription = SocketSubscription({
            target: address(this),
            event_selector: IListener(listener).get_event_selector()
        });

    }

    
}