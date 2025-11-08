// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


interface IPortafolioRegistry{
    function set_liquidity_position_manager(address _liquidity_position_manager) external;
    function get_liquidity_position_manager() external view returns(address);

}



contract PortafolioRegistry is  
    IPortafolioRegistry,
    ISubscriber,
    IListener
    AbstractCallback, 
    AccessControl {
    
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /**
     * @dev ERC-8042 compliant storage struct for ERC20 token data.
     * @custom:storage-location erc8042:wvs.portafolioRegistry
     */

    bytes32 constant public STORAGE_SLOT = 0x7c945f2e7f52df4fa292585f05b707bba72cf3d95be9b68ea0f8817d9d81ed3d;
    

    
    struct PortafolioRegistryStorage{
        address listener;
        address liquidity_position_manager;
        EnumerableMap.AddressToUintMap liquidity_positions;

    }

    function getStorage() internal pure returns (PortafolioRegistryStorage storage $){
        bytes32 position = STORAGE_SLOT;
        assembly("memory-safe"){
            $.slot := position
        }
    }

    function set_listener(address _listener) external{
        PortafolioRegistryStorage $ = getStorage();
        $.listener = _listener;
    }





    constructor(address _callback_sender) AsbtractCallback(_callback_sender){}

    /// IListener

    function on_log(IReactive.LogRecord memory _log, address _dst) external{
        if (_log.contract != LPM && log.chainId == block.chainId) revert("Invalid Log");
        
        _add_position(_dst,_log.topic_3);

    }

    // IListener

    function set_event_selector(bytes32 calldata _event_selector){
        PortafolioRegistryStorage $ = getStorage();
        LibListener.set_event_selector(_event_selector);
        
    }

    // IListener

    function get_event_selector() external returns(bytes4){
        PortafolioRegistryStorage $ = getStorage();
        (bool ok, bytes memory res) = $.listener.delegatecall(
            abi.encodeCall(
                IListener.get_event_selector
            )
        );
        
        if (!ok){
            revert;
        }
        bytes4 _selector = abi.decode(res, (bytes4));

    }



    // IPortafolioRegistry 
    function set_liquidity_position_manager(address _liquidity_position_manager) external{
        PortafolioRegistryStorage $ = getStorage();
        $.liquidity_position_manager = _liquidity_position_manager;
    }

    // IPortafolioRegistry
    function get_liquidity_position_manager() external view returns(address){
        PortafolioRegistryStorage $ = getStorage();
        return $.liquidity_position_manager;
    }




    function _add_position(address _owner, uint256 _tokenId) internal{
        PortafolioRegistryStorage $ = getStorage();
        $.liquidity_positions.set(_tokenId, _owner);
        INotifier(LPM).susbscribe(_tokenId, address(this), bytes(""));

        // NOTE: This needs to be privacy enforced by Fhenix

    }



    // NOTE: For each tokenId owned by a liqudity provider with address 
    // _owner there is a HedgeRegistry that keeps stores the hedges
    //

    ///  ---> ISubscriber
    function notifySubscribe(uint256 tokenId, bytes memory data) external{

    } 



}
