// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

//   - The Socket is a MinimalProxy with metadata.
// The metadata is the tokenId
//   - The Socket is a AsbtractPausableReactive
//   - The Socket hears the PositionManager

import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {AbstractPausableReactive} from "reactive-lib/abstract-base/AbstractPausableReactive.sol";
import {console2} from "forge-std/console2.sol";
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

    constructor() payable AbstractPausableReactive(){
        Port memory _port = ISocketServer(owner).port();
        SocketSubscription memory _socket_subscription = ISocketServer(owner).socket_subscription(address(this));

        bytes memory subscription_payload = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            _port.origin_chain_id,
            _port.endpoint,
            uint256(bytes32(_socket_subscription.event_selector)),
            REACTIVE_IGNORE ,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE    
        );
        (bool subscription_result,) = address(service).call(subscription_payload);
        vm = !subscription_result;
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
        vm = false;
        Port memory _port = ISocketServer(owner).port();

        SocketSubscription memory _socket_subscription = ISocketServer(owner).socket_subscription(address(this));
        (bool subscription_result,) = address(service).call(subscription_payload);
    
    
        // NOTE: Set's the the VM back on
        vm = !subscription_result;
    }



// log.topic1 == address(0x00)
// &&
// (tx.origin == _subscription.target || IERC721(this.owner()).ownerOf(log.topic_3) == _subscription.target)
// 


    function react(LogRecord calldata log) external vmOnly(){

        Port memory _port = ISocketServer(owner).port();
        SocketSubscription memory _subscription = ISocketServer(owner).socket_subscription(address(this));
        
        if  (!(log.chain_id == _port.origin_chain_id && log._contract == _port.endpoint && bytes4(uint32(log.topic_0)) == _subscription.event_selector)) revert("Invalid Event to react");
        // TODO: This needs to be a protgramtic condition
        if (address(uint160(log.topic_1)) == address(0x00) && IERC721(_port.endpoint).ownerOf(log.topic_3) == _subscription.target){
            address _listener = ISocketServer(owner).listener();
            
        }

    }
    

    function getPausableSubscriptions() override internal view returns (Subscription[] memory){

    }
}
