#!/usr/bin/env bash
# Generate genesis with 100 validators
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATORS_DIR="$ROOT_DIR/output/validators/mainnet"
CONFIG_DIR="$ROOT_DIR/output/config/mainnet"
source "$ROOT_DIR/.env"

NETWORK_ID=${NETWORK_ID:-96369}
VALIDATORS=${VALIDATORS:-100}
VALIDATOR_STAKE=${VALIDATOR_STAKE:-1000000000000000000}  # 1B LUX in nLUX

echo "Generating genesis with $VALIDATORS validators..."
echo "Allocation per validator: $VALIDATOR_STAKE nLUX (1B LUX)"
echo ""

# Calculate validator addresses from mnemonic
# For now, we'll use placeholder addresses - in production this should derive from certificates
mkdir -p "$CONFIG_DIR"

# Generate allocations
ALLOCATIONS=""
for i in $(seq 1 $VALIDATORS); do
    # Derive address from account index (i-1)
    # For now using placeholder - should derive from actual keys
    ADDR="0x$(printf '%040d' $i | sha256sum | cut -c1-40)"
    if [ $i -eq 1 ]; then
        ALLOCATIONS="    {\"ethAddr\": \"$ADDR\", \"luxAddr\": \"X-lux1...\", \"initialAmount\": $VALIDATOR_STAKE}"
    else
        ALLOCATIONS="$ALLOCATIONS,\n    {\"ethAddr\": \"$ADDR\", \"luxAddr\": \"X-lux1...\", \"initialAmount\": $VALIDATOR_STAKE}"
    fi
done

# Create genesis
cat > "$CONFIG_DIR/genesis.json" << EOF
{
  "networkID": $NETWORK_ID,
  "allocations": [
$(echo -e "$ALLOCATIONS")
  ],
  "startTime": $(date +%s),
  "initialStakeDuration": 31536000,
  "initialStakeDurationOffset": 5400,
  "message": "Lux Mainnet Regenesis - 100 Validators with 1B LUX each",
  "initialStakedFunds": [

  ],
  "cChainGenesis": "{\"config\":{\"chainId\":96369,\"homesteadBlock\":0,\"eip150Block\":0,\"eip150Hash\":\"0x2086799aeebeae135c246c65021c82b4e15a2c451340993aacfd2751886514f0\",\"eip155Block\":0,\"eip158Block\":0,\"byzantiumBlock\":0,\"constantinopleBlock\":0,\"petersburgBlock\":0,\"istanbulBlock\":0,\"muirGlacierBlock\":0,\"subnetEVMTimestamp\":0},\"nonce\":\"0x0\",\"timestamp\":\"0x0\",\"extraData\":\"0x00\",\"gasLimit\":\"0x5f5e100\",\"difficulty\":\"0x0\",\"mixHash\":\"0x0000000000000000000000000000000000000000000000000000000000000000\",\"coinbase\":\"0x0000000000000000000000000000000000000000\",\"alloc\":{},\"airdropHash\":\"0x0000000000000000000000000000000000000000000000000000000000000000\",\"airdropAmount\":null,\"number\":\"0x0\",\"gasUsed\":\"0x0\",\"parentHash\":\"0x0000000000000000000000000000000000000000000000000000000000000000\",\"baseFeePerGas\":null}"
}
EOF

echo "✓ Genesis generated"
echo "  File: $CONFIG_DIR/genesis.json"
echo "  Network ID: $NETWORK_ID"
echo "  Total Supply: $((VALIDATORS * VALIDATOR_STAKE / 1000000000)) LUX"
echo "  Validators: $VALIDATORS"
