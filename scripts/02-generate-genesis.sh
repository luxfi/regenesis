#!/usr/bin/env bash
# Generate genesis files for mainnet and testnet

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGENESIS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GENESIS_ROOT="$(cd "$REGENESIS_ROOT/../genesis" && pwd)"

# Load mnemonic
if [ ! -f "$GENESIS_ROOT/.env" ]; then
    echo "Error: $GENESIS_ROOT/.env not found"
    exit 1
fi

source "$GENESIS_ROOT/.env"

if [ -z "$MNEMONIC" ]; then
    echo "Error: MNEMONIC not set in .env"
    exit 1
fi

echo "Generating genesis configurations..."
echo ""

# Generate mainnet genesis
echo "==> Generating mainnet genesis..."
"$GENESIS_ROOT/bin/genesis" generate mainnet \
    --mnemonic "$MNEMONIC" \
    --output "$REGENESIS_ROOT/config/mainnet"

echo ""

# Generate testnet genesis  
echo "==> Generating testnet genesis..."
"$GENESIS_ROOT/bin/genesis" generate testnet \
    --mnemonic "$MNEMONIC" \
    --output "$REGENESIS_ROOT/config/testnet"

echo ""
echo "✓ Genesis configurations generated successfully"
echo "  Mainnet: $REGENESIS_ROOT/config/mainnet"
echo "  Testnet: $REGENESIS_ROOT/config/testnet"
