// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "../../src/hedging/HedgeSubscriptionManager.sol";
import "../../src/hedging/HedgeLPMetrics.sol";
import "../fork/ForkUtils.sol";
import "../ForkTest.sol";
import "@uniswap/v4-periphery/test/shared/LiquidityOperations.sol";
import {IUniversalRouter} from "universal-router/contracts/interfaces/IUniversalRouter.sol";
import {Commands} from "universal-router/contracts/libraries/Commands.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {ActionConstants} from "v4-periphery/src/libraries/ActionConstants.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

contract HedgeLPSubscriptionManagerForkTest is ForkTest{

    address hedge_lp_metrics_impl;
    address hedge_subscription_manager;
    address admin;


    function setUp() public override{
        super.setUp();
        vm.selectFork(unichain_fork);
        
        // Ensure USDC_WHALE has enough USDC balance
        deal(USDC, USDC_WHALE, 100_000_000 * 1e6); // 100M USDC
        vm.deal(USDC_WHALE, 100 ether); // Also give ETH for gas and liquidity
        
        hedge_subscription_manager = address(new HedgeSubscriptionManager());
        hedge_lp_metrics_impl = address(new HedgeLPMetrics());
        vm.makePersistent(hedge_subscription_manager, POSITION_MANAGER, hedge_lp_metrics_impl);
        vm.makePersistent(USDC);
        
        // Permits to all contracts interacting with tokens
        vm.startPrank(USDC_WHALE);
        IERC20(USDC).approve(PERMIT2, type(uint256).max);
        IAllowanceTransfer(PERMIT2).approve(USDC, UNIVERSAL_ROUTER, type(uint160).max, type(uint48).max);
        vm.stopPrank();
    }

    function test__fork__subscriptionManagerInit() public{
        IHedgeSubscriptionManager(hedge_subscription_manager).__init__(POSITION_MANAGER);
        assertEq(IHedgeSubscriptionManager(hedge_subscription_manager).lpm(), POSITION_MANAGER);
        address _lp_metrics_factory = IHedgeSubscriptionManager(hedge_subscription_manager).metrics_factory();
        assertNotEq(address(0x00),_lp_metrics_factory);
        assertEq(GenericFactory(_lp_metrics_factory).upgradeAdmin(),hedge_subscription_manager);
        IHedgeSubscriptionManager(hedge_subscription_manager).set_lp_metrics_implementation(hedge_lp_metrics_impl);
        address _lp_metrics_implementation = GenericFactory(_lp_metrics_factory).implementation();
        assertNotEq(_lp_metrics_implementation,address(0x00));
        assertEq(IHedgeLPMetrics(_lp_metrics_implementation).factory(), address(0x00));

    }



    function test__fork__mustSubscribeHedgeMetricsSuccess() external{
        vm.selectFork(unichain_fork);
        __init__();

        
        vm.startPrank(USDC_WHALE);
        
        uint256 _position_token_id = mint_liquidity_default(USDC_WHALE);
        IERC721(POSITION_MANAGER).approve(hedge_subscription_manager, _position_token_id);


        assertEq(USDC_WHALE,IERC721(POSITION_MANAGER).ownerOf(_position_token_id));
        // vm.expectEmit(true, true, true, false, hedge_subscription_manager);
        
        IHedgeSubscriptionManager(hedge_subscription_manager).subscribe(
            _position_token_id,
             USDC_WHALE
        );
        address _position_lens = IHedgeSubscriptionManager(hedge_subscription_manager).position_metrics_lens(_position_token_id);
        assertEq(hedge_subscription_manager,IHedgeLPMetrics(_position_lens).factory());

        vm.stopPrank();

     }   

    function __init__() internal{
        IHedgeSubscriptionManager(hedge_subscription_manager).__init__(POSITION_MANAGER);
        IHedgeSubscriptionManager(hedge_subscription_manager).set_lp_metrics_implementation(hedge_lp_metrics_impl);
        
    }


    function mint_liquidity_default(address _minter) internal returns(uint256 _tokenId){
        // Get the expected tokenId before minting
        _tokenId = IPositionManager(POSITION_MANAGER).nextTokenId();
        
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(ETH),  // ETH address(0)
            currency1: Currency.wrap(USDC),
            fee: 500,  // 0.05% = 500 / 1_000_000
            tickSpacing: 10,  // Standard tick spacing for 0.05% fee
            hooks: IHooks(address(0))  // No hooks
        });
        
        // Use a wide tick range (full range approximately)
        // Ticks must be multiples of tickSpacing (10)
        int24 tickLower = -887270;  // Close to MIN_TICK, rounded to nearest multiple of 10
        int24 tickUpper = 887270;   // Close to MAX_TICK, rounded to nearest multiple of 10
        
        // Default liquidity amount (can be adjusted)
        uint256 liquidity = 1e10;  // Liquidity units
        
        // Calculate and fund token amounts
        // For full-range positions, use a default price since exact price doesn't matter much
        (uint160 sqrtPriceX96,,,) = StateLibrary.getSlot0(
            IPoolManager(IPositionManager(POSITION_MANAGER).poolManager()),
            poolKey.toId()
        );
 
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            uint128(liquidity)
        );
        
        // Transfer tokens to PositionManager BEFORE calling router
        // Transfer USDC (amount1) - add buffer for rounding
        uint256 usdcAmount = amount1 + (amount1 / 100); // Add 1% buffer
        IERC20(USDC).transfer(POSITION_MANAGER, usdcAmount);
        
        // Fund ETH for the minter (will be sent with the execute call)
        // For full-range positions, use a fixed large amount
        uint256 ethAmount = 10 ether; // Fixed large amount for full-range
        vm.deal(_minter, ethAmount + 1 ether); // Add extra for gas
        
        // Build the plan using Planner
        Plan memory plan = Planner.init();
        
        // Add MINT_POSITION action
        plan = plan.add(
            Actions.MINT_POSITION,
            abi.encode(
                poolKey,
                tickLower,
                tickUpper,
                liquidity,
                type(uint128).max,  // amount0Max - max slippage tolerance
                type(uint128).max,  // amount1Max - max slippage tolerance
                _minter,            // owner
                bytes("")           // hookData - empty
            )
        );
        
        // Add SETTLE actions to settle the deltas
        // Use OPEN_DELTA (0) to settle the open delta from the mint operation
        plan = plan.add(Actions.SETTLE, abi.encode(Currency.wrap(USDC), ActionConstants.OPEN_DELTA, false));
        plan = plan.add(Actions.SETTLE, abi.encode(Currency.wrap(ETH), ActionConstants.OPEN_DELTA, false));
        
        // Add SWEEP actions to return excess tokens to minter
        plan = plan.add(Actions.SWEEP, abi.encode(USDC, _minter));
        plan = plan.add(Actions.SWEEP, abi.encode(ETH, _minter));
        
        // Finalize the plan to get encoded unlockData
        bytes memory unlockData = plan.encode();
        
        // Encode the modifyLiquidities call
        bytes memory modifyLiquiditiesCalldata = abi.encodeWithSelector(
            IPositionManager.modifyLiquidities.selector,
            unlockData,
            type(uint256).max  // deadline - max uint256
        );
        
        // Build Universal Router commands and inputs
        bytes memory commands = abi.encodePacked(uint8(Commands.V4_POSITION_MANAGER_CALL));
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = modifyLiquiditiesCalldata;
        
        // Execute via Universal Router
        // Send ETH value with the call for native ETH
        // For full-range positions, send a fixed large amount
        uint256 ethValue = 10 ether; // Fixed large amount for full-range
        IUniversalRouter(UNIVERSAL_ROUTER).execute{value: ethValue}(
            commands,
            inputs,
            type(uint256).max  // deadline
        );
        
        return _tokenId;
    }


}


