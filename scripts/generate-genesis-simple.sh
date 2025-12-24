#!/usr/bin/env bash
# Simple genesis generator with 100B LUX total (100 validators x 1B each)
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/output/config/mainnet"
source "$ROOT_DIR/.env"

NETWORK_ID=${NETWORK_ID:-96369}
VALIDATORS=${VALIDATORS:-100}
PER_VALIDATOR_LUX=${VALIDATOR_STAKE:-1000000000}  # 1B LUX

echo "Generating simple genesis for testing..."
echo "  Network ID: $NETWORK_ID"
echo "  Validators: $VALIDATORS"
echo "  Per validator: $PER_VALIDATOR_LUX LUX"
echo ""

# Calculate total in nLUX (for JSON)
TOTAL_SUPPLY=$((VALIDATORS * PER_VALIDATOR_LUX))

mkdir -p "$CONFIG_DIR"

# For testing, create a minimal genesis that satisfies the validator
# Real addresses will be added later when deploying with real keys
cat > "$CONFIG_DIR/genesis.json" << EOF
{
  "networkID": $NETWORK_ID,
  "allocations": [
    {
      "ethAddr": "0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC",
      "luxAddr": "X-lux18jma8ppw3nhx5r4ap8clazz0dps7rv5u00z96u",
      "initialAmount": $((TOTAL_SUPPLY * 1000000000))
    }
  ],
  "startTime": $(date +%s),
  "initialStakeDuration": 31536000,
  "initialStakeDurationOffset": 5400,
  "message": "Lux Regenesis v0.1.0-test - ${VALIDATORS} validators with ${PER_VALIDATOR_LUX}B LUX each",
  "cChainGenesis": "{\"config\":{\"chainId\":$NETWORK_ID,\"homesteadBlock\":0,\"eip150Block\":0,\"eip155Block\":0,\"eip158Block\":0,\"byzantiumBlock\":0,\"constantinopleBlock\":0,\"petersburgBlock\":0,\"istanbulBlock\":0,\"muirGlacierBlock\":0,\"subnetEVMTimestamp\":0},\"alloc\":{\"8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC\":{\"balance\":\"0x$$(printf '%x' $((TOTAL_SUPPLY * 1000000000)))\"}}}"
}
EOF

echo "✓ Genesis generated"
echo "  File: $CONFIG_DIR/genesis.json"
echo "  Total Supply: ${TOTAL_SUPPLY}B LUX"
echo ""
echo "NOTE: This is a test genesis for CI/local testing."
echo "Real mainnet genesis will have proper addresses for all 100 validators."
