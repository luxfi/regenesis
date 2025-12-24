#!/usr/bin/env bash
# Generate proper genesis using default format
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/output/config/mainnet"
source "$ROOT_DIR/.env"

NETWORK_ID=${NETWORK_ID:-96369}
TOTAL_SUPPLY=100000000000000000000  # 100B LUX in nLUX

echo "Generating proper genesis for network $NETWORK_ID..."

mkdir -p "$CONFIG_DIR"

# Use valid test addresses from official genesis
cat > "$CONFIG_DIR/genesis.json" << 'EOF'
{
  "networkID": 96369,
  "allocations": [
    {
      "ethAddr": "0xb3d82b1367d362de99ab59a658165aff520cbd4d",
      "luxAddr": "X-local18jma8ppw3nhx5r4ap8clazz0dps7rv5u00z96u",
      "initialAmount": 100000000000000000000
    }
  ],
  "startTime": 1599696000,
  "initialStakeDuration": 31536000,
  "initialStakeDurationOffset": 5400,
  "initialStakedFunds": [
    "X-local18jma8ppw3nhx5r4ap8clazz0dps7rv5u00z96u"
  ],
  "initialStakers": [
    {
      "nodeID": "NodeID-7Xhw2mDxuDS44j42TCB6U5579esbSt3Lg",
      "rewardAddress": "X-local18jma8ppw3nhx5r4ap8clazz0dps7rv5u00z96u",
      "delegationFee": 1000000
    }
  ],
  "cChainGenesis": "{\"config\":{\"chainId\":96369,\"homesteadBlock\":0,\"eip150Block\":0,\"eip150Hash\":\"0x2086799aeebeae135c246c65021c82b4e15a2c451340993aacfd2751886514f0\",\"eip155Block\":0,\"eip158Block\":0,\"byzantiumBlock\":0,\"constantinopleBlock\":0,\"petersburgBlock\":0,\"istanbulBlock\":0,\"muirGlacierBlock\":0},\"nonce\":\"0x0\",\"timestamp\":\"0x0\",\"extraData\":\"0x00\",\"gasLimit\":\"0x5f5e100\",\"difficulty\":\"0x0\",\"mixHash\":\"0x0000000000000000000000000000000000000000000000000000000000000000\",\"coinbase\":\"0x0000000000000000000000000000000000000000\",\"alloc\":{\"b3d82b1367d362de99ab59a658165aff520cbd4d\":{\"balance\":\"0x56bc75e2d63100000\"}},\"number\":\"0x0\",\"gasUsed\":\"0x0\",\"parentHash\":\"0x0000000000000000000000000000000000000000000000000000000000000000\"}",
  "message": "Lux Regenesis v0.1.0-test"
}
EOF

echo "✓ Genesis generated at $CONFIG_DIR/genesis.json"
echo "  Network ID: $NETWORK_ID"
echo "  Using valid test addresses for bootstrap"
