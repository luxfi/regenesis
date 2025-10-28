#!/usr/bin/env bash
# Generate validator keys
set -e

VALIDATOR_COUNT=${1:-5}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENESIS_ROOT="$ROOT_DIR/../genesis"
OUT_DIR="$ROOT_DIR/output/validators"

source "$ROOT_DIR/.env"

echo "Generating $VALIDATOR_COUNT validators..."

# Mainnet validators (accounts 0-4)
echo "[1/2] Mainnet validators (accounts 0-$((VALIDATOR_COUNT-1)))..."
"$GENESIS_ROOT/bin/derive-validators" \
    --mnemonic "$MAINNET_MNEMONIC" \
    --start 0 \
    --count $VALIDATOR_COUNT \
    --output "$OUT_DIR/mainnet" \
    --network mainnet

# Testnet validators (accounts 5-9)
echo "[2/2] Testnet validators (accounts $VALIDATOR_COUNT-$((VALIDATOR_COUNT*2-1)))..."
"$GENESIS_ROOT/bin/derive-validators" \
    --mnemonic "$MAINNET_MNEMONIC" \
    --start $VALIDATOR_COUNT \
    --count $VALIDATOR_COUNT \
    --output "$OUT_DIR/testnet" \
    --network testnet

echo "✓ Validators generated"
for i in $(seq 1 $VALIDATOR_COUNT); do
    echo "  Node $i: $(cat "$OUT_DIR/mainnet/node$i/NodeID")"
done
