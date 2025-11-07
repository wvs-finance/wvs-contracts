// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

//   - The Socket is a MinimalProxy with metadata.
// The metadata is the tokenId
//   - The Socket is a AsbtractPausableReactive
//   - The Socket hears the PositionManager
// import {
//     AbstractPausableReactive,
//     IReactive
// }
import "./SocketServer.sol";
// import {LibCall} from "solady/"
import "./Listener.sol";

interface ISocket{

}


contract Socket is ISocket, AbstractPausableReactive{
    using LibCall for address;
    // NOTE: This is supposed to be param,terics but
    // from now is manual
    
     /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.socket
     */

    bytes32 constant STORAGE_SLOT = 0xb4fec1add9e2765bd0eb53c4053166b984884c16174fa63cd30e5d3b583154d2;


   struct SocketStorage{
        bytes32  event_selector;
        address  callback;
   }

    function getStorage() internal pure returns (SocketStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

    function _setListener(address _listener) internal{
        SocketStorage $ = getStorage();
        $.callback = _listener;

    }

    fucntion getListener() public view returns(address _listener){
        SocketStorage $ = getStorage();
        _listener = $.callback;
    }

    function _set_event_selector(bytes4 _event_selector) internal{
        SocketStorage $ = getStorage();
        $.event_selector = _event_selector;
    }

    function get_event_selector() public view returns(bytes4 _event_selector){
        SocketStorage $ = getStorage();
        _event_selector = bytes4($.event_selector);   

    }



    
    constructor(address _listener, bytes32 _event_selector) AbstractPausableReactive{
        {
            _setListener(_listener);
            _set_event_selector(_event_selector);
        }
        (Port memory _port,) = metadata();
        (bool _ok,) = address(service).call(
            abi.encodeCall(
                ISubscriptionService.subscribe,
                (
                    _port.origin_chain_id,
                    _port.endpoint,
                    uint256(_event_selector),
                    REACTIVE_IGNORE,
                    REACTIVE_IGNORE,
                    REACTIVE_IGNORE
                )
            )
        ); 
        vm = !_ok;






   
    }


    function react(LogRecord calldata log) external{
        (Port memory _port, address target) = metadata();
        if  (
            log.chainId == _port.origin_chain_id &&
            log._contract == _port.endpoint &&
            uint160(address(log.topic1)) == address(0x00) &&
            bytes4(uint32(log.topic_0)) && get_event_selector() &&
            (tx.origin == target || IERC721(this.owner()).ownerOf(log.topic_3) == target) 
        )
        {
            
            IListener(getListener()).unlockHedge();
        }


    }

    
    function metadata() private pure returns(Port memory _port, address _target){
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
        (_port, _target) = abi.decode(data, (Port, address));
    }
}
