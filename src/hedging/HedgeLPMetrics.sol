// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISubscriber} from "@uniswap/v4-periphery/src/interfaces/ISubscriber.sol";
import "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

import "./types/Metrics.sol";
import {IComponent} from "euler-vault-kit/src/GenericFactory/GenericFactory.sol";

interface IHedgeLPMetrics{
    event MetricsData(uint256 indexed_token_id, uint80 indexed, bytes _data);
    function get_metrics(uint80) external returns(bytes memory);
    function factory() external returns(address);
}
// NOTE: token id gives metrics

contract HedgeLPMetrics is ISubscriber, IHedgeLPMetrics, IComponent{
    using StateLibrary for IPoolManager;
    using PositionInfoLibrary for PositionInfo;

    bytes32 constant HEDGE_METRICS_POSITION = keccak256("wvs.hedging.lp-metrics");

    struct HedgeLPMetricsStorage{
        address factory;
        mapping(uint80 time_key => bytes _metrics) lp_metrics;
    }

    function getStorage() internal pure returns (HedgeLPMetricsStorage storage s) {
        bytes32 position = HEDGE_METRICS_POSITION;
        assembly ("memory-safe"){
            s.slot := position
        }
    }

    function get_metrics(uint80 _time_key) public view returns(bytes memory){
        HedgeLPMetricsStorage storage $ = getStorage();
        return $.lp_metrics[_time_key];
    }

    function factory() public view returns(address){
        HedgeLPMetricsStorage storage $ = getStorage();
        return $.factory;
    }

    function initialize(address creator) external{
        HedgeLPMetricsStorage storage $ = getStorage();
        $.factory = creator;
    }

    /// @notice Called when a position subscribes to this subscriber contract
    /// @param tokenId the token ID of the position
    /// @param data additional data passed in by the caller

    function notifySubscribe(uint256 tokenId, bytes memory data) external{
        HedgeLPMetricsStorage storage $ = getStorage();
        
        (
            PoolKey memory _pool_key,
            PositionInfo _position_info,
            uint128 _position_liquidity,
            address _lp_account,
            address _pool_manager
        ) = abi.decode(
            data,
            (PoolKey, PositionInfo, uint128, address, address)
        );

        PoolId pool_id = PoolIdLibrary.toId(_pool_key);

        // NOTE: nOW IT NEEDS TO GET THE INITIAL DATA TO get the HODL and LP PORTAFOLIO
        // metrics at t_0 as well as pricing. This is
        (,uint256 position_feeGrowthInside0LastX128, uint256 position_feeGrowthInside1LastX128) = IPoolManager(
            _pool_manager
        ).getPositionInfo(
            pool_id,
            msg.sender, //lpm
            _position_info.tickLower(),
            _position_info.tickUpper(),
            bytes32(tokenId)
        );

        (uint160 _internal_sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee) = IPoolManager(
            _pool_manager
        ).getSlot0(pool_id);

        (
            uint128 current_tick_liquidityGross,
            int128  current_tick_liquidityNet,
            uint256 current_tick_feeGrowthOutside0X128,
            uint256 current_tick_feeGrowthOutside1X128

        ) = IPoolManager(_pool_manager).getTickInfo(
            pool_id,
            tick
        );
        uint80 _time_key = PackedTimeDataLib.build(uint48(block.timestamp),uint32(block.number));
        // uint160 _external_price_X96 = 
        bytes memory _metrics_data =abi.encode(
            _position_liquidity,
            position_feeGrowthInside0LastX128,
            position_feeGrowthInside1LastX128,
            _internal_sqrtPriceX96,
            tick,
            protocolFee,
            lpFee,
            current_tick_liquidityGross,
            current_tick_liquidityNet,
            current_tick_feeGrowthOutside0X128,
            current_tick_feeGrowthOutside1X128
        ); 
        $.lp_metrics[_time_key] = _metrics_data;

        emit MetricsData(tokenId, _time_key, _metrics_data);


        // // NOTE: Volatility metrics
        // NOTE: Volume metrics
        
    }

    /// @notice Called when a position unsubscribes from the subscriber
    /// @dev This call's gas is capped at `unsubscribeGasLimit` (set at deployment)
    /// @dev Because of EIP-150, solidity may only allocate 63/64 of gasleft()
    /// @param tokenId the token ID of the position
    function notifyUnsubscribe(uint256 tokenId) external{}

    /// @notice Called when a position is burned
    /// @param tokenId the token ID of the position
    /// @param owner the current owner of the tokenId
    /// @param info information about the position
    /// @param liquidity the amount of liquidity decreased in the position, may be 0
    /// @param feesAccrued the fees accrued by the position if liquidity was decreased
    function notifyBurn(uint256 tokenId, address owner, PositionInfo info, uint256 liquidity, BalanceDelta feesAccrued)
        external{}

    /// @notice Called when a position modifies its liquidity or collects fees
    /// @param tokenId the token ID of the position
    /// @param liquidityChange the change in liquidity on the underlying position
    /// @param feesAccrued the fees to be collected from the position as a result of the modifyLiquidity call
    /// @dev Note that feesAccrued can be artificially inflated by a malicious user
    /// Pools with a single liquidity position can inflate feeGrowthGlobal (and consequently feesAccrued) by donating to themselves;
    /// atomically donating and collecting fees within the same unlockCallback may further inflate feeGrowthGlobal/feesAccrued
    function notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta feesAccrued) external{}

}