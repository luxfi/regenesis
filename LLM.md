# Lux Regenesis

## Overview

Regenesis is the process of relaunching mainnet/testnet networks with full historical block import. This uses the `lux` CLI with `admin_importChain` geth API - there is NO `migrate_*` API.

## Current Status (2025-12-23)

### ✅ Networks Running
- **Mainnet**: 5 validators on port 9630 (Network ID: 1, Chain ID: 96369)
- **Testnet**: 5 validators on port 9640 (Network ID: 2, Chain ID: 96368)

### Network Commands
```bash
# Start networks
lux network start --mainnet    # Port 9630, gRPC 8369
lux network start --testnet    # Port 9640, gRPC 8368

# Check status
lux network status --mainnet
lux network status --testnet

# Stop networks
lux network stop --mainnet
lux network stop --testnet
```

## Network Configuration

### Network IDs vs Chain IDs

| Network | Network ID (P-Chain) | Chain ID (C-Chain EVM) | Port Base |
|---------|---------------------|------------------------|-----------|
| Mainnet | 1 | 96369 | 9630 |
| Testnet | 2 | 96368 | 9640 |
| Custom/Local | 1337 | 1337 | 9650 |

### Genesis Configuration

Genesis is loaded from `luxfi/genesis` package:
- Embedded configs in `configs/{mainnet,testnet,custom}/`
- Each has: `network.json`, `pchain.json`, `cchain.json`

**Important**: Network ID comes from `network.json`, NOT from CLI flags overriding it.

### Validator Keys

Keys derived from `LUX_MNEMONIC` environment variable:
- P-Chain and X-Chain addresses use bech32 encoding
- C-Chain uses the treasury account `0x9011E888251AB053B7bD1cdB598Db4f9DEd94714`
- Keys stored in `~/.lux/keys/`

## Block Import

### RLP Data Files

Historical blocks stored at `~/work/lux/state/rlp/`:

| Chain | File | Chain ID |
|-------|------|----------|
| Lux Mainnet | `lux-mainnet/lux-mainnet-96369.rlp` | 96369 |
| Lux Testnet | `lux-testnet/lux-testnet-96368.rlp` | 96368 |
| Zoo Mainnet | `zoo-mainnet/zoo-mainnet-200200.rlp` | 200200 |
| Zoo Testnet | `zoo-testnet/zoo-testnet-200201.rlp` | 200201 |

### Genesis Hashes

| Network | Chain ID | Genesis Hash |
|---------|----------|--------------|
| Lux Mainnet | 96369 | `0x3f4fa2a0b0ce089f52bf0ae9199c75ffdd76ecafc987794050cb0d286f1ec61e` |
| Lux Testnet | 96368 | `0x1c5fe37764b8bc146dc88bc1c2e0259cd8369b07a06439bcfa1782b5d4fb0995` |
| Zoo Mainnet | 200200 | `0x7c548af47de27560779ccc67dda32a540944accc71dac3343da3b9cd18f14933` |
| Zoo Testnet | 200201 | `0x0652fb2fde1460544a5893e5eba5095ff566861cbc87fcb1c73be2b81d6d1979` |

### Import Method

**IMPORTANT**: Use `admin_importChain` geth API, NOT any `migrate_*` API (which doesn't exist).

```bash
# Import via CLI (uses admin_importChain internally)
lux chain import --rlp ~/work/lux/state/rlp/lux-mainnet/lux-mainnet-96369.rlp

# Or via direct RPC to running node
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"admin_importChain","params":["path/to/file.rlp"],"id":1}' \
  http://127.0.0.1:9630/ext/bc/C/admin
```

## RPC Endpoints

### Mainnet (port 9630)
| Endpoint | URL |
|----------|-----|
| Info | `http://127.0.0.1:9630/ext/info` |
| Health | `http://127.0.0.1:9630/ext/health` |
| P-Chain | `http://127.0.0.1:9630/ext/P` |
| X-Chain | `http://127.0.0.1:9630/ext/X` |
| C-Chain RPC | `http://127.0.0.1:9630/ext/bc/C/rpc` |
| C-Chain Admin | `http://127.0.0.1:9630/ext/bc/C/admin` |

### Testnet (port 9640)
| Endpoint | URL |
|----------|-----|
| Info | `http://127.0.0.1:9640/ext/info` |
| Health | `http://127.0.0.1:9640/ext/health` |
| P-Chain | `http://127.0.0.1:9640/ext/P` |
| C-Chain RPC | `http://127.0.0.1:9640/ext/bc/C/rpc` |

## Key Repositories

| Repository | Purpose |
|------------|---------|
| `luxfi/cli` | CLI tool (`lux` command) |
| `luxfi/genesis` | Genesis configurations |
| `luxfi/netrunner` | Local network orchestration |
| `luxfi/node` | Node implementation (`luxd`) |
| `luxfi/geth` | EVM implementation (C-Chain) |
| `luxfi/evm` | SubnetEVM for L2 chains |

## Files Structure

```
~/work/lux/
├── cli/                    # lux CLI tool
├── genesis/
│   └── configs/
│       ├── mainnet/        # Mainnet genesis (network.json, pchain.json, cchain.json)
│       ├── testnet/        # Testnet genesis
│       └── custom/         # Local dev genesis
├── netrunner/              # Network orchestration
├── state/
│   └── rlp/                # Historical block RLP files
│       ├── lux-mainnet/
│       ├── lux-testnet/
│       ├── zoo-mainnet/
│       └── zoo-testnet/
└── regenesis/
    ├── scripts/            # Deployment scripts
    └── LLM.md              # This documentation
```

## Common Issues

### "Network ID mismatch"
- Check that genesis `network.json` has correct `networkID`
- Don't confuse Network ID (1, 2) with Chain ID (96369, 96368)

### "Genesis hash mismatch"
- Genesis must match exactly for block import
- Check `cchain.json` has correct `alloc` and `timestamp`

### Port conflicts
- Mainnet uses 9630-9639
- Testnet uses 9640-9649
- gRPC servers: mainnet=8369, testnet=8368

## Version History

- **2025-12-23**: Multi-network support (mainnet + testnet parallel)
- **2025-12-18**: Added Zoo, SPC chain support
- **2025-12-11**: Initial C-Chain import (1.08M blocks)
