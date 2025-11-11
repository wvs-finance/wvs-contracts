// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";

import "./fork/ForkUtils.sol";

contract ForkTest is Test{
    uint256 unichain_fork;
    uint256 reactive_fork;

    address socket_server;


    address user;
    function setUp() public virtual{
        uint256 deployer_private_key = vm.envUint("PRIVATE_KEY");
        user = vm.addr(deployer_private_key);

        reactive_fork = vm.createFork(vm.envString("REACTIVE_RPC_ENDPOINT"));
        unichain_fork = vm.createFork(vm.envString("UNICHAIN_RPC_ENDPOINT"));

    }

    function pre_deploy_reactive(address _deployer) internal returns(bytes32){
        vm.selectFork(reactive_fork);
        assertEq(block.chainid , REACTIVE_CHAIN_ID);
        vm.deal(_deployer, REACT_AMOUNT_TO_DEPLOY);
        
        bytes32 reactive_salt = keccak256(abi.encodePacked("reactive", REACTIVE_CHAIN_ID));
        return reactive_salt;
    }
       

    function pre_deploy_unichain(address _deployer) internal returns(bytes32,bytes32){
        vm.selectFork(unichain_fork);
        assertEq(block.chainid, UNICHAIN_CHAIN_ID);
        vm.deal(_deployer, ETHER_AMOUNT_TO_DEPLOY);
        bytes32 unichain_salt_endpoint = keccak256(abi.encodePacked("unichain-endpoint", UNICHAIN_CHAIN_ID));
        bytes32 unichain_salt_listener = keccak256(abi.encodePacked("unichain-listener", UNICHAIN_CHAIN_ID));
        return (unichain_salt_endpoint,unichain_salt_listener);
    }




}