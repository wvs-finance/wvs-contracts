# Weighted Variance Swaps Implementation Plan

## Executive Summary

This document outlines the implementation plan for a weighted variance swap (WVS) hedge mechanism for Uniswap V3 liquidity providers. The system enables LPs to dynamically hedge their positions against impermanent loss using variance swaps, with integration to the VIX protocol for pricing, minting, and market operations.

## System Overview

### Core Objective
Enable Uniswap V3 LPs to hedge their liquidity positions against impermanent loss through weighted variance swaps, dynamically managed via reactive strategies that adapt to market conditions until maturity.

### Key Components
1. **Uniswap V3 Hook Integration**: Tracks LP positions and calculates HODL equivalent portfolios
2. **Impermanent Loss Calculator**: Computes IL on every swap event
3. **VIX Protocol Integration**: Interfaces with VIX for pricing, minting, and trading variance swap instruments
4. **Reactive Strategy Framework**: Dynamic hedging strategies that adjust positions based on market conditions
5. **ERC1155 Claims System**: Tracks hedge positions and strategy performance
6. **Maturity Management**: TimeLockControllers enforce hedge maturity and settlement

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Uniswap V3 Pool                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         WVS Hook (afterSwap, afterAddLiquidity)      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Position Tracker & IL Calculator               │
│  - Tracks LP positions (HODL portfolios)                   │
│  - Calculates impermanent loss on swaps                     │
│  - Computes optimal tick ranges based on volatility         │
│  - Emits LP_Portfolio and Hodl_Portfolio events            │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Hedge Manager                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Strategy Registry & Factory                   │  │
│  │  - BaseStrategy template                              │  │
│  │  - Strategy catalog (deployed strategies)            │  │
│  │  - Strategy instantiation                             │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Hedge Lifecycle Manager                       │  │
│  │  - Hedge creation (maturity, parameters)              │  │
│  │  - Dynamic rebalancing triggers                       │  │
│  │  - Settlement coordination                            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              VIX Protocol Integration Layer                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         IVix Interface Adapter                        │  │
│  │  - deploy2Currency() for HIGH/LOW IV tokens          │  │
│  │  - Pricing queries                                    │  │
│  │  - Minting operations                                 │  │
│  │  - Market operations                                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              ERC1155 Claims & Metadata System               │
│  - Strategy performance tracking                           │
│  - Hedge position claims                                   │
│  - Dashboard metadata                                      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              TimeLockController (Maturity)                  │
│  - Enforces hedge maturity                                 │
│  - Settlement triggers                                      │
│  - Strategy execution windows                              │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Core Infrastructure (Foundation)
**Goal**: Establish basic tracking and calculation infrastructure

#### 1.1 Uniswap V3 Hook Implementation
**File**: `contracts/src/hooks/WVSHook.sol`

**Responsibilities**:
- Implement `afterAddLiquidity` hook
- Implement `afterSwap` hook
- Track LP positions and HODL equivalent portfolios
- Calculate price impacts and impermanent loss

**Key Functions**:
```solidity
function afterAddLiquidity(
    ModifyLiquidityParams calldata liquidityPosition
) external returns (bytes4);

function afterSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata data
) external returns (bytes4, int128);
```

**Data Structures**:
```solidity
struct HodlPortfolio {
    uint128 token0;
    uint128 token1;
    uint160 initialPrice;
    bool isFinal;
}

mapping(uint256 => HodlPortfolio) public lp_hodl_equivalent_portfolio;
```

**Events**:
- `HodlPortfolio(uint256 positionTokenId, HodlPortfolio portfolio)`
- `LP_Portfolio(uint256 positionTokenId, uint160 priceImpact, uint160 impermanentLoss)`

#### 1.2 External Oracle Interface
**File**: `contracts/src/interfaces/IExternalOracle.sol`

**Required Functions**:
- `getSafePrice()` → Returns safe TWAP price
- `getVolatility()` → Returns volatility data
- `getOptimalTicks()` → Returns optimal tick range based on volatility

#### 1.3 Price Impact & IL Calculation Library
**File**: `contracts/src/libraries/SqrtPriceLibrary.sol`

**Functions**:
- `priceImpact(uint160 price0, uint160 price1) → uint160`
- `impermanentLoss(HodlPortfolio memory portfolio, uint160 currentPrice) → uint256`
- `calculateStraddle(uint160 price, uint256 volatility) → (uint256 call, uint256 put)`

### Phase 2: VIX Integration Layer
**Goal**: Integrate with VIX protocol for variance swap operations

#### 2.1 VIX Adapter Contract
**File**: `contracts/src/integrations/VixAdapter.sol`

**Responsibilities**:
- Wrap VIX protocol calls
- Handle HIGH/LOW IV token deployment
- Manage pricing queries
- Coordinate minting operations

**Key Functions**:
```solidity
function deployVixTokens(
    address poolAddress,
    string[2] memory tokenNames,
    string[2] memory tokenSymbols
) external returns (address[2] memory ivTokenAddresses);

function getVixPrice(address ivToken) external view returns (uint256);

function mintVixPosition(
    address ivToken,
    uint256 amount,
    uint48 maturity
) external returns (uint256 positionId);
```

#### 2.2 WVS to VIX Mapping
**File**: `contracts/src/libraries/WVSVixMapper.sol`

**Responsibilities**:
- Map weighted variance swap parameters to VIX HIGH/LOW token parameters
- Calculate notional equivalents
- Handle maturity conversions

**Functions**:
```solidity
function mapWVSToVix(
    HedgeParams memory wvsParams,
    uint256 lpPositionValue
) external pure returns (VixParams memory);

function calculateVixNotional(
    uint256 wvsNotional,
    uint160 currentVolatility
) external pure returns (uint256);
```

### Phase 3: Hedge Management System
**Goal**: Core hedge lifecycle management

#### 3.1 Hedge Manager (Enhanced)
**File**: `contracts/src/HedgeManager.sol`

**Responsibilities**:
- Manage hedge creation and lifecycle
- Coordinate with VIX protocol
- Track active hedges
- Handle settlement

**Data Structures**:
```solidity
struct Hedge {
    uint256 positionTokenId;      // LP position identifier
    uint48 maturity;               // Maturity timestamp
    uint256 notional;              // Hedge notional
    address strategy;              // Strategy contract address
    address vixHighToken;          // VIX HIGH token address
    address vixLowToken;           // VIX LOW token address
    uint256 vixPositionId;         // VIX protocol position ID
    HedgeStatus status;            // Current status
    uint256 createdAt;             // Creation timestamp
}

enum HedgeStatus {
    Active,
    Settled,
    Cancelled
}

mapping(uint256 => Hedge) public hedges;
mapping(uint256 => uint256[]) public positionHedges; // positionTokenId => hedgeIds[]
```

**Key Functions**:
```solidity
function createHedge(
    uint256 positionTokenId,
    HedgeParams calldata params
) external returns (uint256 hedgeId);

function queryHedgeParameters(
    uint256 positionTokenId,
    uint48 maturity
) external view returns (HedgeQuote memory);

function settleHedge(uint256 hedgeId) external;
```

#### 3.2 Hedge Parameters & Quoting
**File**: `contracts/src/libraries/HedgeQuoter.sol`

**Responsibilities**:
- Calculate required hedge parameters
- Quote hedge costs
- Determine optimal maturity
- Calculate notional requirements

**Functions**:
```solidity
function quoteHedge(
    uint256 positionTokenId,
    uint48 maturity,
    uint160 currentVolatility
) external view returns (HedgeQuote memory);

struct HedgeQuote {
    uint256 notional;
    uint256 estimatedCost;
    uint256 vixHighAmount;
    uint256 vixLowAmount;
    uint256 requiredCollateral;
}
```

### Phase 4: Reactive Strategy Framework
**Goal**: Dynamic hedging strategies

#### 4.1 Base Strategy Template
**File**: `contracts/src/strategies/BaseStrategy.sol`

**Abstract Contract**:
```solidity
abstract contract BaseStrategy {
    // Strategy metadata
    string public name;
    string public description;
    
    // Maturity enforcement
    ITimeLockController public immutable timelock;
    
    // Core strategy interface
    function shouldRebalance(
        uint256 hedgeId,
        MarketData calldata marketData
    ) external view virtual returns (bool, RebalanceAction memory);
    
    function executeRebalance(
        uint256 hedgeId,
        RebalanceAction calldata action
    ) external virtual;
    
    function canExecute(uint256 hedgeId) external view virtual returns (bool);
    
    // Events
    event StrategyExecuted(uint256 indexed hedgeId, RebalanceAction action);
    event RebalanceTriggered(uint256 indexed hedgeId, string reason);
}
```

**Data Structures**:
```solidity
struct MarketData {
    uint160 currentPrice;
    uint160 volatility;
    uint256 timeToMaturity;
    uint256 currentIL;
    uint256 portfolioValue;
}

struct RebalanceAction {
    ActionType action;
    uint256 vixHighDelta;
    uint256 vixLowDelta;
    bytes data;
}

enum ActionType {
    IncreaseHedge,
    DecreaseHedge,
    Rebalance,
    NoAction
}
```

#### 4.2 Strategy Catalog
**File**: `contracts/src/strategies/StrategyRegistry.sol`

**Responsibilities**:
- Register deployed strategies
- Enable strategy discovery
- Manage strategy metadata
- Handle strategy upgrades

**Functions**:
```solidity
function registerStrategy(
    address strategy,
    string memory name,
    string memory description
) external;

function getAvailableStrategies() external view returns (StrategyInfo[] memory);

function deployStrategy(
    bytes memory initData
) external returns (address strategy);
```

#### 4.3 Example Strategies

**4.3.1 Static Hedge Strategy**
**File**: `contracts/src/strategies/StaticHedgeStrategy.sol`

- Maintains constant hedge ratio
- No rebalancing
- Simple implementation for testing

**4.3.2 Dynamic Delta Hedge Strategy**
**File**: `contracts/src/strategies/DynamicDeltaHedgeStrategy.sol`

- Rebalances based on IL changes
- Adjusts hedge ratio dynamically
- Threshold-based triggers

**4.3.3 Volatility-Based Strategy**
**File**: `contracts/src/strategies/VolatilityBasedStrategy.sol`

- Adjusts hedge based on volatility regime
- Increases hedge in high volatility
- Decreases in low volatility

### Phase 5: ERC1155 Claims System
**Goal**: Track positions and enable dashboard integration

#### 5.1 Claims Contract
**File**: `contracts/src/claims/HedgeClaims.sol`

**Responsibilities**:
- Mint ERC1155 tokens for hedge positions
- Track strategy performance
- Provide metadata for dashboard

**Implementation**:
```solidity
contract HedgeClaims is ERC1155 {
    // Token ID structure: keccak256(hedgeId, "hedge")
    
    mapping(uint256 => ClaimMetadata) public claimMetadata;
    
    struct ClaimMetadata {
        uint256 hedgeId;
        uint256 positionTokenId;
        uint48 maturity;
        uint256 initialValue;
        uint256 currentValue;
        uint256 pnl;
        string strategyName;
    }
    
    function mintClaim(uint256 hedgeId) external returns (uint256 tokenId);
    
    function updateClaimMetadata(
        uint256 tokenId,
        ClaimMetadata calldata metadata
    ) external;
    
    function getClaimPerformance(uint256 tokenId) 
        external 
        view 
        returns (ClaimMetadata memory);
}
```

#### 5.2 Metadata Structure
**File**: `contracts/src/claims/ClaimMetadata.sol`

**JSON Metadata Schema**:
```json
{
  "name": "WVS Hedge Position",
  "description": "Weighted Variance Swap Hedge",
  "properties": {
    "hedgeId": "uint256",
    "positionTokenId": "uint256",
    "maturity": "uint48",
    "strategy": "string",
    "initialValue": "uint256",
    "currentValue": "uint256",
    "pnl": "int256",
    "status": "string"
  }
}
```

### Phase 6: Maturity & Settlement
**Goal**: Enforce maturity and handle settlement

#### 6.1 TimeLockController Integration
**File**: `contracts/src/maturity/MaturityManager.sol`

**Responsibilities**:
- Enforce hedge maturity via TimeLockController
- Trigger settlement at maturity
- Handle early settlement requests
- Manage settlement windows

**Implementation**:
```solidity
contract MaturityManager {
    ITimeLockController public immutable timelock;
    
    mapping(uint256 => uint256) public hedgeMaturity; // hedgeId => maturity timestamp
    
    function scheduleSettlement(uint256 hedgeId) external;
    
    function executeSettlement(uint256 hedgeId) external;
    
    function canSettle(uint256 hedgeId) external view returns (bool);
}
```

#### 6.2 Settlement Logic
**File**: `contracts/src/settlement/SettlementEngine.sol`

**Responsibilities**:
- Calculate final hedge PnL
- Coordinate with VIX protocol for settlement
- Transfer funds
- Update claim metadata
- Handle disputes

**Functions**:
```solidity
function settleHedge(uint256 hedgeId) external returns (SettlementResult memory);

struct SettlementResult {
    uint256 finalPnL;
    uint256 vixSettlementAmount;
    bool success;
    string reason;
}
```

## Contract Structure

```
contracts/
├── src/
│   ├── hooks/
│   │   └── WVSHook.sol                    # Uniswap V3 hook implementation
│   ├── integrations/
│   │   ├── VixAdapter.sol                 # VIX protocol adapter
│   │   └── IVix.sol                       # VIX interface (existing)
│   ├── strategies/
│   │   ├── BaseStrategy.sol               # Base strategy template
│   │   ├── StrategyRegistry.sol          # Strategy catalog
│   │   ├── StaticHedgeStrategy.sol       # Example: Static hedge
│   │   ├── DynamicDeltaHedgeStrategy.sol # Example: Dynamic delta
│   │   └── VolatilityBasedStrategy.sol   # Example: Vol-based
│   ├── claims/
│   │   ├── HedgeClaims.sol               # ERC1155 claims contract
│   │   └── ClaimMetadata.sol             # Metadata structures
│   ├── maturity/
│   │   └── MaturityManager.sol           # TimeLockController integration
│   ├── settlement/
│   │   └── SettlementEngine.sol          # Settlement logic
│   ├── libraries/
│   │   ├── SqrtPriceLibrary.sol           # Price calculations
│   │   ├── WVSVixMapper.sol              # WVS to VIX mapping
│   │   └── HedgeQuoter.sol               # Hedge quoting
│   ├── interfaces/
│   │   ├── IExternalOracle.sol          # External oracle interface
│   │   └── integrations/
│   │       └── IVix.sol                  # VIX interface (existing)
│   └── HedgeManager.sol                  # Main hedge manager (enhanced)
├── test/
│   ├── hooks/
│   │   └── WVSHook.t.sol
│   ├── strategies/
│   │   └── BaseStrategy.t.sol
│   └── integration/
│       └── HedgeFlow.t.sol
└── script/
    ├── DeployHedgeManager.s.sol
    └── DeployStrategies.s.sol
```

## Integration Points

### VIX Protocol Integration

#### Interface Requirements
The system integrates with VIX protocol through the `IVix` interface located at `contracts/lib/vix/`. Key integration points:

1. **Token Deployment**:
   ```solidity
   function deploy2Currency(
       address deriveToken,
       string[2] memory _tokenName,
       string[2] memory _tokenSymbol,
       address _poolAddress
   ) public returns(address[2] memory);
   ```

2. **Pricing**: Query VIX protocol for HIGH/LOW IV token prices
3. **Minting**: Create positions in VIX protocol
4. **Market Operations**: Execute trades through VIX protocol

#### Integration Flow
```
LP Creates Hedge
    ↓
HedgeManager queries parameters
    ↓
VixAdapter.deployVixTokens() (if needed)
    ↓
VixAdapter.getVixPrice()
    ↓
Calculate required amounts
    ↓
VixAdapter.mintVixPosition()
    ↓
Track position in HedgeManager
    ↓
Strategy executes rebalancing via VixAdapter
    ↓
Settlement via VixAdapter
```

### Uniswap V3 Integration

#### Hook Implementation
- **afterAddLiquidity**: Track new LP positions, initialize HODL portfolios
- **afterSwap**: Calculate IL, trigger rebalancing checks, emit events

#### Data Flow
```
Uniswap V3 Swap Event
    ↓
WVSHook.afterSwap()
    ↓
Calculate IL for affected positions
    ↓
Emit LP_Portfolio event
    ↓
Strategy checks if rebalancing needed
    ↓
Execute rebalance via VixAdapter
```

## Key Algorithms

### 1. HODL Portfolio Calculation
```solidity
function calculateHodlPortfolio(
    uint256 positionTokenId,
    uint160 initialPrice,
    uint128 liquidity0,
    uint128 liquidity1
) internal pure returns (HodlPortfolio memory) {
    return HodlPortfolio({
        token0: liquidity0,
        token1: liquidity1,
        initialPrice: initialPrice,
        isFinal: false
    });
}
```

### 2. Impermanent Loss Calculation
Based on Fukasawa 2022 (page 4), calculate IL using:
- Initial portfolio value (HODL)
- Current portfolio value (LP position)
- Price impact relative to initial price

### 3. Weighted Variance Calculation
For WVS, calculate weighted variance using:
- Optimal tick range based on volatility
- Position weight within range
- Variance accumulation over time

### 4. Strategy Rebalancing Logic
```solidity
function shouldRebalance(
    uint256 hedgeId,
    MarketData calldata marketData
) external view returns (bool, RebalanceAction memory) {
    Hedge memory hedge = hedges[hedgeId];
    
    // Check maturity
    if (block.timestamp >= hedge.maturity) {
        return (false, RebalanceAction(ActionType.NoAction, 0, 0, ""));
    }
    
    // Strategy-specific logic
    return strategy.shouldRebalance(hedgeId, marketData);
}
```

## Security Considerations

### 1. Access Control
- Hook functions: Only callable by Uniswap V3 pool
- Hedge creation: Only position owner
- Strategy execution: Only registered strategies
- Settlement: TimeLockController enforced

### 2. Reentrancy Protection
- Use ReentrancyGuard on all state-changing functions
- Follow checks-effects-interactions pattern

### 3. Oracle Security
- Use TWAP for price data
- Implement price deviation checks
- Circuit breakers for extreme volatility

### 4. Maturity Enforcement
- TimeLockController prevents early settlement
- Maturity timestamps immutable after hedge creation
- Settlement window enforcement

### 5. Strategy Validation
- Only registered strategies can execute
- Strategy execution bounded by maturity
- Strategy cannot modify hedge parameters

## Testing Strategy

### Unit Tests
1. **WVSHook**: Test IL calculations, HODL portfolio tracking
2. **VixAdapter**: Test VIX protocol integration, error handling
3. **Strategies**: Test rebalancing logic, edge cases
4. **Settlement**: Test PnL calculations, edge cases

### Integration Tests
1. **End-to-End Hedge Flow**: Create → Rebalance → Settle
2. **VIX Integration**: Test actual VIX protocol calls
3. **Uniswap V3 Integration**: Test hook execution in pool context
4. **Strategy Execution**: Test multiple strategies simultaneously

### Fuzz Testing
- Random market data inputs
- Extreme volatility scenarios
- Edge cases in IL calculations

## Deployment Plan

### Phase 1: Core Contracts
1. Deploy WVSHook
2. Deploy ExternalOracle (or integrate existing)
3. Deploy HedgeManager
4. Deploy VixAdapter

### Phase 2: Strategy Framework
1. Deploy BaseStrategy (as template)
2. Deploy StrategyRegistry
3. Deploy example strategies (Static, Dynamic, Volatility-based)

### Phase 3: Claims & Settlement
1. Deploy HedgeClaims (ERC1155)
2. Deploy MaturityManager
3. Deploy SettlementEngine

### Phase 4: Integration
1. Configure TimeLockController
2. Register strategies
3. Connect to VIX protocol
4. Enable hooks on Uniswap V3 pools

## Dependencies

### External Contracts
- **Uniswap V3**: Pool contracts, NonfungiblePositionManager
- **VIX Protocol**: `contracts/lib/vix/` (vixdex)
- **TimeLockController**: OpenZeppelin or custom implementation
- **External Oracle**: Price and volatility oracle

### Libraries
- OpenZeppelin: AccessControl, ReentrancyGuard, ERC1155
- Uniswap V3: Core libraries, Math libraries
- Custom: SqrtPriceLibrary, WVSVixMapper, HedgeQuoter

## UI Dependencies

As specified in `client2/package.json`:
- `vixdex-interface`: VIX protocol UI components
- `vixdex-landing-page`: Landing page components
- `greekfi-frontpage`: Additional UI components
- `greekfi-protocol`: Protocol integration components

## Success Metrics

1. **Functional**:
   - LPs can create hedges successfully
   - Strategies execute rebalancing correctly
   - Settlement occurs at maturity
   - ERC1155 claims minted and tracked

2. **Performance**:
   - Hook execution gas cost < 100k gas
   - Rebalancing execution < 200k gas
   - Settlement execution < 150k gas

3. **Integration**:
   - VIX protocol integration seamless
   - Uniswap V3 hook integration stable
   - TimeLockController enforces maturity

## Next Steps

1. **Immediate**:
   - Review and refine this plan
   - Set up development environment
   - Initialize contract structure

2. **Short-term** (Week 1-2):
   - Implement Phase 1 (Core Infrastructure)
   - Write unit tests for core components
   - Integrate with VIX protocol interface

3. **Medium-term** (Week 3-4):
   - Implement Phase 2-3 (VIX Integration & Hedge Management)
   - Deploy test strategies
   - Integration testing

4. **Long-term** (Week 5-6):
   - Implement Phase 4-6 (Strategies, Claims, Settlement)
   - End-to-end testing
   - Security audit preparation

## References

- **Fukasawa 2022**: Weighted variance swaps and IL hedging
- **Uniswap V3 Core**: Tick-based pricing, liquidity mechanics
- **VIX Protocol**: HIGH/LOW IV token mechanics
- **LP-derivatives-plan.md**: System design document
- **LP-hedge-user-story.md**: User story and flows

## Appendix: Data Structures

### Complete Hedge Structure
```solidity
struct Hedge {
    uint256 positionTokenId;
    uint48 maturity;
    uint256 notional;
    address strategy;
    address vixHighToken;
    address vixLowToken;
    uint256 vixPositionId;
    HedgeStatus status;
    uint256 createdAt;
    uint256 lastRebalance;
    uint256 totalRebalances;
}
```

### Market Data Structure
```solidity
struct MarketData {
    uint160 currentPrice;
    uint160 volatility;
    uint256 timeToMaturity;
    uint256 currentIL;
    uint256 portfolioValue;
    uint160 optimalTickLower;
    uint160 optimalTickUpper;
}
```

### Rebalance Action Structure
```solidity
struct RebalanceAction {
    ActionType action;
    uint256 vixHighDelta;
    uint256 vixLowDelta;
    uint256 timestamp;
    bytes data;
}
```

