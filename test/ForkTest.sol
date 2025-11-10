// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";


contract ForkTest is Test{
    uint256 unichain_fork;
    uint256 reactive_fork;


    address user;
    function setUp() public virtual{
        uint256 deployer_private_key = vm.envUint("PRIVATE_KEY");
        user = vm.addr(deployer_private_key);

        reactive_fork = vm.createFork(vm.envString("REACTIVE_RPC_ENDPOINT"));
        unichain_fork = vm.createFork(vm.envString("UNICHAIN_RPC_ENDPOINT"));


    }
}