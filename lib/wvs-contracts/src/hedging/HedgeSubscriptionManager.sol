// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {INotifier} from "@uniswap/v4-periphery/src/interfaces/INotifier.sol";
import {GenericFactory, IComponent} from "euler-vault-kit/src/GenericFactory/GenericFactory.sol";
import "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";

interface IHedgeSubscriptionManager{
    event Subscribed (address indexed _lp_account, uint256 indexed token_id, address indexed _lp_position_lens);
    function __init__(address _lpm) external;
    function subscribe(uint256 _position_id,address _lp_account) external;
    function set_lp_metrics_implementation(address _new_implementation) external;
    function lpm() external returns(address);
    function metrics_factory() external returns(address);
    function position_metrics_lens(uint256 _token_id) external returns(address);
    function position_lp_account(uint256 _position_token_id) external returns(address _lp_account);
    
}

contract HedgeSubscriptionManager is IHedgeSubscriptionManager{
    
    
    bytes32 constant HEDGE_SUBSCRIPTION_MANAGER_POSITION = keccak256("wvs.hedging.subscription-manager");
    
    struct HedgeSubscriptionManagerStorage{
        address lpm;
        address lp_metrics_factory;
        mapping(uint256 token_id => address lp_metrics) position_metrics_lens;
        mapping(uint256 token_id => address lp_account) position_lp_accounts;
    }

  

    function getStorage() internal pure returns (HedgeSubscriptionManagerStorage storage s) {
        bytes32 position = HEDGE_SUBSCRIPTION_MANAGER_POSITION;
        assembly ("memory-safe"){
            s.slot := position
        }
    }

    function position_lp_accounts(uint256 _position_token_id) public view returns(address _lp_account){
        HedgeSubscriptionManagerStorage storage $ = getStorage();
        _lp_account = $.position_lp_accounts[_position_token_id];
    }

    function __init__(address _lpm) external{
        HedgeSubscriptionManagerStorage storage $ = getStorage();
        $.lpm = _lpm;
        $.lp_metrics_factory = address(new GenericFactory(address(this)));
    }


    function lpm() public view returns(address){
        HedgeSubscriptionManagerStorage storage $ = getStorage();
        return $.lpm;
    }

    function position_metrics_lens(uint256 _token_id) public view returns(address){
        HedgeSubscriptionManagerStorage storage $ = getStorage();
        return $.position_metrics_lens[_token_id];
    }

    function metrics_factory() public view returns(address){
        HedgeSubscriptionManagerStorage storage $ = getStorage();
        return $.lp_metrics_factory;
    }


    function set_lp_metrics_implementation(address _new_implementation) external{
        GenericFactory(metrics_factory()).setImplementation(_new_implementation);
    }

    // TODO: 
    //- THis requires approval
    //- THis call only be called once per position_token life cycle
    // - The msg.sender needs to be the Destination contract and only after a 
    // on_log call
    // - After protected it can not subscribe twice to the same position if position
    // is live

    function subscribe(uint256 _token_id, address _lp_account) external{
        HedgeSubscriptionManagerStorage storage $ = getStorage();

        address _lp_metrics_lens = GenericFactory(metrics_factory()).createProxy(
            GenericFactory(metrics_factory()).implementation(),
            false,
            bytes("")
        );


        (PoolKey memory _pool_key, PositionInfo _position_info) = IPositionManager(
            lpm()
        ).getPoolAndPositionInfo(_token_id);
        uint128 _position_liquidity = IPositionManager(
            lpm()
        ).getPositionLiquidity(_token_id);

        INotifier(lpm()).subscribe(
            _token_id,
            _lp_metrics_lens,
            abi.encode(
                _pool_key,
                _position_info,
                _position_liquidity,
                _lp_account,
                address(IPositionManager(lpm()).poolManager())
            )
        );
        $.position_lp_accounts[_token_id] = _lp_account;
        $.position_metrics_lens[_token_id] = _lp_metrics_lens;
        IComponent(_lp_metrics_lens).initialize(address(this));


        emit Subscribed(_lp_account, _token_id, _lp_metrics_lens);

    }

}
