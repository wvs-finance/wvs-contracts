// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {INotifier} from "@uniswap/v4-periphery/src/interfaces/INotifier.sol";
import {GenericFactory} from "euler-vault-kit/src/GenericFactory/GenericFactory.sol";
import "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";

interface IHedgeSubscriptionManager{
    function __init__(address _lpm, address _generic_factory) external;
    function subscribe(uint256 _position_id,address _lp_account) external;
    function lpm() external returns(address);
    function metrics_factory() external returns(address);
}

contract HedgeSubscriptionManager is IHedgeSubscriptionManager{
    
    
    bytes32 constant HEDGE_SUBSCRIPTION_MANAGER_POSITION = keccak256("wvs.hedging.subscription-manager");
    
    struct HedgeSubscriptionManagerStorage{
        address lpm;
        address lp_metrics_factory;
    }

  

    function getStorage() internal pure returns (HedgeSubscriptionManagerStorage storage s) {
        bytes32 position = HEDGE_SUBSCRIPTION_MANAGER_POSITION;
        assembly ("memory-safe"){
            s.slot := position
        }
    }

    function __init__(address _lpm, address _generic_factory) external{
        HedgeSubscriptionManagerStorage storage $ = getStorage();
        $.lpm = _lpm;
        $.lp_metrics_factory = _generic_factory;
    }


    function lpm() public view returns(address){
        HedgeSubscriptionManagerStorage storage $ = getStorage();
        return $.lpm;
    }

    function metrics_factory() public view returns(address){
        HedgeSubscriptionManagerStorage storage $ = getStorage();
        $.lp_metrics_factory;
    }


    function set_lp_metrics_implementation(address _new_implementation) external{
        GenericFactory(metrics_factory()).setImplementation(_new_implementation);
    }



    // TODO: This requires approval
    function subscribe(uint256 _token_id, address _lp_account) external{
        address _lp_hedge_manager = GenericFactory(metrics_factory()).createProxy(
            GenericFactory(metrics_factory()).implementation(),
            false,
            abi.encode(_lp_account)
        );
        (PoolKey memory _pool_key, PositionInfo _position_info) = IPositionManager(
            lpm()
        ).getPoolAndPositionInfo(_token_id);
        uint128 _position_liquidity = IPositionManager(
            lpm()
        ).getPositionLiquidity(_token_id);

        INotifier(lpm()).subscribe(
            _token_id,
            _lp_hedge_manager,
            abi.encode(
                _pool_key,
                _position_info,
                _position_liquidity,
                address(IPositionManager(lpm()).poolManager())
            )
        );

    }

}
