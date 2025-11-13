// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;


import "./unichain/ForkUtils.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";

// The goal is to track all the information about a position
// on Uniswap using a large position holder as a starting point

// 1. Let's get the tokenId of a position and based on that we get the
// liquidity position and can track all since it's starting point

// We want to know the starting block.number,
// or time where this position was born

abstract contract ForkHelper{


    struct fork_metadata{
        string rpc_endpoint_api_key;
        string network_name;
    }


    mapping (uint256 _forkId => bool _init_) fork_initiated;

    modifier only_fork_initiated(uint256 _fork_id){
        if (!fork_initiated[_fork_id]) revert("fork not initiated");
        _;
    }
    
    function fork_init(fork_metadata calldata _fork_metadata ) public returns (uint256 _fork_id){
        try vm.envString(_fork_metadata.rpc_endpoint_api_key) returns (string memory){
            uint256 forkId = vm.createFork(
                vm.rpcUrl(_fork_metadata.network_name)
            );

            fork_initiated[forkId] = true;

        } catch {
            fork_initiated[forkId] = false;
            console2.log("Failed on fork");
        }

    }

    

    
    function _findLiquidityPositionStartingBlockNumber(
        uint256 _forkId,
        uint256 _tokenId,
        uint256 _seed,
        fork_metadata calldata _fork_metadata
    ) internal only_fork_initiated(_forkId) returns (uint256 startingBlockNumber){

    }
    

}

contract LiquidityPositionTrackerTracker is Test, ForkHelper{
    

    uint48 constant ONGOING_POSITION_SENTINEL = uint48(0xffffffffffff);


    struct FeeRevenue{
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
    }


    struct All_liquidity{
        uint48 startingBlock;
        uint256 positionInfo;
        FeeRevenue fee_revenue;
       
    }
    // NOTE: This uses the uniswapFoundation/foundationalHooks
    // for conversion to uint160
    struct Pricing{
        uint160 external_price_token0;
        uint160 external_price_token1
        uint160 internal_price_token0;
        uint260 internal_price_token1;
    }

    // TODO: What library helps get this amounts
    // reliably
    struct LiquidityPerToken{
        uint256 liquidityOnToken0;
        uint256 liquidityOnToken1;
    }

    // TODO: Define events for liquidity managent
    event ImpermanentLoss();
    event DivergenceLoss();
    // TODO: These are to be heard

    mapping(bytes32 poolId => mapping(uint256 liquidity_token_id => All_liquidity)) liquidity_position_intel;



    function setUp() public {

    }




    
}




