
# VIX $\hat{\sigma}$
- estimates the risk measurement of underlyings 

- informs of market status of underlying

- hedges against volatility or lack thereof

- calculated from underlyings option prices
- calculated using __Black-Scholes option pricing model__

- tracks the 30-day __implied volatility__ of underlyings
- operates on a scale from 0 to 200



## Calculation

- uses the __Black-Scholes option pricing model__
- integrates the __implied volatility__ derived from underlyings option prices
- incorporates the market's projections of future volatility.
- efficient subject to a robust options exchange ecosystem
- uses adapters on oracles from underlyinngs for deriving their option prices
- aggregates option prices from adapters to form a singular, consolidated __option price index__.
- broadcasts __option price index__ on-chain

### Option Price Index
- is accessible for smart contracts
- is used for:
    - settling derivatives contracts
    - adjust trading strategies based on real-time volatility metrics


### Implied Volaitlity

## Trading

- allows traders $\Pi (\overbrace{\sigma}^{+}), \underbrace{\partial_P \Pi = 0}_{\text{agnostic to price direction}}$

## Market -> AMM

- is the liquidity provider of volatility
- sells volatility according to the index value


## $(vX/ (Y/X))$
> Hedged Theta Vault
- trading fees are given in Y to LP's

- mitigates the one-sided exposure risk that is commonly associated with liquidity pools in DeFi platforms.


```
                                                                        AMM
                                     ------adds/removes liquidity --> ( $/X ) 
                                    /
user -- deposit/withdraw X ---> Vault(X) --------- (liquidity share token)     
    \                                             \-------d ($/X)-------------> (vX/($/X))
     ----> mints/burns vX ---------------d(vX) ---------------------->     
```
## LP Revenue
### Trading Fees $\phi^{\Delta}$
- is transaction based revenue

$$
\partial_{\phi^{\Delta}} Y = \int_{\Delta} \phi^{\Theta} ( \Delta)
$$ 

- compensate LP's for creating markets

### Funding Fees $\phi^{\Theta}$
- time-based revenue:
$$
\partial_{\phi^{\Theta}} Y = \int_{t_0}^{T} \phi^{\Theta} (t)
$$ 
- compensate LP'S for taking opposite positions

## Volatility Token

For token $X$ defines $vX$ such that:

### Design Goals
- hedge and delta exposure to $\hat{\sigma}$
    - $P_{\$/{vX}} \big ( \hat{\sigma} \big)$
- account for time decay, while keeping semantic meaning for token price
    - $\partial_t \,P_{\$/{vX}} $


- user can also swap vX against $, since vX is fungible






