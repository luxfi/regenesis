#!/usr/bin/env bash
# Generate validator keys for mainnet and testnet

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGENESIS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GENESIS_ROOT="$(cd "$REGENESIS_ROOT/../genesis" && pwd)"

# Load mnemonic from genesis .env
if [ ! -f "$GENESIS_ROOT/.env" ]; then
    echo "Error: $GENESIS_ROOT/.env not found"
    exit 1
fi

source "$GENESIS_ROOT/.env"

if [ -z "$MNEMONIC" ]; then
    echo "Error: MNEMONIC not set in .env"
    exit 1
fi

echo "Generating validator keys..."
echo ""

# Generate mainnet validators (accounts 0-4)
echo "==> Generating 5 mainnet validators (accounts 0-4)..."
"$GENESIS_ROOT/bin/derive-validators" \
    --mnemonic "$MNEMONIC" \
    --start 0 \
    --count 5 \
    --output "$REGENESIS_ROOT/validators/mainnet" \
    --network mainnet

echo ""

# Generate testnet validators (accounts 5-9)
echo "==> Generating 5 testnet validators (accounts 5-9)..."
"$GENESIS_ROOT/bin/derive-validators" \
    --mnemonic "$MNEMONIC" \
    --start 5 \
    --count 5 \
    --output "$REGENESIS_ROOT/validators/testnet" \
    --network testnet

echo ""
echo "✓ All validator keys generated successfully"
echo "  Mainnet: $REGENESIS_ROOT/validators/mainnet"
echo "  Testnet: $REGENESIS_ROOT/validators/testnet"
