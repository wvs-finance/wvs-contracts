# Sequence Diagram: Multi-Metrics & Hedge Minting Flow

## Text-Based Sequence Diagram (for Excalidraw)

### Actors/Components:
- **LP (User)**: Liquidity Provider
- **PM**: PositionManager (Uniswap V4)
- **HA**: HedgeAggregator (Diamond)
- **HSM**: HedgeSubscriptionManager (Facet)
- **HLPM**: HedgeLPMetrics (ISubscriber)
- **HVM**: HedgeVolumeMetrics (ISubscriber) [NEW]
- **HEO**: HedgeExternalOracle (ISubscriber) [NEW]
- **HMA**: HedgeMetricsAggregator (Facet) [NEW]
- **HM**: HedgeMintingFacet [NEW]
- **VIX**: VIXHedgeFacet [NEW]
- **AO**: AmericanOptionsFacet [NEW]

---

## Sequence 1: Initial Subscription Flow

```
LP -> PM: mintPosition()
PM --> LP: tokenId

LP -> HA: subscribe(tokenId, lpAccount)
HA -> HSM: subscribe(tokenId, lpAccount)
HSM -> HSM: createProxy(HedgeLPMetrics)
HSM -> HSM: createProxy(HedgeVolumeMetrics)
HSM -> HSM: createProxy(HedgeExternalOracle)
HSM -> PM: subscribe(tokenId, HedgeLPMetrics)
HSM -> PM: subscribe(tokenId, HedgeVolumeMetrics)
HSM -> PM: subscribe(tokenId, HedgeExternalOracle)
PM -> HLPM: notifySubscribe(tokenId, data)
PM -> HVM: notifySubscribe(tokenId, data)
PM -> HEO: notifySubscribe(tokenId, data)
HLPM -> HLPM: Store initial metrics
HLPM --> LP: MetricsData(tokenId, time_key, lp_metrics)
HVM -> HVM: Store initial volume metrics
HVM --> LP: MetricsData(tokenId, time_key, volume_metrics)
HEO -> HEO: Store initial oracle metrics
HEO --> LP: MetricsData(tokenId, time_key, oracle_metrics)
HSM --> LP: Subscribed(tokenId, lp_metrics_lens)
```

---

## Sequence 2: Liquidity Change → Metrics Update

```
LP -> PM: modifyLiquidity(tokenId, liquidityDelta)
PM -> PM: _modifyLiquidity()
PM -> PM: poolManager.modifyLiquidity()
PM -> PM: _notifyModifyLiquidity(tokenId, ΔL, fees)

PM -> HLPM: notifyModifyLiquidity(tokenId, ΔL, fees)
HLPM -> HLPM: getPoolAndPositionInfo(tokenId)
HLPM -> HLPM: Recalculate LP metrics
HLPM -> HLPM: Store metrics[time_key] = new_data
HLPM --> LP: MetricsData(tokenId, time_key, updated_lp_metrics)

PM -> HVM: notifyModifyLiquidity(tokenId, ΔL, fees)
HVM -> HVM: Calculate volume impact
HVM -> HVM: Store volume_metrics[time_key] = new_data
HVM --> LP: MetricsData(tokenId, time_key, updated_volume_metrics)

PM -> HEO: notifyModifyLiquidity(tokenId, ΔL, fees)
HEO -> HEO: Check price impact threshold
HEO -> HEO: Query external oracle if needed
HEO -> HEO: Store oracle_metrics[time_key] = new_data
HEO --> LP: MetricsData(tokenId, time_key, updated_oracle_metrics)

PM --> LP: modifyLiquidity() success
```

---

## Sequence 3: Query Aggregated Metrics

```
LP -> HA: getLatestMetrics(tokenId)
HA -> HMA: getLatestMetrics(tokenId)
HMA -> HLPM: get_metrics(latest_time_key)
HLPM --> HMA: lp_metrics_data
HMA -> HVM: get_metrics(latest_time_key)
HVM --> HMA: volume_metrics_data
HMA -> HEO: get_metrics(latest_time_key)
HEO --> HMA: oracle_metrics_data
HMA -> HMA: Aggregate all metrics
HMA --> LP: AggregatedMetrics {
    lpMetrics,
    volumeMetrics,
    oracleMetrics
}
```

---

## Sequence 4: Generic Hedge Minting

```
LP -> HA: mintHedge(GenericHedgeParams)
HA -> HM: mintHedge(params)
HM -> HM: Validate position ownership
HM -> HM: _mintClaimToken(tokenId, lp)
HM -> HM: Deploy BaseStrategy(hedgeId)
HM -> HM: Setup TimeLockController(maturity)
HM --> LP: HedgeMinted(hedgeId, tokenId, hedgeType)
HM --> LP: (hedgeId, baseStrategy)
```

---

## Sequence 5a: Configure VIX Hedge

```
LP -> HA: configureVIXHedge(hedgeId, varianceStrike, notional)
HA -> VIX: configureVIXHedge(hedgeId, ...)
VIX -> VIX: Get baseStrategy(hedgeId)
VIX -> VIXAdapter: getVIXParams(varianceStrike, notional)
VIXAdapter --> VIX: VIXParams
VIX -> VIX: Deploy VIXStrategy(baseStrategy, vixParams)
VIX -> VIX: Update hedge registry
VIX --> LP: VIXStrategy deployed
```

---

## Sequence 5b: Configure American Options Hedge

```
LP -> HA: configureAmericanOptions(hedgeId, strike, optionType, notional)
HA -> AO: configureAmericanOptions(hedgeId, ...)
AO -> AO: Get baseStrategy(hedgeId)
AO -> GreekFiAdapter: getOptionParams(strike, optionType, notional)
GreekFiAdapter --> AO: OptionParams
AO -> AO: Deploy AmericanOptionsStrategy(baseStrategy, optionParams)
AO -> AO: Update hedge registry
AO --> LP: AmericanOptionsStrategy deployed
```

---

## Sequence 6: Maturity & Settlement

```
TimeLockController -> Strategy: maturity reached
Strategy -> Strategy: settle()
Strategy -> Strategy: Calculate P&L
Strategy -> Strategy: Update ERC1155 claims
Strategy --> LP: Settlement(hedgeId, pnl)
LP -> Strategy: withdrawClaims(hedgeId)
Strategy --> LP: Transfer claim tokens
```

---

## Visual Layout Suggestions for Excalidraw

### Vertical Layout:
1. **Top Section**: User/LP
2. **Second Section**: HedgeAggregator (Diamond) with facets
3. **Third Section**: PositionManager
4. **Fourth Section**: Metrics Subscribers (HLPM, HVM, HEO)
5. **Bottom Section**: External Adapters (VIX, GreekFi)

### Color Coding:
- **Blue**: User actions
- **Green**: Subscription flows
- **Orange**: Metrics updates
- **Purple**: Hedge minting
- **Red**: Configuration flows
- **Gray**: Settlement

### Key Interactions to Highlight:
1. **Subscription**: Multiple arrows from HSM to metrics contracts
2. **Cascading Updates**: Parallel notifications from PM to all metrics
3. **Aggregation**: HMA collecting from all metrics
4. **Two-Phase Hedge**: Generic mint → Specific configuration

