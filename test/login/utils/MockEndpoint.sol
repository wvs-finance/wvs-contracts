// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MockEndpoint{

    event MockEvent();

    function emit_event() external{
        emit MockEvent();
    }
}