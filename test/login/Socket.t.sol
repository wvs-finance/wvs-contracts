// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";

import "./utils/SocketHarness.sol";
import {MockEndpoint} from "./utils/MockEndpoint.sol";

import "../fork/ForkUtils.sol";

contract SocketTest is Test{

    address socket;
    function setUp() public {
        socket = address(new SocketHarness());

    }

    function test__socket__metadata() external{
        
        Port memory mock_port = Port({
            origin_chain_id: UNICHAIN_CHAIN_ID,

        });
    }

    
}