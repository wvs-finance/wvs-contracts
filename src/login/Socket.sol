// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

//   - The Socket is a MinimalProxy with metadata.
// The metadata is the tokenId
//   - The Socket is a AsbtractPausableReactive
//   - The Socket hears the PositionManager
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {AbstractPausableReactive} from "reactive-lib/abstract-base/AbstractPausableReactive.sol";

import "./SocketServer.sol";
import "./Listener.sol";

// LOG0 = 0xA0 (160) — 0 topics
// LOG1 = 0xA1 (161) — 1 topic
// LOG2 = 0xA2 (162) — 2 topics
// LOG3 = 0xA3 (163) — 3 topics
// LOG4 = 0xA4 (164) — 4 topics


interface ISocket{
    function subscribe(uint256 op_code, uint256[3] memory _encoded_topic_values) external;

}


contract Socket is ISocket, AbstractPausableReactive{
    // NOTE: This is supposed to be param,terics but
    // from now is manual
    
     /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.socket
     */

    bytes32 constant STORAGE_SLOT = 0xb4fec1add9e2765bd0eb53c4053166b984884c16174fa63cd30e5d3b583154d2;


   struct SocketStorage{
        bytes _storage;
   }

    function getStorage() internal pure returns (SocketStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

// LOG0 = 0xA0 (160) — 0 topics
// LOG1 = 0xA1 (161) — 1 topic
// LOG2 = 0xA2 (162) — 2 topics
// LOG3 = 0xA3 (163) — 3 topics
// LOG4 = 0xA4 (164) — 4 topics
// Deployments occur both on the 
// - Reactive Network, 
// - Deployer's private ReactVM, 
//      - The system contract is not present

    function subscribe(uint256 op_code, uint256[3] memory _encoded_topic_values) external rnOnly {
        (Port memory _port,SocketSubscription memory _socket_subscription) = _metadata();
        
        service.subscribe(
            _port.origin_chain_id,
            _port.endpoint,
            uint256(bytes32(_socket_subscription.event_selector)),
            op_code == uint256(0xA1) ? _encoded_topic_values[0x00]: REACTIVE_IGNORE ,
            op_code == uint256(0xA2) ? _encoded_topic_values[0x01]: REACTIVE_IGNORE,
            op_code == uint256(0xA3) ? _encoded_topic_values[0x01]: REACTIVE_IGNORE
        );
        // NOTE: Set's the the VM back on
        vm = true;
    }



// log.topic1 == address(0x00)
// &&
// (tx.origin == _subscription.target || IERC721(this.owner()).ownerOf(log.topic_3) == _subscription.target)
// 


    function react(LogRecord calldata log) external vmOnly(){

        (Port memory _port, SocketSubscription memory _subscription) = _metadata();
        if  (!(log.chain_id == _port.origin_chain_id && log._contract == _port.endpoint && bytes4(uint32(log.topic_0)) == _subscription.event_selector)) revert("Invalid Event to react");
        // TODO: This needs to be a protgramtic condition
        if (address(uint160(log.topic_1)) == address(0x00) && IERC721(_port.endpoint).ownerOf(log.topic_3) == _subscription.target){
            IListener(_subscription.listener).on_log(log, _subscription.target);
        }

    }
    
    function _metadata() private pure returns(Port memory _port, SocketSubscription memory _subscription){
        bytes memory data;
        assembly {
            let posOfMetadataSize := sub(calldatasize(), 32)
            let size := calldataload(posOfMetadataSize)
            let dataPtr := sub(posOfMetadataSize, size)
            data := mload(64)
            mstore(64, add(data, add(size, 32)))
            mstore(data, size)
            let memPtr := add(data, 32)
            calldatacopy(memPtr, dataPtr, size)
        }

        //return the decoded the metadata
        (_port, _subscription) = abi.decode(data, (Port, SocketSubscription));
    }

    function getPausableSubscriptions() override internal view returns (Subscription[] memory){

    }
}
