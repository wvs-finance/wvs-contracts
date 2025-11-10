# CREATE2 Solution for CreateCollision

## Problem

When deploying contracts on different forks using the same deployer address, you encounter `CreateCollision` because:
- Standard `CREATE` uses: `address = keccak256(rlp([deployer, nonce]))`
- Same deployer + same nonce = same address
- If that address already has code on a fork, collision occurs

## CREATE2 Solution

CREATE2 allows deterministic address calculation using a **salt** instead of nonce:

```
address = keccak256(0xff || deployer || salt || keccak256(bytecode))
```

### Benefits

1. **Same deployer address** - Can use `user` for all deployments
2. **Deterministic** - Same salt + bytecode = same address
3. **No collisions** - Different salts = different addresses
4. **Fork-safe** - Salt includes chain ID, ensuring uniqueness

## Implementation

### Solidity Syntax

```solidity
// CREATE2 deployment with salt
bytes32 salt = keccak256(abi.encodePacked("unique-identifier", chainId));
address contractAddress = address(new ContractName{salt: salt}());
```

### Your Code

```solidity
function deploy_reactive(uint256 _pay_to_deploy) internal{
    vm.selectFork(reactive_fork);
    assertEq(block.chainid, REACTIVE_CHAIN_ID);
    vm.deal(user, _pay_to_deploy);
    
    // Use CREATE2 with unique salt per fork
    bytes32 reactive_salt = keccak256(abi.encodePacked("reactive", REACTIVE_CHAIN_ID));
    
    vm.startPrank(user);
    socket_server = address(new SocketServerHarness{salt: reactive_salt}());
    bytes32 reactive_salt_impl = keccak256(abi.encodePacked("reactive-impl", REACTIVE_CHAIN_ID));
    socket_implementation = address(new SocketHarness{salt: reactive_salt_impl}());
    vm.stopPrank();
    
    vm.makePersistent(socket_server, socket_implementation);
}

function deploy_unichain(uint256 _pay_to_deploy) internal{
    vm.selectFork(unichain_fork);
    assertEq(block.chainid, UNICHAIN_CHAIN_ID);
    vm.deal(user, _pay_to_deploy);
    
    // Same deployer (user) but different salts = different addresses
    bytes32 unichain_salt_endpoint = keccak256(abi.encodePacked("unichain-endpoint", UNICHAIN_CHAIN_ID));
    bytes32 unichain_salt_listener = keccak256(abi.encodePacked("unichain-listener", UNICHAIN_CHAIN_ID));
    
    vm.startPrank(user);
    endpoint = address(new MockEndpoint{salt: unichain_salt_endpoint}());
    listener = address(new ListenerHarness{salt: unichain_salt_listener}());
    vm.stopPrank();
    
    vm.makePersistent(endpoint, listener);
}
```

## Salt Strategy

### Why Include Chain ID?

```solidity
bytes32 salt = keccak256(abi.encodePacked("identifier", chainId));
```

- **Uniqueness**: Different chains = different salts = different addresses
- **Predictability**: Same chain + same identifier = same address
- **Safety**: Prevents accidental collisions across forks

### Salt Components

Good salt includes:
1. **Purpose identifier**: `"reactive"`, `"unichain-endpoint"`, etc.
2. **Chain ID**: Ensures fork-specific addresses
3. **Optional**: Additional uniqueness factors if needed

## Address Calculation

### CREATE (Standard)
```
address = keccak256(rlp([deployer_address, nonce]))
```

### CREATE2 (With Salt)
```
address = keccak256(0xff || deployer_address || salt || keccak256(bytecode))
```

## Advantages Over Different Deployers

| Aspect | Different Deployers | CREATE2 with Salt |
|--------|---------------------|-------------------|
| Same deployer | ❌ No | ✅ Yes |
| Deterministic | ⚠️ Depends on nonce | ✅ Fully deterministic |
| Fork-safe | ✅ Yes | ✅ Yes |
| Complexity | ✅ Simple | ⚠️ Slightly more complex |
| Gas cost | Same | Same |

## Testing

Run your tests:
```bash
forge test --match-test test__fork__socketServerListen -vvv
```

Expected behavior:
- ✅ Same `user` address for all deployments
- ✅ No CreateCollision errors
- ✅ Deterministic addresses per fork
- ✅ Contracts deploy successfully

## Troubleshooting

### If CREATE2 fails:

1. **Check Solidity version**: Requires 0.8.0+
2. **Verify bytecode**: CREATE2 requires exact bytecode match
3. **Check salt uniqueness**: Ensure salts are different for each deployment
4. **Address already exists**: If address has code, you'll still get CreateCollision

### Pre-compute Address (Optional)

```solidity
// Compute address before deploying
address computedAddress = vm.computeCreate2Address(
    salt,
    keccak256(type(ContractName).creationCode)
);

// Check if it exists
if (computedAddress.code.length > 0) {
    // Reuse existing
    contractAddress = computedAddress;
} else {
    // Deploy new
    contractAddress = address(new ContractName{salt: salt}());
}
```

## References

- [EIP-1014: CREATE2](https://eips.ethereum.org/EIPS/eip-1014)
- [Solidity CREATE2 Documentation](https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2)
- Foundry `vm.computeCreate2Address()` cheatcode

