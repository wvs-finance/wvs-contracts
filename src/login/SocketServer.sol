// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {MetaProxyFactory} from "../eip/MetaProxyFactory.sol";
import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";
import "./types/Endpoint.sol";
import "./Socket.sol";
// One port CAN have many origins and
import {AbstractPayer} from "reactive-lib/abstract-base/AbstractPayer.sol";


interface ISocketServer{
    // NOTE: This is the entry point
    // after logging in 
    function listen(
        uint256 _chain_id,
        address _target,        
        address  _destination,
        bytes4[] calldata _event_selectors
        // bytes[] calldata _arbitrary_data
    ) external returns(address);

    function chains(address _user) external returns(uint256[] memory);
    function endpoints(uint256 _chain_id) external returns(Endpoint memory);
    function origins(uint256 _chain_id) external returns(address);
    function destinations(uint256 _chain_id) external returns(address);
    function sockets(address _user, uint256 _chain_id) external returns(address);

    
}

contract SocketServer is ISocketServer, AbstractPayer{
    using EndpointLib for Endpoint;
    /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.socketServer
     */

    bytes32 constant public STORAGE_SLOT = 0xbc6804d897d36506460df3f138d1e666ff601ba56ea4b1f000cb9237bdf814c3;
    
    struct SocketServerStorage{
        mapping(address _user => uint256[] _chainids) chains;
        mapping(address _user => mapping(uint256 _chain_id => address _socket)) sockets;
        mapping(uint256 _chainid => Endpoint) endpoints;
        mapping(uint256 _chainid => address _origin) origins;
        mapping(uint256 _chainid => address _destination) destinations;
    }

    function getStorage() internal pure returns (SocketServerStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }
    function chains(address _user) public view returns(uint256[] memory){
        SocketServerStorage storage $ = getStorage();
        return $.chains[_user];
    }

    function endpoints(uint256 _chain_id) public view returns(Endpoint memory){
        SocketServerStorage storage $ = getStorage();
        return $.endpoints[_chain_id];
    }

    function origins(uint256 _chain_id) public view returns(address){
        SocketServerStorage storage $ = getStorage();
        return $.origins[_chain_id];
    }

    
    function destinations(uint256 _chain_id) public view returns(address){
        SocketServerStorage storage $ = getStorage();
        return $.destinations[_chain_id];
    }
    
    function sockets(address _user, uint256 _chain_id) public view returns(address){
        SocketServerStorage storage $ = getStorage();
        return $.sockets[_user][_chain_id];
    }




    function listen(
        uint256 _chain_id,
        address _target,        
        address _destination,
        bytes4[] calldata _event_selectors
        // bytes[] calldata _arbitrary_data
    ) external returns(address){

        // if (
        //     _event_selectors.length != _arbitrary_data.length

        // ) {revert();}

       SocketServerStorage storage $ = getStorage();
       Endpoint memory endpoint = EndpointLib.__init__();
        for (uint256 selectors_index; selectors_index < _event_selectors.length; selectors_index++){
            endpoint = endpoint.add(
                _event_selectors[selectors_index]
                // _arbitrary_data[selectors_index]
            );
        }
 
        $.endpoints[_chain_id] = endpoint;
        address _chain_socket = _deploy_socket(_chain_id,_target,endpoint,_destination);
        
        this.coverDebt();
        return _chain_socket;
       
    }

    function _deploy_socket(
        uint256 _chain_id,
        address _target,
        Endpoint memory _endpoint,
        address _destination
    ) internal returns(address _socket){
        _socket = sockets(_target, _chain_id) != address(0x00) ? sockets(_target, _chain_id) : address(
                new Socket(
                    _chain_id,
                    origins(_chain_id),
                    _endpoint,
                    _destination
                )
            );
    }

}
