// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;


// import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
// import "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";

// import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
// import {EnumerableMap} from "openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";

// import "./login/Destination.sol";

// import {ISubscriber} from "@uniswap/v4-periphery/src/interfaces/ISubscriber.sol";
// import {INotifier} from "@uniswap/v4-periphery/src/interfaces/INotifier.sol";


// interface IPortafolioRegistry{
//     function liquidity_position_manager() external view returns(address);

// }



// contract PortafolioRegistry is  
//     IPortafolioRegistry,
//     ISubscriber,
//     Destination,
//     AccessControl {
    
//     using EnumerableMap for EnumerableMap.AddressToUintMap;

//     /**
//      * @dev ERC-8042 compliant storage struct for ERC20 token data.
//      * @custom:storage-location erc8042:wvs.portafolioRegistry
//      */

//     bytes32 constant public STORAGE_SLOT = 0x7c945f2e7f52df4fa292585f05b707bba72cf3d95be9b68ea0f8817d9d81ed3d;
    

    
//     struct PortafolioRegistryStorage{
//         address liquidity_position_manager;
//         EnumerableMap.AddressToUintMap liquidity_positions;

//     }

//     function getStorage() internal pure returns (PortafolioRegistryStorage storage $){
//         bytes32 position = STORAGE_SLOT;
//         assembly("memory-safe"){
//             $.slot := position
//         }
//     }


//     constructor(
//         address _callback_sender,
//         address _lpm
//     ) AbstractCallback(_callback_sender){
//         PortafolioRegistryStorage storage $ = getStorage();
//         $.liquidity_position_manager = _lpm;
//     }

//     /// IListener

//     function on_log(address _rvm_id, IReactive.LogRecord memory _log, address _dst) external{
//         if (_log._contract != liquidity_position_manager() && _log.chain_id == block.chainid) revert("Invalid Log");
        
//         _add_position(_dst,_log.topic_3);

//     }

//     // IListener

//     function set_event_selector(bytes32 _event_selector) external{
//         PortafolioRegistryStorage storage $ = getStorage();
//         LibListener.set_event_selector(_event_selector);
        
//     }


//     // IPortafolioRegistry
//     function liquidity_position_manager() public view returns(address){
//         PortafolioRegistryStorage storage $ = getStorage();
//         return $.liquidity_position_manager;
//     }




//     function _add_position(address _owner, uint256 _tokenId) internal{
//         PortafolioRegistryStorage storage $ = getStorage();
//         $.liquidity_positions.set(_owner,_tokenId);
//         address _lpm = liquidity_position_manager();
//         INotifier(_lpm).subscribe(_tokenId, address(this), bytes(""));

//         // NOTE: This needs to be privacy enforced by Fhenix

//     }



//     // NOTE: For each tokenId owned by a liqudity provider with address 
//     // _owner there is a HedgeRegistry that keeps stores the hedges
//     //

//     ///  ---> ISubscriber
//     function notifySubscribe(uint256 tokenId, bytes memory data) external{

//     } 
//     function notifyBurn(uint256 tokenId, address owner, PositionInfo info, uint256 liquidity, BalanceDelta feesAccrued) public {}

//     function notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta feesAccrued) external{}
//     function notifyUnsubscribe(uint256 tokenId) external{}



// }
