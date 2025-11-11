// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AbstractPausableReactive} from "reactive-lib/abstract-base/AbstractPausableReactive.sol";
import "./SocketServer.sol";
import  "./types/Endpoint.sol";


interface ISocket{
    function chain_id() external returns(uint256);
    function origin() external returns(address);
    function endpoint() external returns(Endpoint memory);
    function destination() external returns(address);
}

contract Socket is ISocket, AbstractPausableReactive{
    using EndpointLib for Endpoint;
    // NOTE: This is supposed to be param,terics but
    // from now is manual
    
    /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.socket
    */

   bytes32 constant STORAGE_SLOT = 0xb4fec1add9e2765bd0eb53c4053166b984884c16174fa63cd30e5d3b583154d2;
   uint256 private constant CALLBACK_GAS_LIMIT = 1000000;

    struct SocketStorage{
        uint256 chain_id;
        address origin;
        Endpoint endpoint;
        address destination;
    }

    function getStorage() internal pure returns (SocketStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

    // TODO: This is best stored in bytecode 
    // as eip-3448
    constructor(
        uint256 _chain_id,
        address _origin,
        Endpoint memory _endpoint,
        address _destination  
    ) payable AbstractPausableReactive(){
        SocketStorage storage $ = getStorage();
        
        detectVm();

        if (!vm){
            for (
                uint256 index; 
                index < _endpoint.selectors.length;
                index++
            )
            {   

                (bool _ok, bytes memory _res) = address(service).call{value : msg.value}(
                    abi.encodeWithSignature(
                        "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
                        _chain_id,
                        _origin,
                        uint256(bytes32(_endpoint.selectors[index])),
                        REACTIVE_IGNORE,
                        REACTIVE_IGNORE,
                        REACTIVE_IGNORE
                    )
                );
                

            }
            
        }
        $.chain_id = _chain_id;
        $.origin = _origin;
        $.endpoint = _endpoint;
        $.destination = _destination;
    }

    function chain_id() external returns(uint256){
        SocketStorage storage $ = getStorage();
        return $.chain_id;
    }

    function origin() external returns(address){
        SocketStorage storage $ = getStorage();
        return $.origin;
    }

    function endpoint() external returns(Endpoint memory){
        SocketStorage storage $ = getStorage();
        return $.endpoint;
    }

    function destination() external returns(address){
        SocketStorage storage $ = getStorage();
        return $.destination;
    }
    

    function react(LogRecord calldata log) external vmOnly(){
        SocketStorage storage $ = getStorage();
        if (
            log._contract == $.origin && log.chain_id == $.chain_id &&
            $.endpoint.has(
                bytes4(
                    bytes32(
                        log.topic_0
                    )
                )
            )    
        ){
            bytes memory _event_data = abi.encode(
                log.topic_1,
                log.topic_2,
                log.topic_3,
                log.data
            );
            bytes memory _destinaton_payload = abi.encodeWithSignature(
                "on_log(address,bytes memory, bytes[] memory)",
                address(0x00),
                _event_data,
                new bytes[](uint256(0x00))
                // $.endpoint.data
            );

            emit Callback(
                $.chain_id,
                $.destination,
                uint64(CALLBACK_GAS_LIMIT),
                _destinaton_payload
            );

    
        }

   
    }
    

    function getPausableSubscriptions() override internal view returns (Subscription[] memory){

    }
}
