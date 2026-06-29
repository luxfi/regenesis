<p align="center"><img src=".github/hero.svg" alt="regenesis" width="880"></p>

# Lux Mainnet Regenesis

Complete workflow for launching a 5-node Lux mainnet with C-chain history replay from subnet 96369.

## Overview

This regenesis process:
1. **Generates** deterministic validator keys from BIP39 mnemonic
2. **Creates** genesis configurations for mainnet and testnet
3. **Launches** 5 bootstrap nodes forming the initial network
4. **Deploys** subnet 96369 as the C-chain replay source
5. **Replays** ~1M blocks from subnet to new C-chain via native RPC

## Prerequisites

```bash
# 1. Build required binaries
cd ~/work/lux/genesis && go build -o bin/derive-validators ./cmd/derive-validators
cd ~/work/lux/genesis && go build -o bin/genesis
cd ~/work/lux/node && go build -o build/luxd ./main

# 2. Configure environment
cp .env.example .env
# Edit .env and set your MAINNET_MNEMONIC

# 3. Verify prerequisites
make check-bins
```

## Quick Start

```bash
# Complete workflow (all phases)
make all

# Or launch just mainnet (no subnet/replay)
make mainnet
```

## Step-by-Step

```bash
# Phase 1: Generate validator keys
make validators

# Phase 2: Generate genesis files
make genesis

# Phase 3: Launch 5-node network
make network

# Phase 4: Deploy subnet 96369
make subnet

# Phase 5: Replay C-chain history
make replay
```

## Management

```bash
# Check network status
make status

# View logs
make logs

# Stop all nodes
make stop

# Clean everything (WARNING: removes keys and data)
make clean
```

## Architecture

### Validator Key Derivation

Uses BIP44 path: `m/44'/9000'/0'/0/{index}`

- **Mainnet**: accounts 0-4 (5 validators)
- **Testnet**: accounts 5-9 (5 validators)

Each validator gets:
- `staker.key` - ECDSA P-256 private key
- `staker.crt` - X.509 certificate
- `NodeID` - Derived from certificate

### Network Configuration

- **Network ID**: 96369
- **Chain ID**: 96369
- **Bootstrap Nodes**: 5
- **HTTP Ports**: 9650, 9652, 9654, 9656, 9658
- **Staking Ports**: 9651, 9653, 9655, 9657, 9659

### C-Chain Replay Process

1. Subnet 96369 contains original C-chain data (~1M blocks)
2. New C-chain starts at genesis (block 0)
3. Replay tool:
   - Connects to subnet RPC
   - Reads blocks sequentially
   - Replays transactions on new C-chain
   - Verifies state roots at checkpoints
4. Result: New C-chain with complete history

## Directory Structure

```
~/work/lux/regenesis/
├── Makefile                  # Main orchestration
├── .env                      # Configuration (gitignored)
├── .env.example              # Template
├── README.md                 # This file
├── output/                   # Generated data (gitignored)
│   ├── validators/
│   │   ├── mainnet/         # Node keys
│   │   └── testnet/
│   ├── config/
│   │   └── mainnet/         # Genesis files
│   ├── data/                # Chain data
│   ├── logs/                # Node logs
│   └── replay/              # Replay state
└── scripts/                 # Helper scripts
    ├── check-prerequisites.sh
    ├── generate-validators.sh
    ├── generate-genesis.sh
    ├── launch-network.sh
    ├── deploy-subnet.sh
    ├── replay-cchain.sh
    ├── network-status.sh
    └── stop-network.sh
```

## Makefile Targets

- `all` - Complete workflow (validators → genesis → network → subnet → replay)
- `mainnet` - Quick mainnet (validators → genesis → network)
- `validators` - Generate validator keys
- `genesis` - Generate genesis files
- `network` - Launch network
- `subnet` - Deploy subnet
- `replay` - Replay C-chain
- `status` - Show network status
- `logs` - Tail logs
- `stop` - Stop network
- `clean` - Remove all output
- `help` - Show help

## Tools Used

- **derive-validators** (`~/work/lux/genesis/bin/derive-validators`)
  - Generates deterministic validator keys from mnemonic
  - BIP44 derivation

- **genesis** (`~/work/lux/genesis/bin/genesis`)
  - Generates network genesis configurations
  - Manages chain parameters, allocations, validators

- **luxd** (`~/work/lux/node/build/luxd`)
  - Lux node implementation
  - Runs validators and processes transactions

- **lux-cli** (`~/work/lux/cli/cli`)
  - Network management
  - Subnet operations
  - Key management

## Safety

- `.env` is gitignored (never commit mnemonics)
- Validator keys stored in `output/` (gitignored)
- `make clean` requires confirmation before deleting keys
- All operations are idempotent (can be re-run safely)

## Troubleshooting

### Network won't start
```bash
# Check prerequisites
make check-bins

# Check logs
make logs

# Restart network
make stop && make network
```

### Subnet deployment fails
```bash
# Verify network is running
make status

# Check node health
curl http://localhost:9650/ext/health
```

### Replay is slow
- C-chain replay of ~1M blocks takes several hours
- Progress is checkpointed every 10k blocks
- Resume with: `make replay` (automatically resumes from checkpoint)

## Next Steps

Once regenesis is complete:
1. Verify C-chain state matches expectations
2. Test RPC endpoints
3. Deploy additional nodes to join the network
4. Configure monitoring and alerting
5. Open network to external validators
