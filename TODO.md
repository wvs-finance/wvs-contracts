- Assuming the login is successful anD the reactive contracts are tracking the mint position evenmnt for the LP address and also the portafolioRegistry is subscribed to the LP poition



======================Hedging========================

- Once user mints a position get's the token Id then it enters the token id

(It checks the position belongs to the logged in user address)


- Now we have (token_id, owner | owner = user.login.address)

- The portafolioRegistry subscribes to this token id

A position hedge is a collection of derivative positions whose underlying is defined by the position cost function $c_i$ associated with the original token ID of the LP position.

$$
H_i = \bigg \{h_{ij}\bigg\}_{j}
$$

- $H_i$ subscribes to $i$
- $H_i$ offers metrics tracking to all $i$

- $H_i$ offers market place functionality for $h_{ij}$ for $j := \text{variance swaps} \vee j:= \text{american options}$

- $H_i$ is a `HedgeAggregator`
- $H_i$ is a Diamond which facets are the services it offers to each $j(i)$

====1. Metrics Cycle (offered to every hedge)

- Once deployed the front can query 

```solidity
event MetricsData(uint256 indexed_token_id, uint80 indexed, bytes _data)
```
- This shows  the metrics needed for decision making on
managing derivatives.



- The login service passses the tokenid of teh position and it's owner to the Facet  in charge of subscribing the user to the positions


======== Integration with VIX
- I am an LP and already have a position on a Uniswap V3 Pair. I want to use variance swaps to hedge mmy position dynamically
to do so:

- I query the parameters I need to define the maturity.
  
- I query/calculate the needed data to adapt WVS to VIX HIGH/lOW token

- Based on those calculations come up with a strategy (Reactive contract) + Privay by Fhenix
  to dynamically sell such instrument until maturity
    - Mauturity is enforced via TimeLockContorollers

- Strategies inherit from a template (BaseStrategy) and can be customized (There needs to be a catalog) of strategies already deployed

- The moment maturity ends, the instrumnets are settled and the LP receives the event and can decide on wiothdraing, or re-balance the position 

- The ERC1155 is used for claims and help displaying fro dashborad on strtegy performance, specially for metadata