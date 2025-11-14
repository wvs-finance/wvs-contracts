Has Compose handle extensions, How it does it ?

- These are extensions of the token interface itself and not entities interacting with the token as receivers or issuers $T_t$

ERC20 --> time-extension [ERC-7818](https://eip.tools/eip/7818)

ERC721 --> time-extension [ERC-5007](http://eip.tools/eip/5007)


Then::
$$
T_t.\text{interface} ---mint/transfer(id: i, at: t, to: j)---> \big (T_{ijt}.\text{interface} \big)
$$

- These are extensions for entities $j$ that interact with the token $i$ as issuers or recievers all related with time operations $t$, $T_{ijt}$

- These entities define roles for proposing, canceling, and executing operations constrained by time $t$

- Timelock best used as minimal proxy

```
                                  (execution) 
( Timelock OR TimeLockController ) -----------> ERC7821 
    (on-behalf)
-----------------> Receiver
```

- A special case of time-controlled operations on tokens that are external $T_{ijt}$ is token approvals; the entity defines approval with a deadline using permit on ERC2616.



## DeFi State of Art

How derivative DeFi contracts are handling time related architectures for maturity and other related events ?

What are some common patterns and EIP's used

### Common Patterns

- Pendle : PendleYieldToken --> IOptionToken --> expirationDate()--> PostExpiryData

- 1Innch : limit-order-protocol --> MakerTraits --> bitmask(expirationDate)

### Settlement Patterns

1. **Automatic Settlement**: Triggered on first post-expiry interaction
2. **Manual Settlement**: Requires explicit call to `setPostExpiryData()`
3. **Treasury Collection**: Post-expiry rewards/interests go to treasury
4. **User Claims**: Users can redeem expired positions with different logic