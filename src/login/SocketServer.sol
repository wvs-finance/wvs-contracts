// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {MetaProxyFactory} from "../eip/MetaProxyFactory.sol";
import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";
// import {CREATE3} from "solady/utils/CREATE3.sol";
import "./Listener.sol";
// import {OwnableFacet} from 
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
    address target;
    bytes4 event_selector;
}



interface ISocketServer{

    // This receive the msg sender, so it does not require args

    function __init__(uint256 _originChainId, address _endpoint, address _listener, address _socket_implementation) external;
    function listen(bytes4 _event_selector) external;
    

    
    function port() external returns(Port memory _port);
    function listener() external returns(address _listener);
    function socket_implementation() external returns(address _socket_implementation);
    function socket_subscription(address _socket) external returns(SocketSubscription memory _socket_subscription);
    function get_socket() external returns(address _socket);

    
}

contract SocketServer is MetaProxyFactory, ISocketServer{

    /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.socketServer
     */

    bytes32 constant public STORAGE_SLOT = 0xbc6804d897d36506460df3f138d1e666ff601ba56ea4b1f000cb9237bdf814c3;
    
    struct SocketServerStorage{
        Port port;
        address socket_implementation;
        address listener;
        mapping(address publisher => address socket) sockets;
        mapping(address socket => SocketSubscription) subscriptions;
    }

    function getStorage() internal pure returns (SocketServerStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

    function __init__(
        uint256 _originChainId,
        address _endpoint,
        address _listener,
        address _socket_implementation
    ) external{
        SocketServerStorage storage $ = getStorage();

        $.port = Port({
            origin_chain_id :_originChainId,
            endpoint: _endpoint
        });
        
        $.listener = _listener;
        $.socket_implementation = _socket_implementation;

    }

    function port() public view returns(Port memory _port){
        SocketServerStorage storage $ = getStorage();
        _port = $.port;
    }

    function listener() public view returns(address _listener){
        SocketServerStorage storage $ = getStorage();
        _listener = $.listener;
    }

    function get_socket() public view returns(address _socket){
        SocketServerStorage storage $ = getStorage();
        _socket = $.sockets[msg.sender];
    }


    function socket_implementation() public view returns(address _socket_implementation){
        SocketServerStorage storage $ = getStorage();
        _socket_implementation = $.socket_implementation;
    }

    function _deploy_socket(address _caller, bytes4 _event_selector) internal returns(address _socket){
        SocketServerStorage storage $ = getStorage();
        /// NOTE: This assumes the address was properly set on the firts place
        if ($.sockets[_caller] != address(0x00)){
            _socket = $.sockets[_caller];
        }
        
        SocketSubscription memory _socket_subscription = SocketSubscription({
            target: _caller,
            event_selector : _event_selector
        });

        Port memory _port = port();

        bytes memory _metadata = abi.encode(_port, _socket_subscription);
        
        _socket = _metaProxyFromBytes(socket_implementation(), _metadata);
        $.sockets[_caller] = _socket;

    }

    function listen(bytes4 _event_selector) external{
        
        address _socket = _deploy_socket(msg.sender, _event_selector);
        _set_socket_subscription(_socket, msg.sender, _event_selector);

    }

    function _set_socket_subscription(address _socket, address _target, bytes4 _event_selector) internal{
        SocketServerStorage storage $ = getStorage();
        $.subscriptions[_socket] = SocketSubscription({
            target: _target,
            event_selector: _event_selector
        });
    }

    function socket_subscription(address _socket) external returns(SocketSubscription memory _socket_subscription){
        // if (msg.sender != _socket ) revert("Socket is not caller");
        // // TODO: This is only callable by the socket
        SocketServerStorage storage $ = getStorage();
        _socket_subscription = $.subscriptions[_socket];
    }

}
