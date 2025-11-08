- Create the SocketManager contract on the Reactive Network chain to go ahead and deploy the SocketContract associated with
the user's logged in address
  - The Socket is a MinimalProxy
  - The Socket is a AsbtractPausableReactive
  - The Socket hears the PositionManager




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