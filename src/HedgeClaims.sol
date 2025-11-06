// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;
// import {ERC1155}
// TODO: It works as SettlementEngine too
interface IHedgeClaims{
    
    struct SettlementResult {
        uint256 vixSettlementAmount;
        bool success;
        string reason;
    }


    function settleHedge(uint256 hedgeId) external returns (SettlementResult memory);


}

// NOTE: It also works as a registry for strategies, the owner is the controller of the LP position

contract HedgeClaims {
    
    // NOTE: This is the data to be displayed on the LP dashoboard
    // liquidity_position_tokenId --> hedge_tokenId[] --> hedge_tokenId --> 
    struct ClaimMetadata{
        uint256 liquidity_position_tokenId;
        uint256 initial_value;
        uint256 current_value;
        uint256 pnl;
        uint256 apy;
        string strategy_name;
    }

    // NOTE: All the above goes on ERC1155Metadata


}