// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {Test,console2} from "forge-std/Test.sol";
import "./utils/SocketServerHarness.sol";
import "./utils/SocketHarness.sol";
import "./utils/ListenerHarness.sol";

import "../fork/ForkUtils.sol";

import {MockEndpoint} from "./utils/MockEndpoint.sol";



contract SocketServerTest is Test{
    
    address socket_server;
    address socket_implementation;

    Port mock_port;
    SocketSubscription mock_socket_subscription;
    bytes4 mock_event_selector;

    address endpoint;
    address listener;

    address socket_reference;
    address user;

    address any_caller;

    function setUp() public {
        mock_event_selector = bytes4(keccak256("MockEvent()"));
        socket_server = address(new SocketServerHarness());
        
        socket_implementation = address(new SocketHarness());
        endpoint = address(new MockEndpoint());
        listener = address(new ListenerHarness());

        IListener(listener).set_event_selector(bytes32(mock_event_selector));

        mock_port = Port({
            origin_chain_id: UNICHAIN_CHAIN_ID,
            endpoint: endpoint
        });

        ISocketServer(socket_server).__init__(
            mock_port.origin_chain_id,
            mock_port.endpoint,
            listener,
            socket_implementation
        );


        user = address(this);
        any_caller = makeAddr("any-caller");

        vm.label(user, "user");
        vm.label(any_caller, "any-caller");

        mock_socket_subscription = SocketSubscription({
            target: user,
            event_selector: IListener(listener).get_event_selector()
        });

        
    }

    // function test__unit__socketServerSocketImplementation() external{
    //     address _socket_implementation = ISocketServer(socket_server).socket_implementation();
    //     assertEq(socket_implementation, _socket_implementation);
    //     // TODO: The socket to be deployed must be compliant
    //     // TODO: Not anyone can CRUD the implementation
    
    // }

    function test__unit__socketServerListen() external{
        bytes32 hash_mock_socket_subscription = keccak256(abi.encode(mock_socket_subscription));
        vm.startPrank(user);

        ISocketServer(socket_server).listen(mock_event_selector);
        
        address _socket = ISocketServer(socket_server).get_socket();
        
        SocketSubscription memory _socket_subscription = ISocketServer(socket_server).socket_subscription(_socket);
        
        bytes32 hash_socket_subscription = keccak256(abi.encode(_socket_subscription));
        
        assertEq(hash_mock_socket_subscription,hash_socket_subscription);

        
        vm.stopPrank();

        
    
    }

}