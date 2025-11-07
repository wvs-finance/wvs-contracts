// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


// import {MetaProxyDeployer} from ""
// import {CreateX} from ""
// NOTE: This:
//   - The SocketManager receives the origin address and it's chain Id
//   - The SocketManager is a MetaProxyDeployer
//   - The SocketManager deploys SocketContracts using createX
//   - The SocketManager lives on the Reactive-Network
// There is one socket server per chain

struct Port{
    uint256 origin_chain_id;
    address endpoint;
}



interface ISocketServer{
    error SocketNotSet();

    // This receive the msg sender, so it does not require args

    function listen() external;
    function setSocket(address _socket) external;
}

contract SocketServer is MetaProxyDeployer, ISocketServer{

    /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.socketServer
     */

    bytes32 constant public STORAGE_SLOT = 0xbc6804d897d36506460df3f138d1e666ff601ba56ea4b1f000cb9237bdf814c3;
    
    struct SocketServerStorage{
        Port port;
        address socket;    
    }

    function getStorage() internal pure returns (SocketServerStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

    function setSocket(address _socket) external{
        SocketServerStorage $ = getStorage();
        $.socket = _socket;
    }


    constructor(uint256 _originChainId, address _endpoint){
        SocketServerStorage $ = getStorage();
        $.port = Port({
            origin_chain_id :_originChainId,
            endpoint: _endpoint
        });
    }

    function listen() external{
        address _socket = _listen();
    }

    function _listen() internal virtual returns(address _socket){
        SocketServerStorage $ = getStorage();
        
        bytes _metadata = abi.encode($.port, msg.sender);
        if ($.socket == address(0x00)) revert SocketNotSet();
        _socket = deployMetaProxy($.socket, _metadata);

    }









}
