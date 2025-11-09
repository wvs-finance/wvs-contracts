// // SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity ^0.8.17;


// // NOTE: This takes calculates per-event ALL metrics needed to value hedging derivatives

// // - $w_i$: Given position, calculate the share of its position relative to the total liquidity
// // in such tick range (or the optimal tick range based on volatility) using the external price 

// // - $V_{\text{\texttt{LP}}} \big ( [i_l^\star, i_u^\star]\big )$ Calculate the value of the total liquidity on optimal range
// // - Cal
// // - $\big (V_{\text{\texttt{LP}}}\big )_i = w_i \cdot V_{\text{\texttt{LP}}} \big ( [i_l^\star, i_u^\star]\big )$

// // - Once a position is created, for every swap that affects internal price of the pool it computes the HODL value (considering the initial liquidity added) and


// // import {IReactiver}
// // NOTE: For UniswapV3 LiquidityOracle it needs to be a reactive contract that plays the role of hook per event
// // Like addLiqudiity --> ModifyLiquidity / afterSwap --> Swap


// contract LiquidityOracleUniswapV3 is AsbtractReactive{

// }


// // impor {UniswapV4Hook} from  ... v4-template
// // import                       ... Hookmate
// // import                       .... openzeppelin/uniswap-hooks

// // import {IPriceOracle} fron ..




// // NOTE: This is for the handling using hooks of events 
// contract LiquidityOracleUniswapV4{
//     IPriceOracle price_oracle;

//     function afterAddLiquidity(
//         ModifyLiquidityParams calldata liquidityPosition
//     ) external{
    
//         (uint128 liquidityOn0 ,uint128 liquidityOn1) = (
//             liquidityPosition.liquidityDelta.amount0(), liquidityPosition.liquidityDelta.amount0()
//         );
//         uint160 safeTwapExternalPrice = IPriceOracle(oracle).getSafePrice().tosqrtPrice160();

//         uint256 positionTokenId = liquidityPosition.salt;

//         lp_hodl_equivalent_portafolio[positionTokenId] = Hodl_portafolio({
//             token0: liquidityOn0,
//             token1: liquidityOn1,
//             initialPrice: safeTwapExternalPrice
//             isFinal: false
//         });

//         event Hodl_Portfolio( ... );
//         event LP_Portafolio( ... );




//     }

//     // - Then the impermanent loss event gets triggered every time a swap happens


//     function afterSwap(

//     ) external{
        
//         (uint160 internalPrice160, int24 currentTick,,,) = getSlot0();
        
//         (int24 optimalTickLower, int24 optimalTickUpper) = IExternalOracle(oracle).getVolatility().getOptimalTicks();

//         uint160 safeTwapExternalPrice = IExternalOracle(oracle).getSafePrice().tosqrtPrice160();


//         // NOTE: This is K_T = P_T/P_0
//         uint160 priceImpactRelativeToInitialPrice SqrtPriceLibrary.priceImpact(
//             lp_hodl_equivalent_portafolio[positionTokenId].initialPrice,
//             internalPrice160
//         ).mulDiv(basisPoints);

//         uint160 priceImpactRelativeToCurrentRate = SqrtPriceLibrary.priceImpact(
//             safeTwapExternalPrice,
//             internalPrice160
//         ).mulDiv(basisPoints);

//         // NOTE: This includes impermanent loss calculation ...
//         // It also includes the straddle caulclation for fair pricing (seee fukasawa 2022*(pg 4))
//         event LP_Portafolio( ... );

//     }


// // - We can calculate ATM straddless for call and put options from price data

// // - Now the liquidity provider wishes to hedge against their position's exposure to losses relative to HODL.

// // - He has two options variance swaps and american options




// }












