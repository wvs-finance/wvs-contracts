// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.26;

// import "../ForkTest.sol";
// import "./utils/MockDestinationSimple.sol";
// import "./utils/MockOriginSimple.sol";
// import "../../src/login/Socket.sol";

// contract SocketForkTest is ForkTest{



//     address origin;
//     address destination;


//     address socket;
//     bytes32 mock_origin_event_selector;

//     function setUp() public override{
//         super.setUp();


//         mock_origin_event_selector = keccak256("Stimulus(uint256 indexed)");
//         bytes32 _reactive_salt = pre_deploy_reactive(user);
//         vm.startPrank(user);
//         socket = address(new Socket{salt: _reactive_salt, value: 0.5 ether}());
//         vm.stopPrank();
//         vm.makePersistent(socket, SYSTEM_CONTRACT, NODE);
        

//         (bytes32 _unichain_salt_origin, bytes32 _unichain_salt_destination) = pre_deploy_unichain(user);

//         origin = address(new MockOriginSimple{salt: _unichain_salt_origin}());
//         destination = address(new MockDestinationSimple{salt: _unichain_salt_destination}(SYSTEM_CONTRACT,origin));
//         vm.makePersistent(origin, destination);
//     }

//     function test__fork__socketInit() external{
//         vm.selectFork(reactive_fork);
//         vm.deal(user, 1 ether);
//         vm.startPrank(user);
        
//         ISocket(socket).__init__{value: 1 ether}(
//             UNICHAIN_CHAIN_ID,
//             origin,
//             destination
//         );


//         vm.stopPrank();

//         vm.prank(SYSTEM_CONTRACT);

//         ISocket(socket).subscribe(
//             user,
//             mock_origin_event_selector
//         );

        
//    }

// }

// // //     function uniform_liquidity_amounts(
// // //         uint256 _liquidity_to_provide
// // //     ) internal returns(uint256,uint256){
// // //         (uint160 _low, uint160 _up) = (
// // //             TickMath.getSqrtPriceAtTick(
// // //                 TickMath.minUsableTick(pool_key.tickSpacing)
// // //             ),
// // //             TickMath.getSqrtPriceAtTick(
// // //                 TickMath.maxUsableTick(pool_key.tickSpacing)
// // //             )
// // //         );
// // //         (uint256 amount0_toFund, uint256 amount1_toFund) = (
// // //             SqrtPriceMath.getAmount0Delta(
// // //                 _low,
// // //                 _up,
// // //                 uint128(_liquidity_to_provide),
// // //                 true
// // //             ),
// // //             SqrtPriceMath.getAmount1Delta(
// // //                 _low,
// // //                 _up,
// // //                 uint128(_liquidity_to_provide),
// // //                 true
// // //             )
// // //         );
// // //         return (amount0_toFund, amount1_toFund);

// // //     }


// // //    // NOTE: This is defaulted as uniform liquidity 
// // //    function fund_liquidity(
// // //         address _caller,
// // //         uint256 _liquidity_to_provide
// // //     ) internal returns (uint256 _amount0,uint256 _amount1 ){

// // //         vm.selectFork(unichain_fork);
// // //         assertEq(UNICHAIN_CHAIN_ID, block.chainid);
        
// // //         vm.startPrank(_caller);
 
// // //         (uint256 amount0_toFund, uint256 amount1_toFund) = uniform_liquidity_amounts(_liquidity_to_provide);
          
// // //         IV4Quoter.QuoteExactSingleParams memory _swap_params = IV4Quoter.QuoteExactSingleParams({
// // //             poolKey: pool_key,
// // //             zeroForOne: true,
// // //             exactAmount: uint128(amount1_toFund),
// // //             hookData: Constants.ZERO_BYTES  
// // //         });
// // //         (uint256 _amountIn, uint256 _gasEstimate) = IV4Quoter(QUOTER_V4).quoteExactOutputSingle(
// // //             _swap_params
// // //         );
// // //         vm.deal(_caller, _amountIn + _gasEstimate);

// // //         Plan memory swap_to_usdc = Planner.init();
      

// // //         bytes memory swap_command = abi.encode(
// // //             IV4Router.ExactOutputSingleParams(
// // //                 pool_key,
// // //                 true,
// // //                 uint128(amount1_toFund),
// // //                 uint128(_amountIn),
// // //                 Constants.ZERO_BYTES
// // //             )
// // //         );
// // //         swap_to_usdc = swap_to_usdc.add(
// // //             Actions.SWAP_EXACT_OUT,
// // //             swap_command
// // //         );

// // //         IUniversalRouter(UNIVERSAL_ROUTER).execute(
// // //             swap_to_usdc.actions,
// // //             swap_to_usdc.params,
// // //             uint256(type(uint48).max)
// // //         );

// // //         uint256 usdc_balance = IERC20(Currency.unwrap(pool_key.currency1)).balanceOf(_caller);
// // //         uint256 eth_balance = _caller.balance;
        
// // //         vm.stopPrank();


// // //         assert(usdc_balance == amount1_toFund && eth_balance == amount0_toFund);


// // //         (_amount0, _amount1) = (amount0_toFund, amount1_toFund);



// // //    } 

// // //    function approve_permit2(address _caller) internal{
// // //         vm.selectFork(unichain_fork);
// // //         assertEq(UNICHAIN_CHAIN_ID, block.chainid);
// // //         vm.startPrank(_caller);
// // //         //     PERMIT2,
// // //         // IERC20(Currency.unwrap(pool_key.currency0)).approve(
// // //         //     type(uint256).max
// // //         // );
// // //         // IAllowanceTransfer(PERMIT2).approve(
// // //         //     Currency.unwrap(pool_key.currency0),
// // //         //     endpoint,
// // //         //     type(uint160).max,
// // //         //     type(uint48).max
// // //         // );
// // //         IERC20(Currency.unwrap(pool_key.currency1)).approve(
// // //             PERMIT2,
// // //             type(uint256).max
// // //         );
// // //         IAllowanceTransfer(PERMIT2).approve(
// // //             Currency.unwrap(pool_key.currency1),
// // //             endpoint,
// // //             type(uint160).max,
// // //             type(uint48).max
// // //         );
// // //         vm.stopPrank();
        
// // //    }



// // }