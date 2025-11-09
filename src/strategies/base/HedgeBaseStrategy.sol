// // SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity ^0.8.17;

// // NOTE: This is private useing Phenix 
// // NOTE: This is reactive using IReactive
// // NOTE: This is controlled by TimeLockController
// // NOTE: Events on react(LogRecord) ---> Actions  

// // import {IReactive} 
// // import {TimeLockController} --> MaturityManager
// // NOTE: As MaturityManager this:

// // --> Enforce hedge maturity via TimeLockController
// // --> Trigger settlement at maturity
// // --> Handle early settlement requests
// // --> Manage settlement windows


// library Actions{
//     uint256 constant INCREASE = 0x01;
//     uint256 constant DECREASE = 0x02;
//     uint256 constant REBALANCE = 0x03;

// }
// interface IHedgeStrategy{
    
//     // NOTE: This is the response type that needs to receive from the IMarketDataOracle
//     struct MarketData{
//         uint160 current_price; // NOTE: This is obtained from underlying_entry_point.IpriceOracle
//         uint160 volatility;   //NOTE: underlying_entry_point.IPriceOracle.impliedVolatility()
//         uint48 timeToMaturity // NOTE: This is queryiong the TimeLockController
//         uint256 currentIl; // NOTE: This is querying underlying_entry_point.ILiquidityIntel.calculateIL()
//         uint256 portafolio_value // NOTE: This is querying underlying_entry_point.ILiquidityIntel.getHOdl(tokenId)

//     }

//     function derivatives() external returns(addres[] memory);
// }

// contract HedgeBaseStrategy{

//     // NOTE: Immutable attachment 1 to 1 to a liquidityPosition
//     uint256 immutable liquidity_position_token;
    
//     // NOTE: The access point is to the underlying derivatives pool
//     // This is the (implemenation on the beacon)
//     // NOTE: The diamond determines the rentry poiitn of the strategy at deployemnet time
//     address immutable underlying_entry_point;
//     // NOTE: For the VS is VIX for buy/sell the tokens

//     // NOTE: THere is also immutable access to the deploye, which is the diamond
//     address immutable hedge_manager;


//     // NOTE: There is access to market insights

//     IMarketOracle market_oracle;
    
// }




