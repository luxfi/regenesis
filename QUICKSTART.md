# Lux Regenesis - Quick Start

## What This Does

Launches a complete Lux mainnet with:
- 5 deterministic bootstrap validators
- Full C-chain history replayed from subnet 96369
- ~1M blocks imported via native RPC

## Prerequisites (5 minutes)

```bash
# 1. Build binaries
cd ~/work/lux/genesis && go build -o bin/derive-validators ./cmd/derive-validators
cd ~/work/lux/genesis && go build -o bin/genesis
cd ~/work/lux/node && go build -o build/luxd ./main

# 2. Configure mnemonic
cd ~/work/lux/regenesis
cp .env.example .env
# Edit .env and set MAINNET_MNEMONIC="your 24 words here"

# 3. Verify setup
make check-bins
```

## Launch Mainnet (30 seconds)

```bash
cd ~/work/lux/regenesis

# Generate keys + genesis + launch network
make mainnet

# Check status
make status

# View logs
make logs
```

## Complete Workflow (several hours for replay)

```bash
# Phase 1-3: Mainnet (as above)
make mainnet

# Phase 4: Deploy subnet 96369 (replay source)
make subnet

# Phase 5: Replay C-chain (~1M blocks via RPC)
make replay
```

## Quick Commands

```bash
make help          # Show all commands
make status        # Network status
make logs          # Tail logs
make stop          # Stop nodes
make clean         # Remove all data
```

## What Gets Created

```
output/
├── validators/
│   ├── mainnet/        # 5 validator keys (accounts 0-4)
│   │   ├── node1/
│   │   │   ├── staking/
│   │   │   │   ├── staker.key
│   │   │   │   └── staker.crt
│   │   │   └── NodeID
│   │   ├── node2/ ... node5/
│   └── testnet/        # 5 validator keys (accounts 5-9)
├── config/
│   └── mainnet/
│       └── genesis.json
├── data/
│   ├── node1/          # Chain data
│   ├── node2/ ... node5/
├── logs/
│   ├── node1.log
│   ├── node2.log ... node5.log
└── replay/             # Replay checkpoints
```

## Access Nodes

- **Node 1**: http://localhost:9650
- **Node 2**: http://localhost:9652
- **Node 3**: http://localhost:9654
- **Node 4**: http://localhost:9656
- **Node 5**: http://localhost:9658

### Health Check

```bash
curl http://localhost:9650/ext/health
```

### P-Chain RPC

```bash
curl -X POST --data '{
  "jsonrpc":"2.0",
  "id":1,
  "method":"platform.getHeight",
  "params":{}
}' -H 'content-type:application/json' http://localhost:9650/ext/P
```

### C-Chain RPC

```bash
curl -X POST --data '{
  "jsonrpc":"2.0",
  "id":1,
  "method":"eth_blockNumber",
  "params":[]
}' -H 'content-type:application/json' http://localhost:9650/ext/bc/C/rpc
```

## Troubleshooting

### Prerequisites missing
```bash
make check-bins  # Shows what's missing
```

### Network won't start
```bash
make stop        # Clean stop
make network     # Restart
make status      # Verify
```

### Need to start fresh
```bash
make clean       # Removes EVERYTHING (asks for confirmation)
make mainnet     # Start over
```

## Architecture

### Deterministic Keys
- **BIP44 Path**: m/44'/9000'/0'/0/{index}
- **Mainnet**: accounts 0-4
- **Testnet**: accounts 5-9
- **Security**: Mnemonic in .env (gitignored)

### Network Layout
- **Network ID**: 96369
- **Chain ID**: 96369
- **Validators**: 5 bootstrap nodes
- **Consensus**: P-Chain proof-of-stake

### C-Chain Replay
1. Subnet 96369 = original C-chain data source
2. New C-chain starts at block 0
3. RPC calls to subnet to fetch blocks
4. Sequential replay with state verification
5. Checkpointing every 10k blocks

## Next Steps

After successful launch:

1. **Verify Health**
   ```bash
   make status
   curl http://localhost:9650/ext/health
   ```

2. **Check Block Height**
   ```bash
   # After replay completes, should show ~1M blocks
   curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' \
     -H 'content-type:application/json' http://localhost:9650/ext/bc/C/rpc
   ```

3. **Add More Validators**
   - Use lux-cli to add validators
   - Stake LUX tokens
   - Distribute to decentralize

4. **Configure Monitoring**
   - Prometheus metrics
   - Grafana dashboards
   - Alert rules

5. **Production Hardening**
   - Firewall rules
   - TLS for RPC
   - Key rotation strategy
   - Backup procedures

## Support

- **Issues**: GitHub issues in respective repos
- **Documentation**: ~/work/lux/regenesis/README.md
- **Logs**: ~/work/lux/regenesis/output/logs/
