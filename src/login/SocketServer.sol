// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {MetaProxyDeployer} from "euler-vault-kit/src/GenericFactory/MetaProxyDeployer.sol";
import {CREATE3} from "solady/utils/CREATE3.sol";
import "./Listener.sol";

// import {CreateX} from ""
// NOTE: This:
//   - The SocketManager is a MetaProxyDeployer
//   - The SocketManager receives the origin address and it's chain Id
//   - The SocketManager deploys SocketContracts using createX
//   - The SocketManager lives on the Reactive-Network
// There is one socket server per chain

struct Port{
    uint256 origin_chain_id;
    address endpoint;
}

struct SocketSubscription{
    address listener;
    address target;
    bytes4 event_selector;
}



interface ISocketServer{

    // This receive the msg sender, so it does not require args

    
    function setSocket(address _publisher,address _socket) external;
    function set_socket_implementation(address _socket) external;
    function setPort(uint256 _originChainId, address _endpoint) external;
    function listen(address _listener) external;
}

contract SocketServer is MetaProxyDeployer, ISocketServer{

    /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.socketServer
     */

    bytes32 constant public STORAGE_SLOT = 0xbc6804d897d36506460df3f138d1e666ff601ba56ea4b1f000cb9237bdf814c3;
    
    struct SocketServerStorage{
        Port port;
        address socket_implementation;
        mapping(address user => uint256 nonce) nonces;
        mapping(address publisher => address socket) sockets;
        mapping(address socket => SocketSubscription) subscriptions;
    }

    function getStorage() internal pure returns (SocketServerStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

    function setPort(uint256 _originChainId, address _endpoint) external{
        SocketServerStorage storage $ = getStorage();
        $.port = Port({
            origin_chain_id :_originChainId,
            endpoint: _endpoint
        });
    }

    function set_socket_implementation(address _socket_implementation) external{
        SocketServerStorage storage $ = getStorage();
        $.socket_implementation = _socket_implementation;
    }

    function setSocket(address _publisher,address _socket) external{
        SocketServerStorage storage $ = getStorage();
        $.sockets[msg.sender] = _socket;
    }

    function nonce(address _user) internal returns(uint256 _nonce){
        SocketServerStorage storage $ = getStorage();
        _nonce = $.nonces[_user];
    }

    function _increment_nonce(address _user) internal{
        SocketServerStorage storage $ = getStorage();
        $.nonces[_user]++;
    }




    function listen(address _listener) external{
        
        address predicted_socket = CREATE3.predictDeterministicAddress(
            keccak256(
                abi.encodePacked(
                    "sockerServer",
                    msg.sender,
                    nonce(msg.sender)
                )
            ),
            address(this)
        );
        
        
        _increment_nonce(msg.sender);

        bytes4 _event_selector = IListener(_listener).get_event_selector();
        
        _set_socket_subscription(predicted_socket, _listener, msg.sender, _event_selector);
    }

    function _set_socket_subscription(address _socket, address _listener, address _target, bytes32 _event_selector) internal{
        SocketServerStorage storage $ = getStorage();
        $.subscriptions[_socket] = SocketSubscription({
            listener: _listener,
            target: _target,
            event_selector: bytes4(_event_selector)
        });
    }

    function _get_socket_subscription(address _socket) internal returns(SocketSubscription memory _socket_subscription){
        SocketServerStorage storage $ = getStorage();
        _socket_subscription = $.subscriptions[_socket];
    }

    function _get_socket(address _publisher, address _predicted_socket_address) internal virtual returns(address _socket){
        SocketServerStorage storage $ = getStorage();
        
        bytes memory _metadata = abi.encode($.port, $.subscriptions[_predicted_socket_address]);
        
        if ($.sockets[msg.sender] == address(0x00)){
            $.sockets[msg.sender] = deployMetaProxy($.socket_implementation, _metadata);
        }

        _socket = $.sockets[msg.sender];
    }


}
