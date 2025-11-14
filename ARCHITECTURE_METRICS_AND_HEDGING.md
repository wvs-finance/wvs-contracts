# Architecture: Hedge Minting Flow

## Overview

This document addresses the architectural design for items 40-47 in TODO.md, focusing on:
1. **Hedge Minting Flow**: Generic hedge creation with VIX/American options selection

**Assumptions**: 
- Multi-metrics subscription system is already implemented (`HedgeLPMetrics`, `HedgeVolumeMetrics`, `HedgeExternalOracle`)
- All metrics update reactively when position liquidity changes
- `HedgeMetricsAggregator` provides unified query interface for all metrics

---

## Current Architecture

### Existing Components (Assumed Implemented)

```
┌─────────────────────────────────────────────────────────────┐
│                    HedgeAggregator (Diamond)                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  HedgeSubscriptionManager Facet                        │  │
│  │  - subscribe(tokenId, lpAccount)                      │  │
│  │  - Creates metrics proxies per position                │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  HedgeMetricsAggregator Facet                          │  │
│  │  - getLatestMetrics(tokenId)                           │  │
│  │  - getAggregatedMetrics(tokenId, timeKey)              │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ subscribes to
                            ▼
        ┌───────────────────────────────────────┐
        │   PositionManager (Uniswap V4)        │
        │   - notifyModifyLiquidity()           │
        │   - notifySubscribe()                │
        │   - notifyBurn()                     │
        └───────────────────────────────────────┘
                            │
                            │ notifies (all metrics update reactively)
                            ▼
        ┌───────────────────────────────────────┐
        │   Metrics Subscribers (ISubscriber)  │
        │   ├── HedgeLPMetrics                  │
        │   ├── HedgeVolumeMetrics              │
        │   └── HedgeExternalOracle             │
        │   - All update on liquidity changes   │
        │   - All emit MetricsData events        │
        └───────────────────────────────────────┘
```

---

## Critical Components: Theoretical Foundations & Required Resources

### Component 1: Maturity (TimeLockController) ⚠️

#### Why It's Critical

**Derivative Theory Foundation**: 
- All derivatives (variance swaps, options) have **expiration dates** (maturity)
- Maturity determines the **time value** component of derivative pricing
- Settlement and P&L calculation **must** occur at maturity
- Early settlement or extension violates derivative contract terms

**Mathematical Foundation**:
- **Black-Scholes Model**: Option value = Intrinsic Value + Time Value
  - Time Value decays as maturity approaches (theta decay)
  - Time decay is non-linear and accelerates near expiration
- **Variance Swap Pricing**: 
  - Realized variance is calculated over the period [t₀, T] where T is maturity
  - Settlement formula: `P&L = Notional × (RealizedVariance - StrikeVariance)`
  - Cannot calculate realized variance until maturity T

**LP Position Hedging Context**:
- LP positions have **impermanent loss** that accumulates over time
- Hedges must match the **time horizon** of LP risk exposure
- Maturity ensures hedge **expires** when LP decides to exit or rebalance
- Prevents **over-hedging** or **under-hedging** due to timing mismatches

#### Required Resources to Study

1. **Derivative Pricing Theory**:
   - **Book**: "Options, Futures, and Other Derivatives" by John Hull (Chapters 13-15, 20-21)
   - **Focus**: Time value decay, theta, expiration mechanics
   - **Key Concepts**: 
     - Time decay curves
     - Expiration settlement procedures
     - Early exercise vs. expiration

2. **Variance Swap Theory**:
   - **Paper**: "Variance Swaps" by Carr & Madan (1998)
   - **Paper**: "A New Approach for Pricing Derivatives" by Carr & Lee (2009)
   - **Key Concepts**:
     - Realized variance calculation: `RV = (252/T) × Σ(ln(S_i/S_{i-1}))²`
     - Variance swap payoff structure
     - Maturity-dependent pricing

3. **TimeLockController Implementation**:
   - **Resource**: OpenZeppelin TimelockController documentation
   - **Resource**: EIP-2535 (Diamond Standard) for facet integration
   - **Key Concepts**:
     - Timelock scheduling vs. expiration enforcement
     - Role-based access control for maturity execution
     - Integration with strategy settlement

4. **LP Risk Management**:
   - **Paper**: "Uniswap V3 Impermanent Loss" by Topaze Blue (2021)
   - **Paper**: "Liquidity Provider Returns in Geometric Mean Markets" by Angeris et al. (2021)
   - **Key Concepts**:
     - Time-dependent IL accumulation
     - Optimal hedge duration matching LP holding period

---

### Component 2: HedgeType (VIX | AMERICAN_OPTIONS) ⚠️

#### Why It's Critical

**Derivative Classification Theory**:
- **VIX (Variance Swaps)**: 
  - **Underlying**: Realized variance of asset price
  - **Payoff**: Linear in variance, non-linear in price
  - **Use Case**: Hedge **volatility risk** of LP positions
  - **Settlement**: Cash-settled at maturity based on realized variance
  
- **American Options**:
  - **Underlying**: Asset price directly
  - **Payoff**: Non-linear (asymmetric) in price
  - **Use Case**: Hedge **directional risk** and **tail risk** of LP positions
  - **Settlement**: Can be exercised early (American-style) or at maturity

**LP Position Risk Decomposition**:
LP positions face multiple risk factors:
1. **Volatility Risk** (σ): Variance of price movements → Hedged by VIX
2. **Directional Risk** (Δ): Price movement direction → Hedged by Options
3. **Time Decay Risk** (θ): Time value erosion → Affects both hedge types differently

**Mathematical Foundation**:
- **Portfolio Theory**: Different derivatives hedge different **risk factors**
- **Greeks Analysis**:
  - VIX hedges: Vega (volatility sensitivity)
  - Options hedge: Delta (price sensitivity), Gamma (convexity)
- **Correlation Structure**: 
  - VIX and Options have different correlation with LP P&L
  - Must choose hedge type based on **dominant risk factor**

#### Required Resources to Study

1. **Variance Swaps & VIX Theory**:
   - **Book**: "Volatility Trading" by Euan Sinclair (Chapters 1-4, 8-10)
   - **Paper**: "The VIX Index" by Whaley (2009)
   - **Paper**: "Variance Risk Premium" by Bollerslev et al. (2009)
   - **Key Concepts**:
     - Variance swap mechanics
     - VIX calculation methodology
     - Volatility risk premium
     - Realized vs. implied variance

2. **Options Theory**:
   - **Book**: "Options Volatility & Pricing" by Sheldon Natenberg (Chapters 1-5, 10-12)
   - **Book**: "Dynamic Hedging" by Nassim Taleb (Chapters 1-3)
   - **Key Concepts**:
     - American vs. European options
     - Early exercise optimality
     - Greeks (Delta, Gamma, Theta, Vega)
     - Option pricing models (Black-Scholes, Binomial)

3. **LP Risk Hedging**:
   - **Paper**: "Hedging Uniswap V3 LP Positions" by various DeFi researchers
   - **Paper**: "Impermanent Loss in Automated Market Makers" by Angeris et al. (2020)
   - **Key Concepts**:
     - IL decomposition: `IL = f(price_change, volatility, time)`
     - Volatility component → VIX hedge
     - Price component → Options hedge
     - Correlation between LP returns and hedge instruments

4. **GreekFi Integration**:
   - **Resource**: GreekFi protocol documentation (if available)
   - **Resource**: Options pricing libraries (op-hooks library)
   - **Key Concepts**:
     - On-chain options pricing
     - Greeks calculation on-chain
     - American options exercise logic

---

### Component 3: BaseParameters (Theory-Grounded Metrics) ⚠️

#### Why Metrics Must Be Theory-Grounded

**Derivative Pricing Requirements**:
All derivative pricing models require specific inputs:
- **Current State**: Spot price, volatility, time to maturity
- **Risk Parameters**: Risk-free rate, correlation, skew
- **Market Data**: Implied volatility surface, term structure

**LP Position Metrics**:
LP positions require specific metrics for hedge calibration:
- **Position Metrics**: Liquidity amount, price range, fees accrued
- **Risk Metrics**: Current IL, expected IL, volatility exposure
- **Market Metrics**: Current price, implied volatility, volume

#### Required Metrics (Theory-Grounded)

**1. Position Cost Function Metrics** (from TODO.md line 16):
```
c_i = Cost function of LP position i
```
**Required Metrics**:
- `liquidity`: Current liquidity amount (from HedgeLPMetrics)
- `sqrtPriceX96`: Current pool price (from HedgeLPMetrics)
- `tickLower`, `tickUpper`: Position price range
- `feesAccrued`: Accumulated fees (from HedgeLPMetrics)
- `feeGrowthInside`: Fee growth rates (from HedgeLPMetrics)

**Theoretical Foundation**:
- **CFMM Theory**: Constant Function Market Maker cost function
- **Paper**: "Automated Market Making and Loss-Versus-Rebalancing" by Milionis et al. (2022)
- **Formula**: `c_i = f(liquidity, price_range, fees)`

**2. Volatility Metrics** (for VIX hedging):
**Required Metrics**:
- `realizedVolatility`: Historical volatility over time window
- `impliedVolatility`: Market-implied volatility (from options or VIX)
- `volatilityTermStructure`: Volatility across different maturities
- `varianceRiskPremium`: Difference between implied and realized variance

**Theoretical Foundation**:
- **Stochastic Volatility Models**: Heston model, SABR model
- **Paper**: "The Volatility Surface" by Jim Gatheral (2006)
- **Paper**: "Variance Swaps" by Carr & Madan (1998)
- **Formula**: 
  - Realized Variance: `RV = (1/T) × Σ(ln(S_t/S_{t-1}))²`
  - Implied Variance: From options pricing model

**3. Price Risk Metrics** (for Options hedging):
**Required Metrics**:
- `currentPrice`: Current asset price (from HedgeLPMetrics or HedgeExternalOracle)
- `priceRange`: Min/max price in position range
- `deltaExposure`: Price sensitivity of LP position
- `gammaExposure`: Convexity of LP position
- `skew`: Implied volatility skew (from options market)

**Theoretical Foundation**:
- **Delta-Gamma Hedging**: Greeks-based hedging
- **Book**: "Dynamic Hedging" by Nassim Taleb
- **Paper**: "The Greeks of Uniswap V3" by various researchers
- **Formula**:
  - Delta: `Δ = ∂V/∂S` (price sensitivity)
  - Gamma: `Γ = ∂²V/∂S²` (convexity)

**4. Time-to-Maturity Metrics**:
**Required Metrics**:
- `timeToMaturity`: `T - t` where T is maturity timestamp
- `thetaDecay`: Time value decay rate
- `fundingRate`: Cost of maintaining hedge position

**Theoretical Foundation**:
- **Time Decay Theory**: Theta in options pricing
- **Book**: "Options Volatility & Pricing" by Natenberg
- **Formula**: `θ = -∂V/∂t` (time decay)

**5. Volume & Liquidity Metrics** (for market impact):
**Required Metrics**:
- `tradingVolume`: Volume over time window (from HedgeVolumeMetrics)
- `liquidityDepth`: Available liquidity at current price
- `marketImpact`: Expected price impact of hedge execution

**Theoretical Foundation**:
- **Market Microstructure**: Kyle's lambda, market impact models
- **Paper**: "Optimal Execution of Portfolio Transactions" by Almgren & Chriss (2000)
- **Formula**: `Market Impact = f(volume, liquidity_depth, volatility)`

#### Required Resources to Study

1. **CFMM Theory & LP Metrics**:
   - **Paper**: "Automated Market Making and Loss-Versus-Rebalancing" by Milionis et al. (2022)
   - **Paper**: "Replicating Market Makers" by Angeris et al. (2021)
   - **Key Concepts**:
     - LP position value function
     - Impermanent loss calculation
     - Fee accrual mechanics

2. **Volatility Modeling**:
   - **Book**: "The Volatility Surface" by Jim Gatheral (2006)
   - **Paper**: "A Closed-Form Solution for Options with Stochastic Volatility" by Heston (1993)
   - **Paper**: "Managing Smile Risk" by Hagan et al. (SABR model, 2002)
   - **Key Concepts**:
     - Realized vs. implied volatility
     - Volatility term structure
     - Variance risk premium

3. **Options Greeks & Hedging**:
   - **Book**: "Dynamic Hedging" by Nassim Taleb
   - **Book**: "Options Volatility & Pricing" by Sheldon Natenberg
   - **Key Concepts**:
     - Delta, Gamma, Theta, Vega
     - Greeks for LP positions
     - Dynamic hedging strategies

4. **Market Microstructure**:
   - **Book**: "Market Microstructure Theory" by Maureen O'Hara
   - **Paper**: "Optimal Execution of Portfolio Transactions" by Almgren & Chriss (2000)
   - **Key Concepts**:
     - Market impact
     - Liquidity provision
     - Execution costs

5. **DeFi-Specific Metrics**:
   - **Paper**: "Uniswap V3: The Universal AMM" by Adams et al. (2021)
   - **Paper**: "Concentrated Liquidity in Automated Market Makers" by various researchers
   - **Key Concepts**:
     - Concentrated liquidity metrics
     - Fee accrual in V3/V4
     - Price range optimization

---

## Implementation Architecture: Generic Hedge Minting with Maturity

### Overview

This section focuses on the **implementation architecture** for generic hedge minting, specifically the maturity enforcement mechanism. This is **implementation-focused** and does not require derivative pricing theory - it covers the **how** rather than the **why**.

### Architecture Diagram: Vault-Based Hedge Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    ERC4626 (Tokenized Vault Standard)           │
│                         ↑ (implements)                          │
│                         │                                       │
│              ┌──────────────────────┐                           │
│              │   HedgeVault         │                           │
│              │   (ERC7575 MultiAsset)│                           │
│              │                      │                           │
│              │  ┌────────────────┐  │                           │
│              │  │   Strategy     │  │                           │
│              │  │ (stored here)  │  │                           │
│              │  │ (VaultStrategy)│  │                           │
│              │  └────────────────┘  │                           │
│              └──────────────────────┘                           │
│                         │                                       │
│                         │ (stores strategy)                     │
│                         ↓                                       │
│              ┌──────────────────────┐                           │
│              │      Hedge            │                           │
│              │  (HedgeInfo struct)   │                           │
│              │                      │                           │
│              │  ┌────────────────┐  │                           │
│              │  │HedgeMaturityLock│  │                           │
│              │  │ (has timelock) │  │                           │
│              │  │ (enforces maturity)│                          │
│              │  └────────────────┘  │                           │
│              └──────────────────────┘                           │
│                         │                                       │
│                         │ (references)                          │
│                         ↓                                       │
│              ┌──────────────────────┐                           │
│              │   ERC1155            │                           │
│              │   Claim Tokens       │                           │
│              └──────────────────────┘                           │
│                                                               │
│  Strategy Hierarchy:                                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  VaultStrategy (stored in HedgeVault)              │    │
│  │       ↑ (extends)                                   │    │
│  │  BaseStrategy (abstract)                           │    │
│  │       ↑ (implements)                                │    │
│  │  ERC4626 (vault interface)                         │    │
│  │       ↑ (integrates with)                          │    │
│  │  ERC-5169 (execution standard)                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
└─────────────────────────────────────────────────────────────────┘

Key Relationships:
- HedgeVault (ERC4626/ERC7575 MultiAsset Vault) stores Strategy
- Hedge has HedgeMaturityLock (enforces maturity via TimeLockController)
- Strategy is stored on HedgeVault (multi-asset vault)
- Strategy extends BaseStrategy and implements ERC4626
- Hedge references both vault (where strategy is stored) and maturity lock
- Minting creates: Hedge → HedgeMaturityLock + HedgeVault (with Strategy)
```

**Component Breakdown**:

1. **HedgeVault (ERC4626/ERC7575 MultiAsset Vault)**
   - Implements tokenized vault standard
   - **Stores Strategy** (VaultStrategy contract)
   - Stores hedge assets (LP positions, hedge tokens)
   - Provides deposit/withdraw functionality
   - Multi-asset support via ERC7575

2. **Hedge (HedgeInfo)**
   - **Has HedgeMaturityLock** (enforces maturity)
   - References HedgeVault (where strategy is stored)
   - Stores hedge metadata (tokenId, hedgeType, vault, maturityLock)
   - Links to maturity enforcement contract

3. **HedgeMaturityLock** (Better Name: Maturity Enforcement Contract)
   - **Hedge has this contract** (one per hedge or shared)
   - Implements maturity enforcement via TimeLockController
   - Schedules settlement at maturity
   - Manages hedge state transitions
   - **Alternative Names**: `HedgeMaturityEnforcer`, `MaturityLock`, `HedgeExpiryController`

4. **Strategy (VaultStrategy)**
   - **Stored on HedgeVault** (multi-asset vault)
   - Extends BaseStrategy
   - Implements ERC4626 vault interface
   - Automates buy/sell hedge operations
   - Subject to maturity constraints

5. **ERC-5169 Integration**
   - Cross-chain execution (if needed)
   - Execution delegation
   - Strategy automation triggers

---

### Vault-Based Strategy Architecture

**Key Insight**: Strategy implements ERC4626 Vault interface, enabling:
- Standard vault operations (deposit/withdraw)
- Asset management for hedge positions
- Integration with DeFi protocols expecting ERC4626

**Architecture Flow**:

```
User Minting Hedge
    │
    ├─1. Deploy HedgeVault (ERC4626/ERC7575)
    │   └──► Vault stores hedge assets
    │
    ├─2. Deploy VaultStrategy (extends BaseStrategy, implements ERC4626)
    │   ├──► Strategy manages vault assets
    │   ├──► Strategy automates hedge buy/sell
    │   └──► Strategy subject to maturity constraints
    │
    ├─3. Create Hedge (HedgeInfo)
    │   ├──► Links to HedgeVault (vault address - Strategy stored ON vault)
    │   ├──► Links to HedgeMaturityLock (maturity lock address - Hedge HAS this)
    │   └──► Strategy stored ON vault (not directly in HedgeInfo)
    │
    └─4. Schedule Settlement
        └──► HedgeMaturityLock (Hedge HAS this) schedules strategy.settle() at maturity
```

**VaultStrategy Implementation**:

```solidity
/**
 * @title VaultStrategy
 * @notice Strategy that implements ERC4626 vault interface
 * @dev Extends BaseStrategy and implements vault standard for asset management
 */
contract VaultStrategy is BaseStrategy, ERC4626 {
    // ERC4626 implementation
    function asset() public view override returns (address) {
        return _getUnderlyingAsset(); // LP position token or hedge asset
    }
    
    function totalAssets() public view override returns (uint256) {
        StrategyStorage storage $ = getStorage();
        // Calculate total assets managed by this hedge strategy
        return _calculateTotalAssets($.tokenId);
    }
    
    // BaseStrategy settlement
    function _calculateSettlement() 
        internal 
        override 
        returns (uint256 pnl, bytes memory settlementData) 
    {
        StrategyStorage storage $ = getStorage();
        
        // Calculate P&L based on hedge type
        if (_isVIXHedge($.hedgeId)) {
            return _calculateVIXSettlement();
        } else {
            return _calculateOptionsSettlement();
        }
    }
    
    function _executeSettlement(uint256 pnl, bytes memory settlementData) 
        internal 
        override 
    {
        StrategyStorage storage $ = getStorage();
        
        // Execute settlement via vault
        // Transfer assets to LP account
        _transferAssets($.lpAccount, pnl);
        
        // Update vault state
        _updateVaultState(settlementData);
    }
    
    // Vault automation (subject to maturity)
    function automateHedgeOperations() external {
        StrategyStorage storage $ = getStorage();
        require(block.timestamp < $.maturity, "Hedge matured");
        
        // Automated buy/sell hedge operations
        // Can be triggered by ERC-5169 execution
        _rebalanceHedge();
    }
}
```

**HedgeVault Integration** (Strategy stored ON vault):

```solidity
/**
 * @title HedgeVault
 * @notice ERC4626/ERC7575 vault for storing hedge assets
 * @dev Strategy is stored ON this vault (multi-asset vault)
 */
contract HedgeVault is ERC4626, ERC7575 {
    // Strategy is stored ON this vault
    mapping(uint256 hedgeId => address strategy) public hedgeStrategies;
    
    mapping(uint256 hedgeId => uint256 assets) public hedgeAssets;
    
    /**
     * @notice Store strategy for hedge (Strategy stored ON vault)
     * @param hedgeId Hedge identifier
     * @param strategy Strategy contract address
     */
    function setStrategy(uint256 hedgeId, address strategy) external {
        require(hedgeStrategies[hedgeId] == address(0), "Strategy already set");
        hedgeStrategies[hedgeId] = strategy;
        emit StrategyStored(hedgeId, strategy);
    }
    
    /**
     * @notice Get strategy for hedge (Strategy stored ON vault)
     * @param hedgeId Hedge identifier
     * @return strategy Strategy contract address
     */
    function getStrategy(uint256 hedgeId) external view returns (address) {
        return hedgeStrategies[hedgeId];
    }
    
    function depositForHedge(uint256 hedgeId, uint256 assets) external {
        // Deposit assets for specific hedge
        _deposit(assets, hedgeId);
        hedgeAssets[hedgeId] += assets;
    }
    
    function withdrawFromHedge(uint256 hedgeId, uint256 assets) external {
        require(hedgeAssets[hedgeId] >= assets, "Insufficient assets");
        hedgeAssets[hedgeId] -= assets;
        _withdraw(assets, hedgeId);
    }
    
    event StrategyStored(uint256 indexed hedgeId, address indexed strategy);
}
```

**Why Vault-Based Strategy**:

1. **Standard Interface**: ERC4626 enables integration with DeFi protocols
2. **Asset Management**: Vault manages hedge assets (LP positions, hedge tokens)
3. **Automation**: Strategy can automate hedge operations via ERC-5169
4. **Maturity Constraints**: All operations subject to maturity enforcement
5. **Multi-Asset Support**: ERC7575 enables multiple asset types per vault

**ERC-5169 Integration** (Execution Standard):

```solidity
// Strategy can integrate with ERC-5169 for execution delegation
interface IERC5169 {
    function execute(bytes calldata data) external;
}

// VaultStrategy can use ERC-5169 for cross-chain or delegated execution
contract VaultStrategy is BaseStrategy, ERC4626 {
    IERC5169 public executionDelegate;
    
    function automateViaERC5169(bytes calldata executionData) external {
        require(block.timestamp < getMaturity(), "Hedge matured");
        executionDelegate.execute(executionData);
    }
}
```

---

### Core Components

#### 1. Hedge Registry (Storage)

**Purpose**: Track all hedges and their state

```solidity
struct HedgeRegistry {
    // Core hedge data
    mapping(uint256 hedgeId => HedgeInfo) hedges;
    mapping(uint256 tokenId => uint256[] hedgeIds) positionHedges; // One position can have multiple hedges
    
    // Maturity tracking
    mapping(uint256 maturityTimestamp => uint256[] hedgeIds) maturityQueue;
    
    // State tracking
    mapping(uint256 hedgeId => HedgeState) states;
}

struct HedgeInfo {
    uint256 hedgeId;           // Unique hedge identifier (ERC1155 token ID)
    uint256 tokenId;           // LP position token ID
    address lpAccount;         // LP who owns the hedge
    // maturity, state, createdAt stored in HedgeMaturityLock (query via getHedgeState())
    HedgeType hedgeType;       // VIX | AMERICAN_OPTIONS
    address vault;             // HedgeVault address (ERC4626/ERC7575)
    // ⚠️ Strategy is stored ON the vault (query via vault.getStrategy())
    address maturityLock;      // HedgeMaturityLock address
    // ⚠️ Hedge HAS this contract (enforces maturity via TimeLockController)
    // Alternative names: HedgeMaturityEnforcer, MaturityLock, HedgeExpiryController
}

enum HedgeState {
    ACTIVE,      // Hedge is active, waiting for maturity
    MATURED,     // Maturity reached, ready for settlement
    SETTLED,     // Settlement executed
    CANCELLED    // Hedge cancelled before maturity
}
```

**Architectural Decision**: 
- Use `mapping(uint256 => uint256[])` for maturity queue to enable batch settlement
- Separate state tracking from hedge info for gas efficiency
- Support multiple hedges per position

---

#### 2. ERC1155 Claim Token System

**Purpose**: Represent hedge ownership and claims

```solidity
// Hedge ID encoding scheme
// hedgeId = keccak256(abi.encodePacked(tokenId, maturity, hedgeType, salt))
// OR simpler: hedgeId = uint256(keccak256(abi.encode(tokenId, maturity, hedgeType, nonce)))

interface IHedgeClaims {
    /**
     * @notice Mint claim token when hedge is created
     * @param hedgeId Unique hedge identifier
     * @param lpAccount LP account receiving the claim token
     * @param amount Amount of claim tokens (typically 1)
     */
    function mintClaimToken(
        uint256 hedgeId,
        address lpAccount,
        uint256 amount
    ) external;
    
    /**
     * @notice Burn claim token after settlement
     * @param hedgeId Hedge identifier
     * @param account Account burning the token
     * @param amount Amount to burn
     */
    function burnClaimToken(
        uint256 hedgeId,
        address account,
        uint256 amount
    ) external;
    
    /**
     * @notice Get hedge metadata for claim token
     * @param hedgeId Hedge identifier
     * @return metadata Struct with hedge information
     */
    function getHedgeMetadata(uint256 hedgeId) 
        external 
        view 
        returns (HedgeMetadata memory metadata);
}

struct HedgeMetadata {
    uint256 tokenId;
    uint256 maturity;
    HedgeType hedgeType;
    address strategy;
    HedgeState state;
}
```

**Architectural Decisions**:
- Use ERC1155 for multi-token standard (one token type per hedge)
- Claim token acts as proof of ownership and entitlement to settlement
- Metadata stored off-chain (IPFS) or in separate mapping for gas efficiency

---

#### 3. HedgeMaturityLock (Maturity Enforcement Contract)

**Purpose**: Enforce maturity and trigger settlement

**Architecture Pattern**: **Scheduled Execution Pattern**

**Key Insight**: 
- **Hedge HAS this contract** (HedgeMaturityLock)
- The TimeLockController contract itself stores:
  - `maturity` (as timestamp in `_timestamps` mapping)
  - `HedgeState` (as `OperationState` enum: Unset, Waiting, Ready, Done)
  - `createdAt` (can be derived from scheduled timestamp - delay)

**Better Contract Names**:
- `HedgeMaturityLock` (current)
- `HedgeMaturityEnforcer` (descriptive)
- `MaturityLock` (concise)
- `HedgeExpiryController` (clear purpose)

We need to create a **HedgeMaturityLock** contract that wraps/extends TimeLockController and maps hedge-specific data.

```solidity
interface IMaturityEnforcer {
    /**
     * @notice Schedule settlement operation for hedge maturity
     * @param hedgeId Hedge to schedule settlement for
     * @param maturityTimestamp When to execute settlement
     */
    function scheduleSettlement(
        uint256 hedgeId,
        uint256 maturityTimestamp
    ) external returns (bytes32 operationId);
    
    /**
     * @notice Execute settlement when maturity is reached
     * @param hedgeId Hedge to settle
     */
    function executeSettlement(uint256 hedgeId) external;
    
    /**
     * @notice Check if hedge has reached maturity
     * @param hedgeId Hedge to check
     * @return true if maturity timestamp has passed
     */
    function isMatured(uint256 hedgeId) external view returns (bool);
    
    /**
     * @notice Get hedge state from timelock
     * @param hedgeId Hedge identifier
     * @return state Current hedge state
     * @return maturity Maturity timestamp
     * @return createdAt Creation timestamp
     */
    function getHedgeState(uint256 hedgeId) 
        external 
        view 
        returns (HedgeState state, uint256 maturity, uint256 createdAt);
}
```

**HedgeMaturityLock Contract Implementation** (Hedge HAS this contract):

```solidity
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title HedgeMaturityLock (Alternative: HedgeMaturityEnforcer, MaturityLock, HedgeExpiryController)
 * @notice Hedge HAS this contract - enforces maturity via TimeLockController
 * @dev Wraps TimeLockController with hedge-specific state tracking
 * @dev Maps hedgeId to operationId and provides hedge-specific queries
 */
contract HedgeMaturityLock is TimelockController {
    // Mapping hedgeId -> operationId for settlement operations
    mapping(uint256 hedgeId => bytes32 operationId) public hedgeOperations;
    
    // Mapping operationId -> hedgeId (reverse lookup)
    mapping(bytes32 operationId => uint256 hedgeId) public operationHedges;
    
    // Mapping hedgeId -> creation timestamp
    mapping(uint256 hedgeId => uint256 createdAt) public hedgeCreatedAt;
    
    // HedgeAggregator address (authorized to schedule settlements)
    address public immutable hedgeAggregator;
    
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin,
        address _hedgeAggregator
    ) TimelockController(minDelay, proposers, executors, admin) {
        hedgeAggregator = _hedgeAggregator;
    }
    
    /**
     * @notice Schedule hedge settlement operation
     * @param hedgeId Unique hedge identifier
     * @param maturityTimestamp When hedge matures (settlement execution time)
     * @param settlementTarget Target contract for settlement call
     * @param settlementData Encoded settlement function call
     * @return operationId The operation ID in TimeLockController
     */
    function scheduleHedgeSettlement(
        uint256 hedgeId,
        uint256 maturityTimestamp,
        address settlementTarget,
        bytes memory settlementData
    ) external returns (bytes32 operationId) {
        require(msg.sender == hedgeAggregator, "Only HedgeAggregator");
        require(maturityTimestamp > block.timestamp, "Maturity must be future");
        require(hedgeOperations[hedgeId] == bytes32(0), "Hedge already scheduled");
        
        // Calculate delay from now until maturity
        uint256 delay = maturityTimestamp - block.timestamp;
        require(delay >= getMinDelay(), "Delay below minimum");
        
        // Use hedgeId as salt for deterministic operationId
        bytes32 salt = bytes32(hedgeId);
        
        // Generate operationId
        operationId = hashOperation(
            settlementTarget,
            0, // no value
            settlementData,
            bytes32(0), // no predecessor
            salt
        );
        
        // Schedule the operation in TimeLockController
        schedule(
            settlementTarget,
            0,
            settlementData,
            bytes32(0),
            salt,
            delay
        );
        
        // Store mappings
        hedgeOperations[hedgeId] = operationId;
        operationHedges[operationId] = hedgeId;
        hedgeCreatedAt[hedgeId] = block.timestamp;
        
        emit HedgeScheduled(hedgeId, operationId, maturityTimestamp);
    }
    
    /**
     * @notice Get hedge state from TimeLockController operation state
     * @param hedgeId Hedge identifier
     * @return state Current hedge state (mapped from OperationState)
     * @return maturity Maturity timestamp (from TimeLockController)
     * @return createdAt Creation timestamp
     */
    function getHedgeState(uint256 hedgeId) 
        external 
        view 
        returns (HedgeState state, uint256 maturity, uint256 createdAt) 
    {
        bytes32 operationId = hedgeOperations[hedgeId];
        require(operationId != bytes32(0), "Hedge not found");
        
        // Get operation state from TimeLockController
        OperationState opState = getOperationState(operationId);
        
        // Map OperationState to HedgeState
        if (opState == OperationState.Unset) {
            state = HedgeState.CANCELLED;
        } else if (opState == OperationState.Waiting) {
            state = HedgeState.ACTIVE;
        } else if (opState == OperationState.Ready) {
            state = HedgeState.MATURED;
        } else { // OperationState.Done
            state = HedgeState.SETTLED;
        }
        
        // Get maturity timestamp from TimeLockController
        uint256 timestamp = getTimestamp(operationId);
        maturity = timestamp == _DONE_TIMESTAMP ? 0 : timestamp;
        
        // Get creation timestamp
        createdAt = hedgeCreatedAt[hedgeId];
    }
    
    /**
     * @notice Check if hedge has reached maturity
     * @param hedgeId Hedge identifier
     * @return true if maturity timestamp has passed
     */
    function isMatured(uint256 hedgeId) external view returns (bool) {
        bytes32 operationId = hedgeOperations[hedgeId];
        if (operationId == bytes32(0)) return false;
        
        OperationState opState = getOperationState(operationId);
        return opState == OperationState.Ready || opState == OperationState.Done;
    }
    
    /**
     * @notice Get maturity timestamp for hedge
     * @param hedgeId Hedge identifier
     * @return maturity Maturity timestamp (0 if not found or already settled)
     */
    function getMaturity(uint256 hedgeId) external view returns (uint256 maturity) {
        bytes32 operationId = hedgeOperations[hedgeId];
        if (operationId == bytes32(0)) return 0;
        
        uint256 timestamp = getTimestamp(operationId);
        maturity = timestamp == _DONE_TIMESTAMP ? 0 : timestamp;
    }
    
    /**
     * @notice Get creation timestamp for hedge
     * @param hedgeId Hedge identifier
     * @return createdAt Creation timestamp (0 if not found)
     */
    function getCreatedAt(uint256 hedgeId) external view returns (uint256) {
        return hedgeCreatedAt[hedgeId];
    }
    
    /**
     * @notice Execute settlement (called by TimeLockController executor role)
     * @dev This is called automatically by TimeLockController when operation is ready
     * @param hedgeId Hedge to settle
     */
    function executeHedgeSettlement(uint256 hedgeId) external {
        bytes32 operationId = hedgeOperations[hedgeId];
        require(operationId != bytes32(0), "Hedge not found");
        
        // TimeLockController will call execute() which triggers the settlement
        // The actual settlement logic is in the settlementTarget contract
    }
    
    event HedgeScheduled(
        uint256 indexed hedgeId,
        bytes32 indexed operationId,
        uint256 maturityTimestamp
    );
}
```

**How Hedge HAS HedgeMaturityLock**:

```solidity
// In HedgeAggregator or HedgeMintingFacet
contract HedgeMintingFacet {
    // Each hedge has its own HedgeMaturityLock (or shared instance)
    mapping(uint256 hedgeId => address maturityLock) public hedgeMaturityLocks;
    
    function _setupMaturityLock(
        uint256 hedgeId, 
        uint256 maturity,
        address strategy
    ) internal {
        // Encode settlement call to strategy
        bytes memory settlementData = abi.encodeCall(
            BaseStrategy.settle,
            ()
        );
        
        // Schedule settlement in HedgeMaturityLock (hedge HAS this)
        HedgeMaturityLock maturityLock = HedgeMaturityLock(hedges[hedgeId].maturityLock);
        bytes32 operationId = maturityLock.scheduleHedgeSettlement(
            hedgeId,
            maturity,
            address(strategy),  // settlement target
            settlementData
        );
        
        // Store maturity lock address in registry (hedge HAS this)
        hedges[hedgeId].maturityLock = address(maturityLock);
    }
    
    /**
     * @notice Query hedge state from HedgeMaturityLock (hedge HAS this)
     * @param hedgeId Hedge identifier
     * @return state Current hedge state
     * @return maturity Maturity timestamp
     * @return createdAt Creation timestamp
     */
    function getHedgeState(uint256 hedgeId) 
        external 
        view 
        returns (HedgeState state, uint256 maturity, uint256 createdAt) 
    {
        HedgeMaturityLock maturityLock = HedgeMaturityLock(hedges[hedgeId].maturityLock);
        return maturityLock.getHedgeState(hedgeId);
    }
    
    /**
     * @notice Check if hedge is matured (via HedgeMaturityLock)
     * @param hedgeId Hedge identifier
     * @return true if matured
     */
    function isHedgeMatured(uint256 hedgeId) external view returns (bool) {
        HedgeMaturityLock maturityLock = HedgeMaturityLock(hedges[hedgeId].maturityLock);
        return maturityLock.isMatured(hedgeId);
    }
}
```

**Integration with Hedge Registry**:

**Key Architecture Points**:
1. **Hedge HAS HedgeMaturityLock** (enforces maturity)
2. **Strategy is stored ON HedgeVault** (multi-asset vault)

```solidity
struct HedgeInfo {
    uint256 hedgeId;           // Unique hedge identifier (ERC1155 token ID)
    uint256 tokenId;           // LP position token ID
    address lpAccount;         // LP who owns the hedge
    HedgeType hedgeType;       // VIX | AMERICAN_OPTIONS
    address vault;             // HedgeVault address (Strategy is stored HERE)
    address maturityLock;      // HedgeMaturityLock address (Hedge HAS this)
    // Removed: maturity, state, createdAt (stored in HedgeMaturityLock)
}

// Query strategy from vault (Strategy is stored ON vault)
function getHedgeStrategy(uint256 hedgeId) external view returns (address) {
    HedgeVault vault = HedgeVault(hedges[hedgeId].vault);
    return vault.getStrategy(hedgeId);
}

// Query methods delegate to HedgeMaturityLock (Hedge HAS this)
function getHedgeMaturity(uint256 hedgeId) external view returns (uint256) {
    HedgeMaturityLock maturityLock = HedgeMaturityLock(hedges[hedgeId].maturityLock);
    return maturityLock.getMaturity(hedgeId);
}

function getHedgeState(uint256 hedgeId) external view returns (HedgeState) {
    HedgeMaturityLock maturityLock = HedgeMaturityLock(hedges[hedgeId].maturityLock);
    (HedgeState state,,) = maturityLock.getHedgeState(hedgeId);
    return state;
}

function getHedgeCreatedAt(uint256 hedgeId) external view returns (uint256) {
    HedgeMaturityLock maturityLock = HedgeMaturityLock(hedges[hedgeId].maturityLock);
    return maturityLock.getCreatedAt(hedgeId);
}
```

**Recommended Pattern**: **HedgeMaturityLock** (extends TimeLockController)
- **Hedge HAS this contract** (one per hedge or shared instance)
- **Benefits**: 
  - Clear ownership: Hedge has maturity enforcement contract
  - State stored in TimeLockController (leverages existing infrastructure)
  - Single source of truth for maturity, state, and createdAt
  - Lower gas cost than per-hedge TimeLockControllers (if shared)
  - Automatic state management via TimeLockController's OperationState
- **Trade-off**: Contract dependency per hedge, but provides clear separation
- **State Storage**: maturity, state (OperationState), and createdAt all stored in HedgeMaturityLock
- **Better Names**: `HedgeMaturityEnforcer`, `MaturityLock`, `HedgeExpiryController`

---

#### 4. BaseStrategy Contract Template

**Purpose**: Provide common functionality for all hedge strategies

```solidity
abstract contract BaseStrategy {
    // Storage
    struct StrategyStorage {
        uint256 hedgeId;
        uint256 tokenId;
        address lpAccount;
        uint256 maturity;
        address aggregator;      // HedgeAggregator address
        bool initialized;
    }
    
    bytes32 constant STRATEGY_STORAGE_POSITION = 
        keccak256("wvs.hedging.base-strategy");
    
    function getStorage() internal pure returns (StrategyStorage storage s) {
        bytes32 position = STRATEGY_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
    
    // Initialization
    function initialize(
        uint256 _hedgeId,
        uint256 _tokenId,
        address _lpAccount,
        uint256 _maturity,
        address _aggregator
    ) external {
        StrategyStorage storage $ = getStorage();
        require(!$.initialized, "Already initialized");
        
        $.hedgeId = _hedgeId;
        $.tokenId = _tokenId;
        $.lpAccount = _lpAccount;
        $.maturity = _maturity;
        $.aggregator = _aggregator;
        $.initialized = true;
        
        _onInitialize();
    }
    
    // Abstract hooks for strategy-specific logic
    function _onInitialize() internal virtual;
    
    // Settlement (called by TimeLockController at maturity)
    function settle() external {
        StrategyStorage storage $ = getStorage();
        require(block.timestamp >= $.maturity, "Not matured");
        require(msg.sender == $.aggregator, "Unauthorized");
        
        (uint256 pnl, bytes memory settlementData) = _calculateSettlement();
        
        _executeSettlement(pnl, settlementData);
        
        emit StrategySettled($.hedgeId, $.tokenId, pnl);
    }
    
    // Abstract methods for strategy-specific implementation
    function _calculateSettlement() 
        internal 
        virtual 
        returns (uint256 pnl, bytes memory settlementData);
    
    function _executeSettlement(uint256 pnl, bytes memory settlementData) 
        internal 
        virtual;
    
    // Common utilities
    function getHedgeId() external view returns (uint256) {
        return getStorage().hedgeId;
    }
    
    function getMaturity() external view returns (uint256) {
        return getStorage().maturity;
    }
    
    function isMatured() external view returns (bool) {
        return block.timestamp >= getStorage().maturity;
    }
    
    event StrategySettled(
        uint256 indexed hedgeId,
        uint256 indexed tokenId,
        int256 pnl
    );
}
```

**Architectural Decisions**:
- Use diamond storage pattern for upgradeability
- Abstract methods for strategy-specific logic
- Common maturity checking and settlement flow
- Event emission for off-chain tracking

---

### Why Strategy Integration is Critical

#### 1. **Separation of Concerns**

**Problem**: Different hedge types (VIX vs American Options) have completely different settlement logic:
- **VIX**: Calculate realized variance, compare to strike, settle variance swap
- **American Options**: Calculate option payoff, handle early exercise, settle option contract

**Solution**: Each hedge type gets its own strategy contract that implements hedge-specific logic.

```
HedgeAggregator (Diamond)
    │
    ├──► Generic Hedge Minting (Phase 1)
    │    └──► Deploys BaseStrategy (template)
    │
    └──► Hedge-Specific Configuration (Phase 2)
         ├──► VIX Strategy (extends BaseStrategy)
         │    └──► Implements VIX settlement logic
         │
         └──► American Options Strategy (extends BaseStrategy)
              └──► Implements options settlement logic
```

#### 2. **Settlement Execution Flow**

**Critical Path**: When maturity is reached, HedgeTimeLock calls the strategy's `settle()` function:

```
HedgeTimeLock (maturity reached)
    │
    └──► Calls strategy.settle()
         │
         ├──► BaseStrategy.settle() (common logic)
         │    ├── Validate maturity
         │    ├── Validate caller (HedgeAggregator)
         │    └── Call _calculateSettlement() [abstract]
         │
         └──► Strategy-specific implementation
              ├── VIXStrategy._calculateSettlement()
              │   ├── Query realized variance from metrics
              │   ├── Calculate P&L = Notional × (RV - Strike)
              │   └── Execute variance swap settlement
              │
              └── AmericanOptionsStrategy._calculateSettlement()
                  ├── Query current price
                  ├── Calculate option payoff
                  └── Execute option settlement
```

**Why This Matters**:
- Strategy contract is the **execution target** for HedgeTimeLock
- Strategy contains **all settlement logic** (P&L calculation, token transfers, etc.)
- Strategy is **isolated** - if one strategy has a bug, others are unaffected
- Strategy can be **upgraded** independently (if using proxy pattern)

#### 3. **Two-Phase Hedge Creation**

**Phase 1: Generic Minting** (creates BaseStrategy)
- Deploys BaseStrategy with common parameters
- BaseStrategy is **incomplete** - missing hedge-specific configuration
- Stores: hedgeId, tokenId, lpAccount, maturity, aggregator

**Phase 2: Hedge-Specific Configuration** (extends BaseStrategy)
- VIX: Configures variance swap parameters, links to VIXAdapter
- American Options: Configures option parameters, links to GreekFiAdapter
- Strategy becomes **fully functional** after configuration

**Why Two Phases**:
- Allows user to **mint hedge first**, then **configure later** based on market conditions
- Separates **generic hedge creation** from **hedge-specific setup**
- Enables **flexible configuration** without redeploying strategy

#### 4. **Strategy as Settlement Target**

**HedgeTimeLock Integration**:

```solidity
// When scheduling settlement, strategy is the target
hedgeTimeLock.scheduleHedgeSettlement(
    hedgeId,
    maturity,
    address(strategy),  // ⚠️ Strategy is the settlement target
    abi.encodeCall(BaseStrategy.settle, ())
);

// At maturity, HedgeTimeLock calls:
strategy.settle()  // Strategy executes settlement
```

**Why Strategy Must Be Separate Contract**:
1. **Isolation**: Settlement logic isolated from HedgeAggregator
2. **Upgradeability**: Can upgrade strategy without touching aggregator
3. **Gas Efficiency**: Only strategy code is deployed per hedge (not full aggregator)
4. **Testability**: Can test settlement logic independently
5. **Security**: Strategy bugs don't affect other hedges or aggregator

#### 5. **Strategy Registry Pattern**

**Architecture**: Strategy address stored in HedgeInfo for lookup

```solidity
// Query strategy for hedge
address strategy = hedges[hedgeId].strategy;

// Call strategy methods
BaseStrategy(strategy).settle();
BaseStrategy(strategy).getHedgeId();
BaseStrategy(strategy).isMatured();
```

**Benefits**:
- **Direct Access**: Can call strategy methods directly
- **Type Safety**: Strategy implements BaseStrategy interface
- **Extensibility**: New strategy types can be added without changing registry
- **Query Capability**: Frontend can query strategy state directly

#### 6. **Strategy Lifecycle**

```
1. Deploy (Phase 1)
   └──► BaseStrategy deployed via CREATE2
   └──► Initialized with generic parameters
   └──► State: INCOMPLETE (missing hedge-specific config)

2. Configure (Phase 2)
   └──► Hedge-specific parameters added
   └──► Links to adapters (VIXAdapter, GreekFiAdapter)
   └──► State: ACTIVE (ready for settlement)

3. Active (Until Maturity)
   └──► Strategy monitors metrics
   └──► Can be queried for current state
   └──► State: ACTIVE

4. Settlement (At Maturity)
   └──► HedgeTimeLock calls strategy.settle()
   └──► Strategy calculates P&L
   └──► Strategy executes settlement
   └──► State: SETTLED
```

**Why This Lifecycle Matters**:
- **Clear State Transitions**: Each phase has distinct responsibilities
- **Validation**: Can validate strategy is configured before settlement
- **Monitoring**: Can track strategy state throughout hedge lifecycle
- **Debugging**: Can inspect strategy state at any point

---

### Strategy Integration Summary

**Why Strategy is Important**:

1. **Encapsulation**: Settlement logic encapsulated in strategy contract
2. **Extensibility**: New hedge types = new strategy contracts (no aggregator changes)
3. **Isolation**: Strategy bugs don't affect other hedges
4. **Testability**: Can test settlement logic independently
5. **Upgradeability**: Can upgrade strategies without touching aggregator
6. **Gas Efficiency**: Only strategy code deployed per hedge (not full aggregator)
7. **Flexibility**: Two-phase creation allows delayed configuration

**Key Integration Points**:

1. **HedgeInfo.strategy**: Stores strategy address for lookup
2. **HedgeTimeLock**: Calls `strategy.settle()` at maturity
3. **BaseStrategy**: Common interface for all strategies
4. **Strategy Deployment**: CREATE2 for deterministic addresses
5. **Strategy Initialization**: Two-phase (generic → specific)

**Architectural Pattern**: **Strategy Pattern** (Gang of Four)
- BaseStrategy defines interface
- Concrete strategies (VIXStrategy, AmericanOptionsStrategy) implement interface
- HedgeAggregator uses strategies without knowing implementation details

---

### Implementation Cycle

#### Phase 1: Hedge Creation

```
User calls mintHedge(params)
    │
    ├─1. Validation
    │   ├─ Validate tokenId ownership
    │   ├─ Validate maturity > block.timestamp
    │   ├─ Validate hedgeType is valid
    │   └─ Validate baseConfig completeness
    │
    ├─2. Generate Hedge ID
    │   └─ hedgeId = _generateHedgeId(tokenId, maturity, hedgeType, nonce)
    │
    ├─3. Deploy BaseStrategy
    │   ├─ Deploy strategy contract (CREATE2 for deterministic address)
    │   ├─ Initialize strategy with hedge parameters
    │   └─ Store strategy address in registry
    │
    ├─4. Setup Maturity Enforcement
    │   ├─ Deploy HedgeMaturityLock (or use shared instance)
    │   ├─ Hedge HAS HedgeMaturityLock (store address in HedgeInfo)
    │   ├─ Call maturityLock.scheduleHedgeSettlement(hedgeId, maturity, strategy, settlementData)
    │   ├─ HedgeMaturityLock stores: maturity (in _timestamps), state (OperationState), createdAt
    │   └─ Store maturityLock address in registry
    │
    ├─5. Mint ERC1155 Claim Token
    │   ├─ Mint claim token to lpAccount
    │   ├─ Set metadata URI for claim token
    │   └─ Emit HedgeMinted event
    │
    └─6. Update Registry
        ├─ Store hedge info in hedges mapping
        ├─ Add hedgeId to positionHedges[tokenId]
        ├─ Add hedgeId to maturityQueue[maturity]
        └─ Set state to ACTIVE
```

**Implementation**:

```solidity
function mintHedge(GenericHedgeParams memory params) 
    external 
    returns (uint256 hedgeId, address strategy) 
{
    // 1. Validation
    _validateMintParams(params);
    
    // 2. Generate hedge ID
    hedgeId = _generateHedgeId(params);
    
    // 3. Deploy BaseStrategy
    strategy = _deployBaseStrategy(hedgeId, params);
    
    // 4. Setup maturity enforcement (Hedge HAS HedgeMaturityLock)
    _setupMaturityLock(hedgeId, params.maturity, strategy);
    
    // 5. Mint claim token
    _mintClaimToken(hedgeId, params.lpAccount);
    
    // 6. Update registry
    _registerHedge(hedgeId, params, strategy);
    
    emit HedgeMinted(hedgeId, params.tokenId, params.hedgeType);
    
    return (hedgeId, strategy);
}

function _validateMintParams(GenericHedgeParams memory params) internal view {
    // Validate ownership
    require(
        IERC721(positionManager).ownerOf(params.tokenId) == msg.sender,
        "Not position owner"
    );
    
    // Validate maturity
    require(
        params.maturity > block.timestamp,
        "Maturity must be in future"
    );
    
    // Validate maturity is not too far in future (optional)
    require(
        params.maturity <= block.timestamp + MAX_MATURITY_DURATION,
        "Maturity too far"
    );
    
    // Validate hedge type
    require(
        params.hedgeType == HedgeType.VIX || 
        params.hedgeType == HedgeType.AMERICAN_OPTIONS,
        "Invalid hedge type"
    );
}

function _generateHedgeId(GenericHedgeParams memory params) 
    internal 
    returns (uint256) 
{
    uint256 nonce = hedgeNonce[params.tokenId]++;
    return uint256(keccak256(abi.encode(
        params.tokenId,
        params.maturity,
        params.hedgeType,
        nonce,
        block.timestamp
    )));
}

function _setupMaturityLock(
    uint256 hedgeId,
    uint256 maturity,
    address strategy
) internal {
    // Deploy or get HedgeMaturityLock (Hedge HAS this)
    HedgeMaturityLock maturityLock = _getOrDeployMaturityLock(hedgeId);
    
    // Encode settlement call (Strategy is stored ON vault)
    address vault = hedges[hedgeId].vault;
    bytes memory settlementData = abi.encodeCall(BaseStrategy.settle, ());
    
    // Schedule in HedgeMaturityLock (stores maturity, state, createdAt internally)
    bytes32 operationId = maturityLock.scheduleHedgeSettlement(
        hedgeId,
        maturity,
        address(strategy), // Strategy address (stored on vault)
        settlementData
    );
    
    // Store maturity lock address (Hedge HAS this)
    hedges[hedgeId].maturityLock = address(maturityLock);
    
    emit MaturityScheduled(hedgeId, operationId, maturity);
}
```

---

#### Phase 2: Maturity Monitoring

**Architecture Pattern**: **Event-Driven + Polling Hybrid**

```solidity
// Option 1: Event-driven (recommended for on-chain monitoring)
event MaturityApproaching(uint256 indexed hedgeId, uint256 maturity, uint256 blocksRemaining);

// Option 2: Polling (for off-chain services)
function getMaturedHedges(uint256 fromTimestamp, uint256 toTimestamp) 
    external 
    view 
    returns (uint256[] memory hedgeIds) 
{
    // Return all hedges with maturity in [fromTimestamp, toTimestamp]
}

// Option 3: Queue-based (for batch processing)
function processMaturityQueue(uint256 maturityTimestamp) external {
    uint256[] memory hedgeIds = maturityQueue[maturityTimestamp];
    for (uint256 i = 0; i < hedgeIds.length; i++) {
        if (isMatured(hedgeIds[i])) {
            _markAsMatured(hedgeIds[i]);
        }
    }
}
```

**Architectural Decision**:
- Use **event-driven** for real-time monitoring
- Use **queue-based** for batch settlement at specific maturity timestamps
- Off-chain services can poll `getMaturedHedges()` for settlement

---

#### Phase 3: Settlement Execution

```
TimeLockController.execute() OR Manual trigger
    │
    ├─1. Validate Maturity
    │   ├─ Check block.timestamp >= maturity
    │   ├─ Check hedge state is ACTIVE
    │   └─ Verify caller is authorized (TimeLockController or admin)
    │
    ├─2. Update State
    │   └─ Set hedge state to MATURED
    │
    ├─3. Execute Strategy Settlement
    │   ├─ Call strategy.settle()
    │   ├─ Strategy calculates P&L
    │   ├─ Strategy executes settlement logic
    │   └─ Strategy emits StrategySettled event
    │
    ├─4. Update Claim Tokens
    │   ├─ Update claim token metadata (mark as settled)
    │   └─ Optionally burn claim tokens or mark as redeemed
    │
    ├─5. Update Registry
    │   ├─ Set hedge state to SETTLED
    │   ├─ Remove from maturity queue
    │   └─ Emit HedgeSettled event
    │
    └─6. Notify LP
        └─ Emit event for frontend/dashboard
```

**Implementation**:

```solidity
function executeSettlement(uint256 hedgeId) external {
    HedgeInfo storage hedge = hedges[hedgeId];
    
    // 1. Validate maturity (query from HedgeMaturityLock - Hedge HAS this)
    HedgeMaturityLock maturityLock = HedgeMaturityLock(hedge.maturityLock);
    (HedgeState currentState, uint256 maturity,) = maturityLock.getHedgeState(hedgeId);
    require(currentState == HedgeState.ACTIVE || currentState == HedgeState.MATURED, "Invalid state");
    require(block.timestamp >= maturity, "Not matured");
    require(
        msg.sender == address(maturityLock) || 
        msg.sender == address(this) || 
        hasRole(SETTLEMENT_EXECUTOR_ROLE, msg.sender),
        "Unauthorized"
    );
    
    // 2. State is managed by HedgeMaturityLock, no need to update here
    
    // 3. Execute strategy settlement (Strategy is stored ON vault)
    HedgeVault vault = HedgeVault(hedge.vault);
    address strategy = vault.getStrategy(hedgeId);
    (int256 pnl, bytes memory settlementData) = BaseStrategy(strategy).settle();
    
    // 4. Update claim tokens (optional - can be done in strategy)
    _updateClaimTokenMetadata(hedgeId, settlementData);
    
    // 5. Update registry (state managed by HedgeMaturityLock)
    _removeFromMaturityQueue(hedgeId, maturity);
    
    emit HedgeSettled(hedgeId, hedge.tokenId, pnl, settlementData);
}
```

---

### Complete Call Flow: HedgeMaturityLock Integration

**Step-by-Step Implementation**:

```solidity
// 1. Deploy HedgeMaturityLock (per hedge or shared instance)
// Hedge HAS this contract
HedgeMaturityLock maturityLock = new HedgeMaturityLock(
    0,                          // minDelay (0 = immediate execution at maturity)
    [address(this)],            // proposers (HedgeAggregator)
    [address(this)],            // executors (HedgeAggregator)
    address(0),                 // admin
    address(this)               // hedgeAggregator
);

// 2. When minting hedge, deploy vault and strategy
function mintHedge(GenericHedgeParams memory params) external {
    // ... validation and hedge ID generation ...
    
    // Deploy HedgeVault (Strategy will be stored ON this vault)
    HedgeVault vault = new HedgeVault();
    
    // Deploy strategy and store ON vault
    address strategy = _deployBaseStrategy(hedgeId, params);
    vault.setStrategy(hedgeId, strategy);
    
    // Hedge HAS HedgeMaturityLock
    HedgeMaturityLock maturityLock = _getOrDeployMaturityLock(hedgeId);
    
    // Schedule settlement in HedgeMaturityLock
    bytes memory settlementData = abi.encodeCall(BaseStrategy.settle, ());
    bytes32 operationId = maturityLock.scheduleHedgeSettlement(
        hedgeId,
        params.maturity,
        address(strategy), // Strategy stored ON vault
        settlementData
    );
    
    // Store references
    hedges[hedgeId].vault = address(vault);           // Strategy stored ON vault
    hedges[hedgeId].maturityLock = address(maturityLock); // Hedge HAS this
    
    // HedgeMaturityLock now stores:
    // - maturity: in _timestamps[operationId]
    // - state: OperationState (Waiting -> Ready -> Done)
    // - createdAt: in hedgeCreatedAt[hedgeId]
}

// 3. Query hedge state from HedgeMaturityLock (Hedge HAS this)
function getHedgeInfo(uint256 hedgeId) external view returns (
    uint256 tokenId,
    address lpAccount,
    HedgeType hedgeType,
    address vault,
    address strategy,
    HedgeState state,
    uint256 maturity,
    uint256 createdAt
) {
    HedgeInfo storage hedge = hedges[hedgeId];
    
    // Query state from HedgeMaturityLock (Hedge HAS this)
    HedgeMaturityLock maturityLock = HedgeMaturityLock(hedge.maturityLock);
    (HedgeState currentState, uint256 maturityTimestamp, uint256 created) = 
        maturityLock.getHedgeState(hedgeId);
    
    // Get strategy from vault (Strategy stored ON vault)
    HedgeVault vault = HedgeVault(hedge.vault);
    address strategyAddress = vault.getStrategy(hedgeId);
    
    return (
        hedge.tokenId,
        hedge.lpAccount,
        hedge.hedgeType,
        hedge.vault,              // Strategy stored ON vault
        strategyAddress,          // Retrieved from vault
        currentState,            // From HedgeMaturityLock
        maturityTimestamp,       // From HedgeMaturityLock
        created                  // From HedgeMaturityLock
    );
}

// 4. Check maturity before settlement (via HedgeMaturityLock)
function canSettle(uint256 hedgeId) external view returns (bool) {
    HedgeMaturityLock maturityLock = HedgeMaturityLock(hedges[hedgeId].maturityLock);
    return maturityLock.isMatured(hedgeId);
}

// 5. Settlement execution (called by HedgeMaturityLock executor role)
// When maturity is reached, HedgeMaturityLock automatically calls:
// strategy.settle() -> Strategy is stored ON vault
```

**State Mapping**:

```
TimeLockController.OperationState → HedgeState
─────────────────────────────────────────────────
Unset      → CANCELLED  (hedge not scheduled or cancelled)
Waiting    → ACTIVE     (hedge scheduled, waiting for maturity)
Ready      → MATURED    (maturity reached, ready for settlement)
Done       → SETTLED    (settlement executed)
```

**Key Benefits**:
1. **Single Source of Truth**: All maturity/state data in HedgeMaturityLock (Hedge HAS this)
2. **Automatic State Management**: TimeLockController manages OperationState
3. **Gas Efficient**: No duplicate storage of maturity/state/createdAt
4. **Leverages Existing Infrastructure**: Uses TimeLockController's proven state machine
5. **Clear Ownership**: Hedge HAS maturity lock, Strategy stored ON vault

---

### Key Architectural Decisions

#### Decision 1: Maturity Enforcement Location

**Options**:
- **A**: Enforce at HedgeAggregator level (centralized)
- **B**: Enforce at Strategy level (decentralized)
- **C**: Hybrid (HedgeTimeLock schedules, Strategy executes)

**Decision**: **Option C (Hybrid)**
- HedgeMaturityLock (Hedge HAS this) ensures maturity is enforced
- HedgeMaturityLock stores maturity, state, and createdAt internally
- Strategy (stored ON vault) handles settlement logic
- Separation of concerns: enforcement vs. execution
- Single source of truth for hedge state
- Clear ownership: Hedge HAS maturity lock, Strategy stored ON vault

#### Decision 2: Claim Token Lifecycle

**Options**:
- **A**: Burn claim tokens after settlement
- **B**: Keep claim tokens as historical record
- **C**: Transfer claim tokens to settlement contract

**Decision**: **Option B (Keep as record)**
- Enables historical tracking and dashboard display
- Claim tokens can be marked as "settled" via metadata
- Lower gas cost (no burn operation)

#### Decision 3: Batch Settlement

**Options**:
- **A**: Settle hedges individually as they mature
- **B**: Batch settle all hedges at same maturity timestamp
- **C**: Hybrid (batch when possible, individual when needed)

**Decision**: **Option C (Hybrid)**
- Use maturity queue for batch processing
- Allow individual settlement for urgent cases
- Gas efficient for multiple hedges maturing simultaneously

#### Decision 4: Strategy Deployment Pattern

**Options**:
- **A**: Deploy new strategy contract per hedge (CREATE)
- **B**: Use deterministic addresses (CREATE2)
- **C**: Use proxy pattern (minimal proxy)

**Decision**: **Option B (CREATE2)**
- Deterministic addresses enable pre-computation
- Lower gas cost than CREATE
- Enables strategy address prediction before deployment

---

### Gas Optimization Considerations

1. **Maturity Queue**: Batch processing reduces gas per hedge
2. **Storage Packing**: Pack structs to minimize storage slots
3. **Event-Only Metadata**: Store detailed metadata off-chain, emit events
4. **Lazy Settlement**: Only calculate P&L when settlement is called
5. **Claim Token Optimization**: Use ERC1155 batch operations when possible

---

### Error Handling & Edge Cases

1. **Maturity in Past**: Reject or allow immediate settlement?
   - **Decision**: Reject (validation in `_validateMintParams`)

2. **Strategy Deployment Failure**: Rollback entire hedge creation?
   - **Decision**: Yes (use try-catch, revert on failure)

3. **TimeLockController Execution Failure**: Manual override?
   - **Decision**: Allow admin override after maturity timestamp

4. **Multiple Hedges Same Maturity**: Handle queue overflow?
   - **Decision**: Use array, no size limit (gas cost acceptable)

5. **LP Position Burned Before Maturity**: Cancel hedge?
   - **Decision**: Keep hedge active, settlement handles position state

---

### Testing Strategy

1. **Unit Tests**:
   - Hedge ID generation uniqueness
   - Maturity validation logic
   - State transitions

2. **Integration Tests**:
   - TimeLockController integration
   - ERC1155 claim token minting/burning
   - Strategy deployment and initialization

3. **Fork Tests**:
   - End-to-end hedge creation → maturity → settlement
   - Multiple hedges maturing simultaneously
   - Edge cases (past maturity, cancelled positions)

---

## ERC1155 Hedge Minting Entry Point: Requirements & Extensibility

### Overview

The **ERC1155 token minting** is the entry point for creating hedges. Each minted ERC1155 token represents a hedge position. This section defines all requirements and extension points to make the minting process fully customizable by other processes.

**Design Principles**:
1. **ERC1155 Token = Hedge**: Each minted token ID represents a unique hedge
2. **Fully Extensible**: All critical steps have hook points for customization
3. **Non-Breaking**: Core requirements cannot be bypassed, but can be extended
4. **Composable**: Multiple hooks can be chained together
5. **Upgradeable**: Hook system allows adding new functionality without core changes

---

### Entry Point Design: `mintHedge`

**Core Function**: Mint ERC1155 token as hedge entry point

```solidity
/**
 * @title IHedgeMinter
 * @notice Entry point for minting ERC1155 hedge tokens
 * @dev Fully customizable via hooks and extension points
 */
interface IHedgeMinter {
    /**
     * @notice Mint ERC1155 hedge token (entry point)
     * @param params Generic hedge parameters
     * @param customData Custom data for extension hooks
     * @return hedgeId ERC1155 token ID (hedge identifier)
     * @return vault HedgeVault address (strategy stored ON vault)
     * @return maturityLock HedgeMaturityLock address (hedge HAS this)
     */
    function mintHedge(
        GenericHedgeParams memory params,
        bytes memory customData
    ) external returns (
        uint256 hedgeId,
        address vault,
        address maturityLock
    );
    
    /**
     * @notice Batch mint multiple hedges (gas efficient)
     * @param paramsArray Array of hedge parameters
     * @param customData Custom data for extension hooks
     * @return hedgeIds Array of hedge IDs
     * @return vaults Array of vault addresses
     * @return maturityLocks Array of maturity lock addresses
     */
    function batchMintHedge(
        GenericHedgeParams[] memory paramsArray,
        bytes memory customData
    ) external returns (
        uint256[] memory hedgeIds,
        address[] memory vaults,
        address[] memory maturityLocks
    );
}
```

---

### Requirements for ERC1155 Hedge Minting

#### 1. **Core Requirements** (Mandatory - Cannot be Bypassed)

**R1.1: Hedge ID Generation**
- ✅ Must generate unique `hedgeId` (ERC1155 token ID)
- ✅ Must be deterministic or collision-resistant
- ✅ Must encode hedge parameters for uniqueness
- ✅ Must prevent ID collisions across all hedges

**R1.2: LP Position Validation**
- ✅ Must validate `tokenId` exists and is owned by caller
- ✅ Must validate position is active (not burned)
- ✅ Must validate position has sufficient liquidity
- ✅ Must validate position is subscribed to metrics (if required)

**R1.3: Maturity Validation**
- ✅ Must validate `maturity > block.timestamp`
- ✅ Must validate `maturity <= block.timestamp + MAX_MATURITY_DURATION`
- ✅ Must validate maturity is not in past
- ✅ Must validate maturity is within acceptable range

**R1.4: Hedge Type Validation**
- ✅ Must validate `hedgeType` is supported (VIX | AMERICAN_OPTIONS)
- ✅ Must validate hedge type-specific parameters are present
- ✅ Must validate hedge type is enabled (not paused)

**R1.5: ERC1155 Token Minting**
- ✅ Must mint ERC1155 token to `lpAccount`
- ✅ Must use `hedgeId` as token ID
- ✅ Must mint exactly 1 token (or configurable amount)
- ✅ Must emit `TransferSingle` event
- ✅ Must comply with ERC1155 standard

**R1.6: Registry Storage**
- ✅ Must store `HedgeInfo` in registry
- ✅ Must link `hedgeId` to `tokenId` in `positionHedges` mapping
- ✅ Must add `hedgeId` to `maturityQueue[maturity]`
- ✅ Must update hedge count per position

**R1.7: Vault & Strategy Deployment**
- ✅ Must deploy `HedgeVault` (or use factory)
- ✅ Must deploy `VaultStrategy` and store ON vault
- ✅ Must initialize strategy with hedge parameters
- ✅ Must link strategy to hedge ID

**R1.8: Maturity Lock Setup**
- ✅ Must deploy or get `HedgeMaturityLock` (hedge HAS this)
- ✅ Must schedule settlement at maturity
- ✅ Must store maturity lock address in `HedgeInfo`
- ✅ Must validate maturity lock deployment success

---

#### 2. **Extension Points** (Customization Hooks)

**E1: Pre-Mint Validation Hook**
```solidity
interface IPreMintHook {
    /**
     * @notice Called before minting ERC1155 token
     * @param params Hedge parameters
     * @param customData Custom data from mintHedge call
     * @return success Whether validation passed
     * @return reason Revert reason if validation failed
     */
    function beforeMint(
        GenericHedgeParams memory params,
        bytes memory customData
    ) external returns (bool success, string memory reason);
}
```

**E2: Post-Mint Hook**
```solidity
interface IPostMintHook {
    /**
     * @notice Called after minting ERC1155 token
     * @param hedgeId Minted hedge ID
     * @param params Hedge parameters
     * @param customData Custom data from mintHedge call
     */
    function afterMint(
        uint256 hedgeId,
        GenericHedgeParams memory params,
        bytes memory customData
    ) external;
}
```

**E3: Strategy Deployment Hook**
```solidity
interface IStrategyDeploymentHook {
    /**
     * @notice Customize strategy deployment
     * @param hedgeId Hedge ID
     * @param params Hedge parameters
     * @param customData Custom data
     * @return strategy Strategy contract address
     */
    function deployStrategy(
        uint256 hedgeId,
        GenericHedgeParams memory params,
        bytes memory customData
    ) external returns (address strategy);
}
```

**E4: Vault Deployment Hook**
```solidity
interface IVaultDeploymentHook {
    /**
     * @notice Customize vault deployment
     * @param hedgeId Hedge ID
     * @param params Hedge parameters
     * @param customData Custom data
     * @return vault Vault contract address
     */
    function deployVault(
        uint256 hedgeId,
        GenericHedgeParams memory params,
        bytes memory customData
    ) external returns (address vault);
}
```

**E5: Maturity Lock Hook**
```solidity
interface IMaturityLockHook {
    /**
     * @notice Customize maturity lock setup
     * @param hedgeId Hedge ID
     * @param maturity Maturity timestamp
     * @param strategy Strategy address
     * @param customData Custom data
     * @return maturityLock Maturity lock address
     */
    function setupMaturityLock(
        uint256 hedgeId,
        uint256 maturity,
        address strategy,
        bytes memory customData
    ) external returns (address maturityLock);
}
```

**E6: Metadata Hook**
```solidity
interface IMetadataHook {
    /**
     * @notice Customize ERC1155 token metadata
     * @param hedgeId Hedge ID
     * @param params Hedge parameters
     * @return metadataURI Token metadata URI
     */
    function getMetadataURI(
        uint256 hedgeId,
        GenericHedgeParams memory params
    ) external view returns (string memory metadataURI);
}
```

**E7: Fee Calculation Hook** (NEW)
```solidity
interface IFeeCalculationHook {
    /**
     * @notice Customize fee calculation for hedge minting
     * @param params Hedge parameters
     * @param customData Custom data
     * @return feeAmount Fee amount to charge
     * @return feeRecipient Fee recipient address
     */
    function calculateFee(
        GenericHedgeParams memory params,
        bytes memory customData
    ) external view returns (uint256 feeAmount, address feeRecipient);
}
```

**E8: Access Control Hook** (NEW)
```solidity
interface IAccessControlHook {
    /**
     * @notice Customize access control for minting
     * @param caller Caller address
     * @param params Hedge parameters
     * @param customData Custom data
     * @return allowed Whether caller is allowed to mint
     */
    function canMint(
        address caller,
        GenericHedgeParams memory params,
        bytes memory customData
    ) external view returns (bool allowed);
}
```

**E9: Hedge ID Generation Hook** (NEW)
```solidity
interface IHedgeIdGenerationHook {
    /**
     * @notice Customize hedge ID generation
     * @param params Hedge parameters
     * @param customData Custom data
     * @return hedgeId Generated hedge ID
     */
    function generateHedgeId(
        GenericHedgeParams memory params,
        bytes memory customData
    ) external returns (uint256 hedgeId);
}
```

**E10: Event Emission Hook** (NEW)
```solidity
interface IEventEmissionHook {
    /**
     * @notice Emit custom events after minting
     * @param hedgeId Hedge ID
     * @param params Hedge parameters
     * @param vault Vault address
     * @param maturityLock Maturity lock address
     * @param customData Custom data
     */
    function emitCustomEvents(
        uint256 hedgeId,
        GenericHedgeParams memory params,
        address vault,
        address maturityLock,
        bytes memory customData
    ) external;
}
```

**E11: State Transition Hook** (NEW)
```solidity
interface IStateTransitionHook {
    /**
     * @notice Called during state transitions
     * @param hedgeId Hedge ID
     * @param fromState Previous state
     * @param toState New state
     * @param customData Custom data
     */
    function onStateTransition(
        uint256 hedgeId,
        HedgeState fromState,
        HedgeState toState,
        bytes memory customData
    ) external;
}
```

**E12: Batch Minting Hook** (NEW)
```solidity
interface IBatchMintingHook {
    /**
     * @notice Called before batch minting
     * @param paramsArray Array of hedge parameters
     * @param customData Custom data
     * @return processed Whether batch should proceed
     */
    function beforeBatchMint(
        GenericHedgeParams[] memory paramsArray,
        bytes memory customData
    ) external returns (bool processed);
    
    /**
     * @notice Called after batch minting
     * @param hedgeIds Array of minted hedge IDs
     * @param paramsArray Array of hedge parameters
     * @param customData Custom data
     */
    function afterBatchMint(
        uint256[] memory hedgeIds,
        GenericHedgeParams[] memory paramsArray,
        bytes memory customData
    ) external;
}
```

---

#### 3. **Configuration Parameters** (Fully Customizable)

```solidity
struct GenericHedgeParams {
    // Core parameters
    uint256 tokenId;           // LP position token ID
    address lpAccount;         // LP account (recipient of ERC1155 token)
    uint256 maturity;          // Maturity timestamp
    HedgeType hedgeType;       // VIX | AMERICAN_OPTIONS
    
    // Base configuration (theory-grounded metrics)
    BaseHedgeConfig baseConfig;
    
    // Extension configuration
    ExtensionConfig extensions; // Custom extension points
}

struct ExtensionConfig {
    // Hook addresses (address(0) = use default)
    address preMintHook;           // Pre-mint validation hook
    address postMintHook;          // Post-mint hook
    address strategyDeploymentHook; // Strategy deployment hook
    address vaultDeploymentHook;    // Vault deployment hook
    address maturityLockHook;       // Maturity lock hook
    address metadataHook;           // Metadata hook
    address feeCalculationHook;     // Fee calculation hook (NEW)
    address accessControlHook;      // Access control hook (NEW)
    address hedgeIdGenerationHook;  // Hedge ID generation hook (NEW)
    address eventEmissionHook;     // Event emission hook (NEW)
    address stateTransitionHook;   // State transition hook (NEW)
    
    // Custom configuration
    bytes customConfig;             // Custom configuration data
}

struct BaseHedgeConfig {
    // Position metrics (from HedgeLPMetrics)
    uint128 liquidity;
    uint160 sqrtPriceX96;
    int24 tickLower;
    int24 tickUpper;
    uint256 feesAccrued;
    
    // Volatility metrics (for VIX hedging)
    uint256 realizedVolatility;
    uint256 impliedVolatility;
    uint256 varianceRiskPremium;
    
    // Price risk metrics (for Options hedging)
    int256 deltaExposure;
    int256 gammaExposure;
    uint256 currentPrice;
    
    // Time metrics
    uint256 timeToMaturity;
    int256 thetaDecay;
    
    // Market metrics (from HedgeVolumeMetrics)
    uint256 tradingVolume;
    uint256 liquidityDepth;
    
    // Risk parameters
    uint256 riskFreeRate;
    uint256 correlation;
}
```

---

#### 4. **Extensible Minting Implementation**

```solidity
contract HedgeMintingFacet is IHedgeMinter {
    // Hook registry
    mapping(address => bool) public registeredHooks;
    
    // Default hooks (can be overridden per hedge)
    address public defaultPreMintHook;
    address public defaultPostMintHook;
    address public defaultStrategyDeploymentHook;
    address public defaultVaultDeploymentHook;
    address public defaultMaturityLockHook;
    address public defaultMetadataHook;
    address public defaultFeeCalculationHook;
    address public defaultAccessControlHook;
    address public defaultHedgeIdGenerationHook;
    address public defaultEventEmissionHook;
    address public defaultStateTransitionHook;
    
    /**
     * @notice Mint ERC1155 hedge token (entry point)
     * @dev Fully customizable via hooks
     */
    function mintHedge(
        GenericHedgeParams memory params,
        bytes memory customData
    ) external returns (
        uint256 hedgeId,
        address vault,
        address maturityLock
    ) {
        // E8: Access control hook
        address accessControlHook = params.extensions.accessControlHook != address(0)
            ? params.extensions.accessControlHook
            : defaultAccessControlHook;
        
        if (accessControlHook != address(0)) {
            require(
                IAccessControlHook(accessControlHook).canMint(msg.sender, params, customData),
                "Access denied"
            );
        }
        
        // E1: Pre-mint validation hook
        address preMintHook = params.extensions.preMintHook != address(0)
            ? params.extensions.preMintHook
            : defaultPreMintHook;
        
        if (preMintHook != address(0)) {
            (bool success, string memory reason) = IPreMintHook(preMintHook)
                .beforeMint(params, customData);
            require(success, reason);
        }
        
        // Core validation (always required)
        _validateCoreRequirements(params);
        
        // E7: Fee calculation hook
        (uint256 feeAmount, address feeRecipient) = _calculateFee(params, customData);
        if (feeAmount > 0) {
            _collectFee(feeAmount, feeRecipient);
        }
        
        // E9: Hedge ID generation hook
        hedgeId = _generateHedgeId(params, customData);
        
        // E3: Strategy deployment hook
        address strategy = _deployStrategy(hedgeId, params, customData);
        
        // E4: Vault deployment hook
        vault = _deployVault(hedgeId, params, customData);
        
        // Store strategy ON vault
        HedgeVault(vault).setStrategy(hedgeId, strategy);
        
        // E5: Maturity lock hook
        maturityLock = _setupMaturityLock(hedgeId, params, strategy, customData);
        
        // R1.5: Mint ERC1155 token
        _mintClaimToken(hedgeId, params.lpAccount, params);
        
        // R1.6: Update registry
        _registerHedge(hedgeId, params, vault, maturityLock);
        
        // E11: State transition hook
        _notifyStateTransition(hedgeId, HedgeState.ACTIVE, params.extensions, customData);
        
        // E2: Post-mint hook
        address postMintHook = params.extensions.postMintHook != address(0)
            ? params.extensions.postMintHook
            : defaultPostMintHook;
        
        if (postMintHook != address(0)) {
            IPostMintHook(postMintHook).afterMint(hedgeId, params, customData);
        }
        
        // E10: Event emission hook
        _emitCustomEvents(hedgeId, params, vault, maturityLock, customData);
        
        emit HedgeMinted(hedgeId, params.tokenId, params.hedgeType);
        
        return (hedgeId, vault, maturityLock);
    }
    
    /**
     * @notice Batch mint multiple hedges
     */
    function batchMintHedge(
        GenericHedgeParams[] memory paramsArray,
        bytes memory customData
    ) external returns (
        uint256[] memory hedgeIds,
        address[] memory vaults,
        address[] memory maturityLocks
    ) {
        // E12: Batch minting hook
        IBatchMintingHook batchHook = IBatchMintingHook(defaultBatchMintingHook);
        if (address(batchHook) != address(0)) {
            require(
                batchHook.beforeBatchMint(paramsArray, customData),
                "Batch mint rejected"
            );
        }
        
        uint256 length = paramsArray.length;
        hedgeIds = new uint256[](length);
        vaults = new address[](length);
        maturityLocks = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            (hedgeIds[i], vaults[i], maturityLocks[i]) = mintHedge(
                paramsArray[i],
                customData
            );
        }
        
        // E12: After batch mint hook
        if (address(batchHook) != address(0)) {
            batchHook.afterBatchMint(hedgeIds, paramsArray, customData);
        }
        
        return (hedgeIds, vaults, maturityLocks);
    }
    
    function _generateHedgeId(
        GenericHedgeParams memory params,
        bytes memory customData
    ) internal returns (uint256) {
        address hook = params.extensions.hedgeIdGenerationHook != address(0)
            ? params.extensions.hedgeIdGenerationHook
            : defaultHedgeIdGenerationHook;
        
        if (hook != address(0)) {
            return IHedgeIdGenerationHook(hook).generateHedgeId(params, customData);
        }
        
        // Default generation
        uint256 nonce = hedgeNonce[params.tokenId]++;
        return uint256(keccak256(abi.encode(
            params.tokenId,
            params.maturity,
            params.hedgeType,
            nonce,
            block.timestamp
        )));
    }
    
    function _calculateFee(
        GenericHedgeParams memory params,
        bytes memory customData
    ) internal view returns (uint256 feeAmount, address feeRecipient) {
        address hook = params.extensions.feeCalculationHook != address(0)
            ? params.extensions.feeCalculationHook
            : defaultFeeCalculationHook;
        
        if (hook != address(0)) {
            return IFeeCalculationHook(hook).calculateFee(params, customData);
        }
        
        // Default: no fee
        return (0, address(0));
    }
    
    function _emitCustomEvents(
        uint256 hedgeId,
        GenericHedgeParams memory params,
        address vault,
        address maturityLock,
        bytes memory customData
    ) internal {
        address hook = params.extensions.eventEmissionHook != address(0)
            ? params.extensions.eventEmissionHook
            : defaultEventEmissionHook;
        
        if (hook != address(0)) {
            IEventEmissionHook(hook).emitCustomEvents(
                hedgeId,
                params,
                vault,
                maturityLock,
                customData
            );
        }
    }
    
    function _notifyStateTransition(
        uint256 hedgeId,
        HedgeState newState,
        ExtensionConfig memory extensions,
        bytes memory customData
    ) internal {
        address hook = extensions.stateTransitionHook != address(0)
            ? extensions.stateTransitionHook
            : defaultStateTransitionHook;
        
        if (hook != address(0)) {
            HedgeState fromState = HedgeState.ACTIVE; // Initial state
            IStateTransitionHook(hook).onStateTransition(
                hedgeId,
                fromState,
                newState,
                customData
            );
        }
    }
    
    // ... other helper functions ...
}
```

---

#### 5. **Hook Registration & Management**

```solidity
interface IHedgeMintingRegistry {
    /**
     * @notice Register a hook contract
     * @param hook Hook contract address
     * @param hookType Type of hook
     */
    function registerHook(address hook, HookType hookType) external;
    
    /**
     * @notice Set default hook for hook type
     * @param hookType Hook type
     * @param hook Hook contract address
     */
    function setDefaultHook(HookType hookType, address hook) external;
    
    /**
     * @notice Check if hook is registered
     * @param hook Hook contract address
     * @return isRegistered Whether hook is registered
     */
    function isHookRegistered(address hook) external view returns (bool);
    
    /**
     * @notice Get default hook for hook type
     * @param hookType Hook type
     * @return hook Default hook address
     */
    function getDefaultHook(HookType hookType) external view returns (address);
}

enum HookType {
    PreMint,
    PostMint,
    StrategyDeployment,
    VaultDeployment,
    MaturityLock,
    Metadata,
    FeeCalculation,
    AccessControl,
    HedgeIdGeneration,
    EventEmission,
    StateTransition,
    BatchMinting
}
```

---

#### 6. **Requirements Summary**

**Mandatory Requirements** (Cannot be customized):
1. ✅ Hedge ID generation (must be unique)
2. ✅ ERC1155 token minting (standard compliance)
3. ✅ Registry storage (data integrity)
4. ✅ Core validation (security)

**Customizable Requirements** (Via hooks):
1. 🔧 Pre-mint validation (custom rules)
2. 🔧 Strategy deployment (custom strategies)
3. 🔧 Vault deployment (custom vaults)
4. 🔧 Maturity lock setup (custom maturity enforcement)
5. 🔧 Post-mint actions (custom workflows)
6. 🔧 Metadata generation (custom URIs)
7. 🔧 Fee calculation (custom fee models) **NEW**
8. 🔧 Access control (custom permissions) **NEW**
9. 🔧 Hedge ID generation (custom ID schemes) **NEW**
10. 🔧 Event emission (custom events) **NEW**
11. 🔧 State transitions (custom state handling) **NEW**
12. 🔧 Batch minting (custom batch logic) **NEW**

**Extension Points**:
- ✅ Hook-based architecture
- ✅ Default hooks (fallback)
- ✅ Per-hedge hook override
- ✅ Custom data passthrough
- ✅ Hook registration system
- ✅ Batch minting support **NEW**
- ✅ Fee customization **NEW**
- ✅ Access control customization **NEW**

---

## Architectural Challenge: Hedge Minting Flow (TODO 40-47)

**Problem**: User mints hedge with generic info, then selects VIX or American options

**Architecture Solution**: **Two-Phase Hedge Creation Pattern**

```
Phase 1: Generic Hedge Minting
    │
    ├── User provides:
    │   ├── tokenId (LP position)
    │   ├── maturity (TimeLockController) ⚠️ CRITICAL COMPONENT
    │   ├── hedgeType (VIX | AMERICAN_OPTIONS) ⚠️ CRITICAL COMPONENT
    │   └── baseParameters (shared by all hedge types) ⚠️ THEORY-GROUNDED METRICS
    │
    └── HedgeAggregator creates:
        ├── HedgePosition (ERC1155 claim token)
        ├── BaseStrategy contract
        └── TimeLockController for maturity

Phase 2: Hedge-Specific Configuration
    │
    ├── If VIX:
    │   ├── Query VIX adapter parameters
    │   ├── Configure variance swap parameters
    │   └── Deploy VIXStrategy (extends BaseStrategy)
    │
    └── If AMERICAN_OPTIONS:
        ├── Query GreekFi adapter parameters
        ├── Configure option parameters (strike, etc.)
        └── Deploy AmericanOptionsStrategy (extends BaseStrategy)
```

**Contract Structure**:

```solidity
// Generic hedge minting interface
interface IHedgeMinter {
    struct GenericHedgeParams {
        uint256 tokenId;           // LP position
        uint256 maturity;          // Timestamp (see Critical Components section)
        HedgeType hedgeType;       // VIX | AMERICAN_OPTIONS (see Critical Components section)
        BaseHedgeConfig baseConfig; // Theory-grounded metrics (see Critical Components section)
    }
    
    struct BaseHedgeConfig {
        // Position metrics (from HedgeLPMetrics)
        uint128 liquidity;
        uint160 sqrtPriceX96;
        int24 tickLower;
        int24 tickUpper;
        uint256 feesAccrued;
        
        // Volatility metrics (for VIX hedging)
        uint256 realizedVolatility;      // Historical volatility
        uint256 impliedVolatility;       // Market-implied volatility
        uint256 varianceRiskPremium;     // IV - RV premium
        
        // Price risk metrics (for Options hedging)
        int256 deltaExposure;            // Price sensitivity
        int256 gammaExposure;            // Convexity
        uint256 currentPrice;            // Current asset price
        
        // Time metrics
        uint256 timeToMaturity;          // T - t (seconds)
        int256 thetaDecay;               // Time value decay rate
        
        // Market metrics (from HedgeVolumeMetrics)
        uint256 tradingVolume;           // Volume over time window
        uint256 liquidityDepth;          // Available liquidity
        
        // Risk parameters
        uint256 riskFreeRate;             // Risk-free interest rate
        uint256 correlation;              // Correlation with underlying
    }
    
    function mintHedge(GenericHedgeParams memory params) 
        external 
        returns (uint256 hedgeId, address strategy);
}

// Hedge-specific configuration
interface IVIXHedgeConfigurator {
    function configureVIXHedge(
        uint256 hedgeId,
        uint256 varianceStrike,
        uint256 notional
    ) external returns (address vixStrategy);
}

interface IAmericanOptionsConfigurator {
    function configureAmericanOptions(
        uint256 hedgeId,
        uint256 strikePrice,
        OptionType optionType,  // CALL | PUT
        uint256 notional
    ) external returns (address optionsStrategy);
}
```

**Implementation Flow**:

```solidity
// HedgeAggregator.sol (as Diamond with facets)

// Facet 1: Generic Hedge Minting
contract HedgeMintingFacet {
    function mintHedge(GenericHedgeParams memory params) 
        external 
        returns (uint256 hedgeId, address strategy) 
    {
        // 1. Validate position ownership
        require(
            IERC721(positionManager).ownerOf(params.tokenId) == msg.sender,
            "Not position owner"
        );
        
        // 2. Create ERC1155 claim token
        hedgeId = _mintClaimToken(params.tokenId, msg.sender);
        
        // 3. Deploy base strategy
        strategy = _deployBaseStrategy(hedgeId, params);
        
        // 4. Set up TimeLockController
        _setupMaturityLock(hedgeId, params.maturity);
        
        // 5. Emit event
        emit HedgeMinted(hedgeId, params.tokenId, params.hedgeType);
    }
}

// Facet 2: VIX Configuration
contract VIXHedgeFacet {
    function configureVIXHedge(
        uint256 hedgeId,
        uint256 varianceStrike,
        uint256 notional
    ) external returns (address vixStrategy) {
        // 1. Get base strategy
        address baseStrategy = _getBaseStrategy(hedgeId);
        
        // 2. Query VIX adapter for parameters
        VIXAdapter.VIXParams memory vixParams = 
            VIXAdapter.getVIXParams(varianceStrike, notional);
        
        // 3. Deploy VIX-specific strategy
        vixStrategy = _deployVIXStrategy(
            baseStrategy,
            vixParams
        );
        
        // 4. Update hedge registry
        _updateHedgeStrategy(hedgeId, vixStrategy);
    }
}

// Facet 3: American Options Configuration  
contract AmericanOptionsFacet {
    function configureAmericanOptions(
        uint256 hedgeId,
        uint256 strikePrice,
        OptionType optionType,
        uint256 notional
    ) external returns (address optionsStrategy) {
        // 1. Get base strategy
        address baseStrategy = _getBaseStrategy(hedgeId);
        
        // 2. Query GreekFi adapter
        GreekFiAdapter.OptionParams memory optionParams = 
            GreekFiAdapter.getOptionParams(
                strikePrice,
                optionType,
                notional
            );
        
        // 3. Deploy American options strategy
        optionsStrategy = _deployAmericanOptionsStrategy(
            baseStrategy,
            optionParams
        );
        
        // 4. Update hedge registry
        _updateHedgeStrategy(hedgeId, optionsStrategy);
    }
}
```

---

## Sequence Diagram Flow

### Complete Flow: Position → Metrics → Hedge Minting

```
User (LP)
  │
  ├─1. Mint LP Position───────► PositionManager
  │                              │
  │                              └─► Returns tokenId
  │
  ├─2. Subscribe to Metrics────► HedgeAggregator.subscribe(tokenId)
  │                              │
  │                              └─► [Metrics system already implemented]
  │                                  All metrics subscribe and update reactively
  │
  ├─3. Query Aggregated Metrics──► HedgeMetricsAggregator.getLatestMetrics(tokenId)
  │                              │
  │                              └─► Returns AggregatedMetrics {
  │                                    lpMetrics,
  │                                    volumeMetrics,
  │                                    oracleMetrics
  │                                  }
  │
  ├─4. Mint Generic Hedge───────► HedgeAggregator.mintHedge(params)
  │                              │
  │                              ├─► Validates ownership
  │                              ├─► Creates ERC1155 claim token (hedgeId)
  │                              ├─► Deploys BaseStrategy
  │                              └─► Sets up TimeLockController
  │
  ├─5a. Configure VIX Hedge─────► HedgeAggregator.configureVIXHedge(hedgeId, ...)
  │   │                          │
  │   │                          ├─► Queries VIXAdapter
  │   │                          ├─► Deploys VIXStrategy
  │   │                          └─► Links to BaseStrategy
  │   │
  │   └─5b. OR Configure Options► HedgeAggregator.configureAmericanOptions(hedgeId, ...)
  │                              │
  │                              ├─► Queries GreekFiAdapter
  │                              ├─► Deploys AmericanOptionsStrategy
  │                              └─► Links to BaseStrategy
  │
  └─6. Monitor & Settle─────────► TimeLockController (at maturity)
                                  │
                                  ├─► Strategy.settle()
                                  ├─► Calculate P&L
                                  └─► Emit Settlement event
```

---

## Key Architectural Decisions

### 1. **Separation of Concerns**
- Metrics system is already implemented and working independently
- Hedge minting is separate from hedge configuration
- Each hedge type (VIX, American Options) is a separate facet

### 2. **Diamond Pattern for Extensibility**
- `HedgeAggregator` uses Diamond pattern
- Each hedge type (VIX, American Options) is a separate facet
- New hedge types can be added without modifying core

### 3. **Two-Phase Hedge Creation**
- Phase 1: Generic hedge with shared parameters
- Phase 2: Hedge-specific configuration
- Allows for flexible hedge customization

---

## Implementation Priorities

### Phase 1: Hedge Minting Infrastructure
1. ⬜ Create `HedgeMintingFacet` for generic hedge creation
2. ⬜ Implement ERC1155 claim token system
3. ⬜ Create `BaseStrategy` template
4. ⬜ Integrate TimeLockController

### Phase 2: Hedge-Specific Configuration
1. ⬜ Create `VIXHedgeFacet` with VIXAdapter integration
2. ⬜ Create `AmericanOptionsFacet` with GreekFiAdapter integration
3. ⬜ Implement strategy catalog/registry

---

## Open Questions

1. **Strategy Catalog**: Should strategies be pre-deployed templates or deployed on-demand? What's the gas vs. flexibility tradeoff?

2. **Hedge Configuration Timing**: Can users configure hedge type immediately after minting, or should there be a time window?

3. **Metrics Integration**: How should hedge strategies access aggregated metrics? Direct calls to `HedgeMetricsAggregator` or passed as parameters?

4. **BaseStrategy Template**: What shared functionality should `BaseStrategy` provide? Settlement logic, P&L calculation, claim token management?

5. **TimeLockController Integration**: Should maturity be enforced at the strategy level or aggregator level?

---

## References

### Implementation References
- Uniswap V4 Periphery: `ISubscriber` interface
- Diamond Pattern: EIP-2535
- ERC1155: Multi-token standard for claims
- TimeLockController: OpenZeppelin implementation

### Theoretical Foundations (Required Reading)

#### Derivative Pricing & Options Theory
1. **Hull, John C.** "Options, Futures, and Other Derivatives" (10th Edition)
   - Chapters 13-15: Options pricing, Greeks
   - Chapters 20-21: Volatility, variance swaps
   
2. **Natenberg, Sheldon.** "Options Volatility & Pricing"
   - Chapters 1-5: Options fundamentals
   - Chapters 10-12: Greeks, hedging strategies
   
3. **Taleb, Nassim.** "Dynamic Hedging: Managing Vanilla and Exotic Options"
   - Chapters 1-3: Dynamic hedging, Greeks management

#### Variance Swaps & Volatility
4. **Sinclair, Euan.** "Volatility Trading"
   - Chapters 1-4: Volatility fundamentals
   - Chapters 8-10: Variance swaps, VIX
   
5. **Gatheral, Jim.** "The Volatility Surface: A Practitioner's Guide"
   - Complete book: Volatility modeling, term structure
   
6. **Carr, Peter & Madan, Dilip.** "Towards a Theory of Volatility Trading" (1998)
   - Variance swap pricing theory
   
7. **Carr, Peter & Lee, Roger.** "A New Approach for Pricing Derivatives" (2009)
   - Variance swap mechanics

#### LP Risk & CFMM Theory
8. **Milionis, Jason et al.** "Automated Market Making and Loss-Versus-Rebalancing" (2022)
   - LP position cost function
   - Impermanent loss theory
   
9. **Angeris, Guillermo et al.** "An Analysis of Uniswap Markets" (2020)
   - CFMM mechanics, LP returns
   
10. **Angeris, Guillermo et al.** "Replicating Market Makers" (2021)
    - LP position replication, hedging

#### Market Microstructure & Execution
11. **O'Hara, Maureen.** "Market Microstructure Theory"
    - Market impact, liquidity
   
12. **Almgren, Robert & Chriss, Neil.** "Optimal Execution of Portfolio Transactions" (2000)
    - Execution costs, market impact

#### Stochastic Volatility Models
13. **Heston, Steven L.** "A Closed-Form Solution for Options with Stochastic Volatility" (1993)
    - Heston model for volatility
    
14. **Hagan, Patrick S. et al.** "Managing Smile Risk" (2002)
    - SABR volatility model

#### VIX & Volatility Index
15. **Whaley, Robert E.** "Understanding VIX" (2009)
    - VIX calculation, interpretation
    
16. **Bollerslev, Tim et al.** "Expected Stock Returns and Variance Risk Premium" (2009)
    - Variance risk premium theory

#### DeFi-Specific Research
17. **Adams, Hayden et al.** "Uniswap V3 Core" (2021)
    - Concentrated liquidity mechanics
    
18. **Topaze Blue.** "Uniswap V3 Impermanent Loss" (2021)
    - IL calculation for V3 positions

---

## Study Roadmap: Understanding Critical Components

### Phase 1: Derivative Fundamentals (Weeks 1-2)
**Goal**: Understand why maturity and hedge types are critical

1. **Week 1**: Options & Derivatives Basics
   - Read: Hull Chapters 13-15 (Options pricing, time value)
   - Read: Natenberg Chapters 1-5 (Options fundamentals)
   - **Key Takeaway**: Understand why derivatives expire and how time value works

2. **Week 2**: Volatility & Variance Swaps
   - Read: Sinclair Chapters 1-4, 8-10 (Volatility trading)
   - Read: Carr & Madan (1998) "Variance Swaps"
   - **Key Takeaway**: Understand variance swap mechanics and why maturity is essential

### Phase 2: LP Risk Theory (Weeks 3-4)
**Goal**: Understand what metrics are needed for hedging LP positions

1. **Week 3**: CFMM & LP Position Theory
   - Read: Milionis et al. (2022) "Automated Market Making"
   - Read: Angeris et al. (2021) "Replicating Market Makers"
   - **Key Takeaway**: Understand LP position cost function and risk decomposition

2. **Week 4**: LP Hedging Strategies
   - Read: "Hedging Uniswap V3 LP Positions" papers
   - Read: Angeris et al. (2020) "Impermanent Loss"
   - **Key Takeaway**: Understand which hedge type (VIX vs Options) hedges which risk

### Phase 3: Metrics & Greeks (Weeks 5-6)
**Goal**: Understand theory-grounded metrics for baseParameters

1. **Week 5**: Options Greeks & Hedging
   - Read: Taleb "Dynamic Hedging" Chapters 1-3
   - Read: Natenberg Chapters 10-12 (Greeks)
   - **Key Takeaway**: Understand Delta, Gamma, Theta, Vega and their role in hedging

2. **Week 6**: Volatility Modeling
   - Read: Gatheral "The Volatility Surface"
   - Read: Heston (1993) Stochastic Volatility
   - **Key Takeaway**: Understand realized vs implied volatility, variance risk premium

### Phase 4: Implementation (Weeks 7-8)
**Goal**: Understand how to implement maturity and metrics collection

1. **Week 7**: TimeLockController & Settlement
   - Study: OpenZeppelin TimelockController
   - Study: EIP-2535 Diamond Standard
   - **Key Takeaway**: Understand how to enforce maturity and execute settlement

2. **Week 8**: Metrics Collection & Aggregation
   - Study: Current HedgeLPMetrics implementation
   - Design: Metrics aggregation for baseParameters
   - **Key Takeaway**: Understand how to collect and aggregate theory-grounded metrics

---

## Quick Reference: Why Each Component is Critical

### Maturity (TimeLockController)
- **Theory**: Derivative contracts must expire at maturity for proper settlement
- **Math**: Variance swaps require full period [t₀, T] to calculate realized variance
- **LP Context**: Hedge duration must match LP holding period to avoid over/under-hedging
- **Implementation**: TimeLockController enforces expiration and triggers settlement

### HedgeType (VIX | AMERICAN_OPTIONS)
- **Theory**: Different derivatives hedge different risk factors (volatility vs. price)
- **Math**: VIX hedges Vega (volatility), Options hedge Delta/Gamma (price)
- **LP Context**: LP positions have both volatility risk and directional risk
- **Implementation**: User selects hedge type based on dominant risk factor

### BaseParameters (Theory-Grounded Metrics)
- **Theory**: Derivative pricing models require specific inputs (price, volatility, time, Greeks)
- **Math**: Black-Scholes, variance swap pricing formulas require these metrics
- **LP Context**: LP position risk decomposition requires position, volatility, and price metrics
- **Implementation**: Metrics collected from HedgeLPMetrics, HedgeVolumeMetrics, HedgeExternalOracle

