
- Let's test the Socketcontract with non susbcription at deployment but dynamic susbcription management. The socket must store the following on its bytecode

```solidity
struct Endpoint{
  uint256 chain_id;
  address origin;
  address destination;
  bytes4[] event_selectors;
}
```


















- Create the SocketManager contract on the Reactive Network chain to go ahead and deploy the SocketContract associated with

- The user log-in on the extension interface using its address.




- A user has a set of chains they will listen
```solidity

mapping(address _user => uint256[] chainids) origins;
mapping(uint256 _chainid => Endpoint) endpoints;
mapping(uint256 _chainid => address _origin) origins;
mapping(uint256 _chainid => address _destination) destinations
// INVARIANT origins[x] ^ origins[x]

struct Endpoint{
  bytes selectors;
  bytes[] arbitrary_data;
}

//-> The selectors must belongo to events on the _origin interface or it's childs
// -> The data can be anything

```
- The user selects the chains where they will provide liquidity, montitor, etc

```solidity

// Implemenation specific
address position_manager;
bytes4 mint_position_selector;

function listen(
  uint256[] calldata _chain_ids,
  bytes[] calldata _arbitrary_data,
  address[] calldata _destinations
) external{

  /// destinations must be on the same chain as origins
///===========THIS IS THE PATH FOR THE FIRST TIME USER ==============
  
  // 1. Set's the origin to the user
  origins[msg.sender] = _chain_ids;
  // 2. Start the endpoint with the events we wnat to listen
  Endpoint memory endpoint = EndpointLib.__init__();
  Endpoint memory endpoint = endpoint.add(
    mint_position_selector,
    abi.encode(msg.sender)
  );

  // 3. Defines as endpoint the position manager 
  for (uint256 index; index< _chain_ids.length; index++){
    endpoints[_chain_ids[index]] = endpoint;
    // 4. Deploy per chain-id a socket that hears the event
    // NOTE: The fact that is firts time gurantees it does not
    // deploy duplicated sockets
    address _chain_socket = deploy_socket(
      _chain_ids[index],
      endpoint,
      _destinations[index]
    );

  }
}
```
- Once the socket is deployed it subscribes to the endpoint.
(The data on endpoint.data) is stored on the socket's bytecode metadata and is only accessible to destination contracts.

```solidity

contract Socket is AbstractPausableReactive{
  
  struct SocketStorage{
    uint256 chain_id;
    address origin;
    Endpoint endpoint;
    address destination;
  }

  constructor(
    uint256 _chain_id,
    address _origin_contract,
    Endpoint calldata _endpoint,
    address _destination_contract  
  ) payable {
    // This is reactive network only
    
    if (!vm){
      for (uint256 index; index < _endpoint.selectors.length; index++){
           
           bytes4 _event_selector = bytes4(_endpoint.selectors[index]);
           
           service.subscribe(
              _chain_id;
              _origin_contract;
              uint256(bytes32(_endpoint._event_selector)),
              REACTIVE_IGNORE,
              REACTIVE_IGNORE,
              REACTIVE_IGNORE
            );


      }
      
    }
    // NOTE: vM IS SET READY TO HEAR THE EVENTS
    vm = true;
  }
}
```

- The subscription is ACTIVE, now if someone mints a position. Then the socket sends the data stored on SocketStorage plus the event data to the Destination.

This is

```solidity
contract Socket is AbstractPausableReactive{
  function react(LogRecord calldata log) external vmOnly{
    
    SocketStorage storage $ = getStorage();
    
    if (
      log._contract == $.origin &&
      log.chain_id == $.chain_id &&
      $.endpoint.event_selectors.any(bytes4(bytes32($.topic_0)))
    ){
      bytes memory _event_data = abi.encode(
        log.topic_1,
        log.topic_2,
        log.topic_3,
        log.data
      );
      bytes memory _destinaton_payload = abi.encodeWithSignature(
        "on_log(address,bytes memory, bytes[] memory)",
          address(0x00),
          _event_data,
          $.endpoint.data
      );
      emit Callback($.chain_id, $.destination, CALLBACK_GAS_LIMIT,_destinaton_payload);
    }

    
  }
} 
```
- Now the destination performos custom action on it. This is:

```solidity

abstract contract Destination is AbstractCallback{

  function on_log(
    address _rvm_id,
    bytes memory _log_data,
    bytes[] memory _origin_data
  )
  external 
  rvmIdOnly(_rvm_id)
  {
    _on_log(_log_data, _origin_data);
  }
}
```






























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