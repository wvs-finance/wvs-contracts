// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./SocketServer.t.sol";
import "../ForkTest.sol";
import "../../src/PortafolioRegistry.sol";


contract SocketSeverForkTest is ForkTest{
    address socket_server;
    address socket_implementation;

    Port mock_port;
    SocketSubscription mock_socket_subscription;
    bytes4 mock_event_selector;

    address endpoint;
    address listener;

    function deploy_reactive(uint256 _pay_to_deploy) internal{
        vm.selectFork(reactive_fork);
        assertEq(block.chainid, REACTIVE_CHAIN_ID);
        vm.deal(user, _pay_to_deploy);
        
        // Use CREATE2 with unique salt per fork to avoid CreateCollision
        // Salt includes chain ID to ensure uniqueness across forks
        bytes32 reactive_salt = keccak256(abi.encodePacked("reactive", REACTIVE_CHAIN_ID));
        
        vm.startPrank(user);
        socket_server = address(new SocketServerHarness{salt: reactive_salt}());
        // Use different salt for second deployment
        bytes32 reactive_salt_impl = keccak256(abi.encodePacked("reactive-impl", REACTIVE_CHAIN_ID));
        socket_implementation = address(new SocketHarness{salt: reactive_salt_impl}()); 
        vm.stopPrank();
        
        // Make persistent after stopping prank to ensure clean state
        vm.makePersistent(socket_server, socket_implementation);
    }

    function deploy_unichain(uint256 _pay_to_deploy) internal{
        vm.selectFork(unichain_fork);
        assertEq(block.chainid, UNICHAIN_CHAIN_ID);
        vm.deal(user, _pay_to_deploy);
        
        // Use CREATE2 with unique salt per fork to avoid CreateCollision
        // Salt includes chain ID to ensure uniqueness across forks
        // Same deployer (user) but different salts = different addresses
        bytes32 unichain_salt_endpoint = keccak256(abi.encodePacked("unichain-endpoint", UNICHAIN_CHAIN_ID));
        bytes32 unichain_salt_listener = keccak256(abi.encodePacked("unichain-listener", UNICHAIN_CHAIN_ID));
        
        vm.startPrank(user);
        endpoint = POSITION_MANAGER;
        listener = address(new ListenerHarness{salt: unichain_salt_listener}());
        vm.stopPrank();
        
        // Make persistent after stopping prank to ensure clean state
        vm.makePersistent(endpoint, listener);
    }


    function setUp() public override{
        super.setUp();


        mock_event_selector = bytes4(keccak256("MockEvent()"));
        
        deploy_reactive(20 ether);
        deploy_unichain(1 ether);
        
        
        mock_port = Port({
            origin_chain_id: UNICHAIN_CHAIN_ID,
            endpoint: endpoint
        });

        mock_socket_subscription = SocketSubscription({
            target: user,
            event_selector: mock_event_selector
        });


    }

    function test__fork__socketInit() external{
        vm.selectFork(reactive_fork);
        vm.prank(user);

        ISocketServer(socket_server).__init__(
            mock_port.origin_chain_id,
            mock_port.endpoint,
            listener,
            socket_implementation
        );

        bytes32 hash_port = keccak256(abi.encode(mock_port));
        assertEq(listener, ISocketServer(socket_server).listener());
        assertEq(hash_port,keccak256(abi.encode(ISocketServer(socket_server).port())));
    }

    function test__fork__socketServerListen() external{
        vm.selectFork(reactive_fork);
        vm.startPrank(user);
        ISocketServer(socket_server).listen(mock_event_selector);
        address _socket = ISocketServer(socket_server).get_socket();
        ISocket(_socket).subscribe(
            uint256(0xA0),
            [uint256(0x00), uint256(0x00),uint256(0x00)]
        );
        vm.stopPrank();

        vm.selectFork(unichain_fork);

        vm.prank(user);
        MockEndpoint(endpoint).emit_event();
        // vm.expectEmit(endpoint);


    }



}