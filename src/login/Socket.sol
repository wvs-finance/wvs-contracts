// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AbstractPausableReactive} from "reactive-lib/abstract-base/AbstractPausableReactive.sol";
import {DoubleEndedQueue} from "openzeppelin-contracts/contracts/utils/structs/DoubleEndedQueue.sol";

interface ISocket{
    function __init__(uint256 _chain_id, address _origin, address _destination) external payable;
    function subscribe(address _rvm_id, bytes32 _topic_0) external;
    function chain_id() external returns(uint256);
    function origin() external returns(address);
    function destination() external returns(address);
}

contract Socket is ISocket, AbstractPausableReactive{
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;    
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
        DoubleEndedQueue.Bytes32Deque event_selectors;
        address destination;
    }

    function getStorage() internal pure returns (SocketStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }
    function chain_id() public view returns(uint256){
        SocketStorage storage $ = getStorage();
        return $.chain_id;
    }

    function origin() public view returns(address){
        SocketStorage storage $ = getStorage();
        return $.origin;
    }


    function destination() public view returns(address){
        SocketStorage storage $ = getStorage();
        return $.destination;
    }


    modifier callbackOnly(address evm_id) {
        require(msg.sender == address(service), 'Callback only');
        require(evm_id == owner, 'Wrong EVM ID');
        _;
    }

    constructor() payable AbstractPausableReactive(){}
    
    function __init__(uint256 _chain_id, address _origin, address _destination) external payable{
        SocketStorage storage $ = getStorage();
        $.chain_id = _chain_id;
        $.origin = _origin;
        $.destination = _destination;      
    }

    function subscribe(address _rvm_id , bytes32 _topic_0) external rnOnly() callbackOnly(_rvm_id){
        SocketStorage storage $ = getStorage();

        service.subscribe(
            chain_id(),
            origin(),
            uint256(_topic_0),
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        $.event_selectors.pushFront(_topic_0);

    }
    

    function react(LogRecord calldata log) external vmOnly(){
        SocketStorage storage $ = getStorage();

        if (
            log._contract == origin() && log.chain_id == chain_id()
        ){

            if (log.topic_0 == uint256($.event_selectors.front())){
            // TODO: Management of queue
                bytes memory _event_data = abi.encode(
                    log.topic_1,
                    log.topic_2,
                    log.topic_3,
                    log.data
                );
                
                bytes memory _destinaton_payload = abi.encodeWithSignature(
                    "on_log(address,bytes memory)",
                    address(0x00),
                    _event_data
                );

                emit Callback(
                    chain_id(),
                    destination(),
                    uint64(CALLBACK_GAS_LIMIT),
                    _destinaton_payload
                );
            }
                
        }

   
    }
    

    function getPausableSubscriptions() override internal view returns (Subscription[] memory){

    }
}
