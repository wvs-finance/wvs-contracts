// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "./utils/ListenerHarness.sol";
import {Test, console2} from "forge-std/Test.sol";



contract ListenerTest is Test{
    

    address listener_harness;

    function setUp() public{
        listener_harness = address(new ListenerHarness());      
    }

    function test__listener__setEventSelector() external{
        bytes32 selector = keccak256(abi.encode("Transfer(address,address,uint256)"));
        IListener(listener_harness).set_event_selector(selector);
        bytes4 expected_selector = bytes4(selector);
        bytes4 event_selector = IListener(listener_harness).get_event_selector();
        assertEq(expected_selector, event_selector);
    }

    // NOTE: More tests, on re-entrancy, attack vectors, permissions, etc


}

