# Branch Setup: feat/hedge-minting

## Summary

Created new branch `feat/hedge-minting` from `feat/hedging` with the following configuration:

## ✅ Completed Setup

### 1. Branch Creation
- **Branch**: `feat/hedge-minting`
- **Created from**: `feat/hedging`
- **Date**: November 13, 2025

### 2. Source Code Directories (Cleared)
- ✅ `src/` - All `.sol` files removed, directories preserved with `.gitkeep`
- ✅ `test/` - All `.sol` files removed, directories preserved with `.gitkeep`
- ✅ `script/` - All `.sol` files removed, directories preserved with `.gitkeep`

### 3. Preserved Infrastructure
- ✅ `foundry.toml` - Foundry configuration
- ✅ `remappings.txt` - Solidity remappings
- ✅ `.gitmodules` - Git submodules configuration
- ✅ `foundry.lock` - Dependency lock file
- ✅ All `lib/` dependencies preserved

### 4. Library Dependencies (15 total)
- ✅ `lib/Compose` - Diamond pattern implementation
- ✅ `lib/Subscription` - **NEW**: feat/Subscription branch dependency
- ✅ `lib/createx` - Contract creation utilities
- ✅ `lib/euler-price-oracle` - Price oracle
- ✅ `lib/euler-vault-kit` - Vault kit
- ✅ `lib/forge-std` - Foundry standard library
- ✅ `lib/foundry-devops` - DevOps utilities
- ✅ `lib/limit-order-protocol` - Limit order protocol
- ✅ `lib/op-hook` - Options hooks
- ✅ `lib/reactive-smart-contract-demos` - Reactive contracts
- ✅ `lib/solady` - Solady library
- ✅ `lib/system-smart-contracts` - System contracts
- ✅ `lib/universal-router` - Universal Router
- ✅ `lib/v4-periphery` - Uniswap V4 periphery
- ✅ `lib/vixdex` - VIX integration

### 5. Subscription Dependency Configuration

**Added to `.gitmodules`**:
```ini
[submodule "lib/Subscription"]
	path = lib/Subscription
	url = https://github.com/wvs-finance/wvs-contracts.git
	branch = feat/Subscription
```

**Note**: The `feat/Subscription` branch will be tracked when it becomes available on the remote repository. Currently, the submodule points to the main repository and will automatically switch to `feat/Subscription` when the branch is created.

## Directory Structure

```
feat/hedge-minting/
├── lib/                    # All dependencies preserved
│   ├── Subscription/       # NEW: feat/Subscription branch
│   └── ...                 # All other dependencies
├── src/                    # Empty (only .gitkeep files)
│   ├── hedging/
│   └── login/
├── test/                   # Empty (only .gitkeep files)
│   ├── hedging/
│   └── fork/
├── script/                 # Empty (only .gitkeep files)
│   └── hedging/
├── foundry.toml            # ✅ Preserved
├── remappings.txt          # ✅ Preserved
├── .gitmodules             # ✅ Updated with Subscription
└── foundry.lock            # ✅ Preserved
```

## Next Steps

1. **Update Subscription submodule** when `feat/Subscription` branch is created:
   ```bash
   git submodule update --remote lib/Subscription
   ```

2. **Start implementing hedge minting**:
   - ERC1155 token minting
   - Hedge registry
   - Vault strategy deployment
   - Maturity lock setup

3. **Use Subscription dependency**:
   - Import from `lib/Subscription/src/...`
   - Reference subscription functionality as needed

## Verification

- ✅ No `.sol` files in `src/`, `test/`, or `script/`
- ✅ All library dependencies preserved
- ✅ Subscription submodule configured
- ✅ Foundry configuration intact
- ✅ Remappings preserved

