#!/usr/bin/env bash
# Generate genesis files
set -e

NETWORK_ID=${1:-96369}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENESIS_ROOT="$ROOT_DIR/../genesis"
VALIDATORS_DIR="$ROOT_DIR/output/validators"
CONFIG_DIR="$ROOT_DIR/output/config"

echo "Generating genesis for network $NETWORK_ID..."

# TODO: Call genesis tool to create genesis.json with:
# - Network ID
# - Validator set from $VALIDATORS_DIR/mainnet
# - Initial allocations
# - Subnet 96369 configuration
# For now, create placeholder
mkdir -p "$CONFIG_DIR/mainnet" "$CONFIG_DIR/testnet"

cat > "$CONFIG_DIR/mainnet/genesis.json" << EOF
{
  "networkID": $NETWORK_ID,
  "allocations": [],
  "startTime": $(date +%s),
  "message": "Lux Mainnet Genesis - Regenesis with C-chain replay"
}
EOF

echo "✓ Genesis generated at $CONFIG_DIR/mainnet/genesis.json"
