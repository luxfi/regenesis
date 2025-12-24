# Lux Regenesis - AI Assistant Context

## Current Status (2025-10-28)

### ✅ Completed
1. **100 Validators Generated** - All 100 mainnet + 100 testnet validator keys derived from test mnemonic
2. **Genesis Configuration** - Valid genesis created with proper unlockSchedule and staking
3. **Node Port Configuration** - Changed from 9650 to 9630 as required
4. **Bootstrap Scripts** - All scripts updated for 5-node network
5. **Node Binary Built** - Successfully compiled luxd with latest changes

### 🚧 Current Blockers

#### C-Chain VM Plugin Issue
- **Problem**: Node expects C-Chain VM plugin but we don't have it built yet
- **Error**: `"error creating required chain: "mgj786NP7uDwBCcq6YwThhaN8FLyybkCa4zBWTQbNgmK6k9A6" was not found"`
- **VM ID**: `mgj786NP7uDwBCcq6YwThhaN8FLyybkCa4zBWTQbNgmK6k9A6` (likely CorethVM/C-Chain)

#### SubnetEVM Build Issues (CRITICAL - FIXED SNOW REFERENCES)
**Fixed**: Removed all `github.com/luxfi/consensus/snow` imports - using `github.com/luxfi/consensus` instead

**Remaining Issues**:
1. **IDs package conflicts**: Mismatch between `github.com/luxfi/ids` and `github.com/luxfi/node/ids`
   - `AppGossip` method signature mismatch
   - NodeID type mismatch in handlers
2. **Logger interface mismatch**: `github.com/luxfi/log.Logger` vs `logging.Logger`
   - Different Debug method signatures
3. **Set API changes**: `Peek()` method missing from `github.com/luxfi/math/set.Set`
4. **Geth API changes**: `StartPrefetcher` signature changed (needs witness parameters)

#### Investigation Findings
1. The cchainvm in `/Users/z/work/lux/node/vms/cchainvm` implements `block.ChainVM` from luxfi/consensus package
2. Node expects VMs to implement `snowman.ChainVM` from node package
3. Interface mismatch prevents using built-in cchainvm
4. Need to build C-Chain VM as external plugin
5. **NEVER use snow packages** - always use `github.com/luxfi/consensus` (✅ FIXED)

### 📋 Required VM Plugins

User needs TWO VM plugins for runtime replay:
1. **CoreVM (C-Chain)**: VM ID `mgj786NP7uDwBCcq6YwThhaN8FLyybkCa4zBWTQbNgmK6k9A6`
   - For the new C-Chain that will receive replayed data
   - Should be built from `/Users/z/work/lux/geth` or coreth

2. **SubnetEVM**: VM ID `srEXiWaHuhNyGwPUi444Tu47ZEDwxTWrbQiuD7FmgSAQ6X7Dy`
   - For running old subnet 96369 (replay source)
   - Should be built from `/Users/z/work/lux/evm`
   - Build failed: missing `github.com/luxfi/consensus/snow` dependency

### 🎯 Next Steps

1. **Build CoreVM Plugin**:
   - Determine correct source (geth vs coreth vs need to create wrapper)
   - Build as plugin binary named after VM ID
   - Place in plugins directory

2. **Fix SubnetEVM Build**:
   - Resolve missing consensus/snow dependency
   - Build SubnetEVM plugin

3. **Plugin Installation**:
   - Create plugins directory: `~/.lux/plugins` or per-node `<data-dir>/plugins`
   - Copy built VMs with correct names

4. **Launch Network**:
   - Start 5 bootstrap nodes
   - Verify P-Chain, X-Chain, and C-Chain all start
   - Run health checks

## Architecture Notes

### VM Plugin System
- Node loads VMs as separate executables via RPC
- Plugin filename (minus extension) must match VM ID (cb58 encoded)
- Located in:
  - Global: `$LUXD_DATA_DIR/plugins` or default `~/.node/plugins`
  - Per-node: `<data-dir>/plugins`

### Genesis Configuration
- Located: `/Users/z/work/lux/regenesis/output/config/mainnet/genesis.json`
- Network ID: 96369
- Contains cChainGenesis as JSON string
- Valid with proper unlockSchedule and initialStakedFunds

### Validator Keys
- 100 validators generated from test mnemonic
- Located: `/Users/z/work/lux/regenesis/output/validators/mainnet/node{1-100}/`
- Each has staker.key, staker.crt, NodeID
- First 5 (node1-5) are bootstrap validators

### Network Ports
- **HTTP**: 9630, 9632, 9634, 9636, 9638
- **Staking**: 9631, 9633, 9635, 9637, 9639
- **IMPORTANT**: Using 9630 NOT 9650!

## Key Files

### Scripts
- `/Users/z/work/lux/regenesis/scripts/generate-validators.sh` - Generates 100 validators
- `/Users/z/work/lux/regenesis/scripts/launch-network.sh` - Starts 5 bootstrap nodes
- `/Users/z/work/lux/regenesis/scripts/stop-network.sh` - Stops all nodes

### Configuration
- `.env` - Test mnemonic and network config
- `Makefile` - Orchestrates all phases
- `REGENESIS_PLAN.md` - Complete architecture and plan

### Node Modifications
- `/Users/z/work/lux/node/node/node.go:1200` - C-Chain VM registration disabled (loading as plugin)
- `/Users/z/work/lux/node/vms/cchainvm/factory.go` - Factory signature fixed but not used

## Remaining Tasks

### Before Public Release (v0.1.0)
1. ✅ Generate 100 validators
2. ✅ Configure genesis
3. ⏳ Build VM plugins (CoreVM + SubnetEVM)
4. ⏳ Launch 5-node network successfully
5. ⏳ Verify all chains (P, X, C) operational
6. ⏳ Update key storage to ~/.lux/keys with address prefixes
7. ⏳ Test all components compile
8. ⏳ Commit all changes
9. ⏳ Tag v0.1.0 across all repos
10. ⏳ Push to GitHub

### Future (Post v0.1.0)
- Implement fee tracking during replay (1% per validator)
- P/C/Q chain lock-step synchronization
- 100-year vesting implementation
- Runtime replay from subnet 96369 (~1M blocks)

## Important Commands

```bash
# Regenesis directory
cd /Users/z/work/lux/regenesis

# Generate validators
make validators

# Build node
cd /Users/z/work/lux/node && go build -o build/luxd ./main

# Launch network
make network

# Check status
make status

# Stop network
make stop

# View logs
tail -f output/logs/node1.log
```

## Test Mnemonic
**FOR TESTING ONLY - NOT FOR PRODUCTION**
```
copper verify boss hurt cargo mesh shine bunker museum glimpse sausage notable
```

## Critical User Requirements
- Port 9630 (NOT 9650)
- Keys in ~/.lux/keys with address prefixes
- 100 validators, 5 bootstrappers
- All components must compile and pass tests
- Fee tracking: 1% to each of 100 validators from replay
- 100-year vesting schedule
- Public verification via GitHub tags

## Regenesis Process - C-Chain Block Import (2025-12-11)

### Summary

Successfully imported 1,082,781 C-Chain blocks to a 5-node LUX Mainnet (network ID 96369) in 291 seconds at ~3,719 blocks/sec.

### Key Fixes Applied

#### 1. Field Name Mapping in Import Tool

The JSONL export uses snake_case, but the `migrate_importBlocks` API expects PascalCase:

```go
// WRONG (import fails silently):
type ImportBlock struct {
    HeaderRLP   string `json:"headerRLP"`    // ❌ Wrong field name
    BodyRLP     string `json:"bodyRLP"`
    ReceiptsRLP string `json:"receiptsRLP"`
}

// CORRECT (matches cchainvm/api.go ImportBlockEntry):
type ImportBlockEntry struct {
    Height   uint64 `json:"height"`      // ✅ from "number"
    Hash     string `json:"hash"`
    Header   string `json:"header"`      // ✅ from "header_rlp"
    Body     string `json:"body"`        // ✅ from "body_rlp"
    Receipts string `json:"receipts"`    // ✅ from "receipts_rlp"
}
```

#### 2. InitialStakedFunds Must Match Allocations

In `netrunner/local/genesis_config.go`:

```go
// The address MUST exist in allocations
firstValidatorAddr, err := FormatAddress("X", hrp, validatorKeys[0].ShortID)
genesis["initialStakedFunds"] = []string{firstValidatorAddr}
```

#### 3. Use BadgerDB (Not PebbleDB)

In `cli/cmd/networkcmd/start.go`:
```go
"db-type": "badgerdb"  // Required for reliable import
```

### Repositories and Commits

| Repository | Commit | Change |
|------------|--------|--------|
| migrate | d9e2c79 | Import tools with correct field mapping |
| netrunner | f6c835c | initialStakedFunds fix |
| cli | 4cc1e89e | BadgerDB as default |
| node | c171a0e75b | migrate_importBlocks API |

### Import Process

```bash
# 1. Start network
cd ~/work/lux/cli && ./bin/lux network start --mainnet --num-nodes=5

# 2. Import blocks (correct field names)
cd ~/work/lux/migrate
./bin/import-jsonl \
  -input=/tmp/lux-mainnet-blocks-sorted.jsonl \
  -nodes="http://127.0.0.1:9630/ext/bc/C/rpc,..."

# 3. Verify
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://127.0.0.1:9630/ext/bc/C/rpc
```

### Performance Metrics

- **Total blocks**: 1,082,781
- **Import time**: 291 seconds
- **Average rate**: 3,719 blocks/sec
- **Batch size**: 20 blocks
- **Nodes**: 5 (parallel import)

### Verification Results

All 5 nodes synchronized at block 1,082,780:
```
Node 9630: 0x10859c (1,082,780)
Node 9632: 0x10859c
Node 9634: 0x10859c
Node 9636: 0x10859c
Node 9638: 0x10859c
```

## Full Deployment and Import Process (2025-12-18)

### Overview

Complete process for deploying Lux Mainnet + Zoo EVM with full block import using RLP files. The process is idempotent and creates snapshots at each step for reproducibility.

### Prerequisites

1. **lux CLI** - Built and in PATH
2. **EVM Plugin** - Built at `~/.lux/plugins/srEXiWaHuhNyGwPUi444Tu47ZEDwxTWrbQiuD7FmgSAQ6X7Dy`
3. **RLP Files**:
   - C-Chain: `~/work/lux/state/rlp/lux-mainnet/lux-mainnet-96369.rlp`
   - Zoo: `~/work/lux/state/rlp/zoo-mainnet/zoo-mainnet-200200.rlp`
4. **Genesis Files**:
   - Zoo: `~/work/lux/genesis/chains/zoo/genesis.json`

### Deployment Script

Located at: `/Users/z/work/lux/regenesis/scripts/deploy-and-import.sh`

```bash
# Run full deployment (all steps)
./scripts/deploy-and-import.sh all

# Run individual steps
./scripts/deploy-and-import.sh mainnet      # Start fresh mainnet
./scripts/deploy-and-import.sh cchain       # Import C-Chain blocks
./scripts/deploy-and-import.sh zoo-deploy   # Deploy Zoo subnet
./scripts/deploy-and-import.sh zoo-import   # Import Zoo blocks
./scripts/deploy-and-import.sh test         # Test AMM on both chains
./scripts/deploy-and-import.sh final        # Save production snapshot
```

### Snapshots Created

| Snapshot | Description |
|----------|-------------|
| `mainnet-fresh` | Fresh mainnet with P/X/C chains |
| `cchain-imported` | 1.08M C-Chain blocks imported |
| `zoo-deployed` | Zoo subnet deployed |
| `zoo-imported` | 800 Zoo blocks imported |
| `production-ready` | Final tested state |

### Zoo Genesis Configuration

**Chain ID**: 200200

**Genesis Hash**: `0x7c548af47de27560779ccc67dda32a540944accc71dac3343da3b9cd18f14933`

**State Root**: `0x2d1cedac263020c5c56ef962f6abe0da1f5217bdc6468f8c9258a0ea23699e80`

**Accounts (Only 2!)**:
1. Treasury: `0x9011E888251AB053B7bD1cdB598Db4f9DEd94714` - 2T LUX
2. Warp Precompile: `0x0200000000000000000000000000000000000005` - activation marker

### Import Process

The import uses the `admin.importChain` RPC method which:
1. Parses blocks from RLP file
2. Re-executes all transactions
3. Verifies all state roots match
4. Builds full state trie from scratch
5. Accepts blocks into consensus

**NO bypass of state verification** - all hashes must match exactly.

### Testing

```bash
# Test C-Chain AMM
lux amm balance --network lux

# Test Zoo AMM
lux amm balance --network zoo

# Get swap quote
lux amm quote --network zoo --from 0x... --to 0x... --amount 100
```

### RPC Endpoints

| Chain | RPC URL |
|-------|---------|
| C-Chain | `http://127.0.0.1:9630/ext/bc/C/rpc` |
| C-Chain Admin | `http://127.0.0.1:9630/ext/bc/C/admin` |
| Zoo | `http://127.0.0.1:9630/ext/bc/zoo/rpc` |
| Zoo Admin | `http://127.0.0.1:9630/ext/bc/zoo/admin` |

### Troubleshooting

#### Zoo RPC 404
- Check if subnet is properly deployed with `lux network status`
- Verify blockchain ID in endpoint
- Wait 30-60s after network start for subnet to initialize

#### Import Fails with ErrPrunedAncestor
- Genesis state must be properly committed
- Check genesis hash matches RLP file
- Do NOT bypass state check - fix root cause

#### State Root Mismatch
- Re-execute ALL transactions from genesis
- Ensure feeConfig matches original chain
- Check SubnetEVM gas accounting (coinbase receives full gas)

### Files

```
~/work/lux/regenesis/
├── scripts/
│   └── deploy-and-import.sh    # Main deployment script
├── docs/
│   └── DEPLOYMENT.md           # Detailed deployment docs
├── output/
│   └── validators/             # Validator keys
└── LLM.md                      # This documentation

~/work/lux/state/
├── rlp/
│   ├── lux-mainnet/
│   │   └── lux-mainnet-96369.rlp
│   └── zoo-mainnet/
│       └── zoo-mainnet-200200.rlp
└── pebbledb/                   # Original chain databases
```

## All Chains Configuration (2025-12-18)

### Chain Overview

| Chain | Chain ID | Type | Treasury | Status |
|-------|----------|------|----------|--------|
| C-Chain | 96369 | Mainnet | ~1.9T LUX | Import from RLP |
| Zoo | 200200 | Mainnet L2 | 2T LUX | Import from RLP |
| SPC | 36911 | Mainnet L2 | Various | Import from RLP |
| Hanzo AI | 36963 | Mainnet L2 | 1B AI | Fresh deploy |

### Hanzo AI Chain (NEW)

**Purpose**: AI-focused EVM chain for Hanzo AI ecosystem

**Configuration**:
- **Chain ID**: 36963
- **Token**: AI (1 billion initial supply)
- **Treasury**: `0x9011E888251AB053B7bD1cdB598Db4f9DEd94714` (1B AI)
- **Gas Limit**: 15,000,000
- **Base Fee**: 25 gwei
- **Block Time**: 2 seconds

**Genesis File**: `/Users/z/work/lux/genesis/chains/ai/genesis.json`

```json
{
  "alloc": {
    "9011E888251AB053B7bD1cdB598Db4f9DEd94714": {
      "balance": "0x33b2e3c9fd0803ce8000000"
    }
  },
  "config": {
    "chainId": 36963,
    "subnetEVMTimestamp": 0,
    "durangoTimestamp": 0
  }
}
```

### SPC Chain

**Chain ID**: 36911

**Genesis File**: `/Users/z/work/lux/genesis/chains/spc/genesis.json`

**RLP File**: `/Users/z/work/lux/state/rlp/spc-mainnet/spc-mainnet-36911.rlp`

### Testnet Chains

| Chain | Chain ID | RLP File |
|-------|----------|----------|
| C-Chain Testnet | 96368 | `lux-testnet-96368.rlp` |
| Zoo Testnet | 200201 | `zoo-testnet-200201.rlp` |

## Deployment Scripts

### All-Chains Deployment (Mainnet)

**Script**: `/Users/z/work/lux/regenesis/scripts/deploy-all-chains.sh`

```bash
# Full deployment of all chains
./scripts/deploy-all-chains.sh all

# Individual steps
./scripts/deploy-all-chains.sh mainnet      # Fresh mainnet
./scripts/deploy-all-chains.sh cchain       # Import C-Chain (1.08M blocks)
./scripts/deploy-all-chains.sh zoo          # Deploy + import Zoo (800 blocks)
./scripts/deploy-all-chains.sh spc          # Deploy + import SPC
./scripts/deploy-all-chains.sh ai           # Deploy Hanzo AI (fresh, 1B AI)
./scripts/deploy-all-chains.sh test         # Test AMM
./scripts/deploy-all-chains.sh final        # Save production snapshot
```

### Testnet Deployment

**Script**: `/Users/z/work/lux/regenesis/scripts/deploy-and-import-testnet.sh`

```bash
# Full testnet deployment
./scripts/deploy-and-import-testnet.sh all

# Individual steps (same as mainnet but testnet config)
./scripts/deploy-and-import-testnet.sh testnet
./scripts/deploy-and-import-testnet.sh cchain
./scripts/deploy-and-import-testnet.sh zoo-deploy
./scripts/deploy-and-import-testnet.sh zoo-import
```

### Snapshots Created

| Snapshot Name | Contents |
|---------------|----------|
| `mainnet-fresh` | Fresh P/X/C chains |
| `cchain-imported` | + 1.08M C-Chain blocks |
| `zoo-imported` | + Zoo with 800 blocks |
| `spc-imported` | + SPC chain |
| `ai-deployed` | + Hanzo AI (fresh) |
| `all-chains-ready` | Final production state |

### RPC Endpoints

| Chain | RPC URL |
|-------|---------|
| C-Chain | `http://127.0.0.1:9630/ext/bc/C/rpc` |
| Zoo | `http://127.0.0.1:9630/ext/bc/<zoo-id>/rpc` |
| SPC | `http://127.0.0.1:9630/ext/bc/<spc-id>/rpc` |
| Hanzo AI | `http://127.0.0.1:9630/ext/bc/<ai-id>/rpc` |

## Files Structure

```
~/work/lux/
├── genesis/
│   └── chains/
│       ├── ai/
│       │   └── genesis.json      # Hanzo AI (1B AI)
│       ├── spc/
│       │   └── genesis.json      # SPC chain
│       └── zoo/
│           └── genesis.json      # Zoo (2T LUX)
├── state/
│   ├── rlp/
│   │   ├── lux-mainnet/          # C-Chain mainnet blocks
│   │   ├── lux-testnet/          # C-Chain testnet blocks
│   │   ├── zoo-mainnet/          # Zoo mainnet blocks
│   │   ├── zoo-testnet/          # Zoo testnet blocks
│   │   └── spc-mainnet/          # SPC blocks
│   └── scripts/
│       ├── deploy-all-chains.sh  # All chains deployment
│       ├── deploy-and-import.sh  # Mainnet only
│       └── deploy-and-import-testnet.sh
└── regenesis/
    ├── scripts/                   # Copied deployment scripts
    └── LLM.md                     # This documentation
```

### Version History

- **v0.3.0** (2025-12-18): Added SPC, Hanzo AI, testnet scripts
- **v0.2.0** (2025-12-18): Added Zoo deployment and import
- **v0.1.0** (2025-12-11): Initial C-Chain import (1.08M blocks)
