#!/usr/bin/env bash
# Check all prerequisites for regenesis
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENESIS_ROOT="$ROOT_DIR/../genesis"
NODE_ROOT="$ROOT_DIR/../node"

echo "Checking prerequisites..."

# Check .env
if [ ! -f "$ROOT_DIR/.env" ]; then
    echo "ERROR: .env file not found at $ROOT_DIR/.env"
    echo "Create it with: MAINNET_MNEMONIC=\"your mnemonic here\""
    exit 1
fi

source "$ROOT_DIR/.env"
if [ -z "$MAINNET_MNEMONIC" ]; then
    echo "ERROR: MAINNET_MNEMONIC not set in .env"
    exit 1
fi

# Check binaries
BINS=(
    "$GENESIS_ROOT/bin/derive-validators:derive-validators (run: cd $GENESIS_ROOT && go build -o bin/derive-validators ./cmd/derive-validators)"
    "$GENESIS_ROOT/bin/genesis:genesis (run: cd $GENESIS_ROOT && go build -o bin/genesis)"
    "$NODE_ROOT/build/luxd:luxd (run: cd $NODE_ROOT && go build -o build/luxd ./main)"
)

for bin_info in "${BINS[@]}"; do
    IFS=: read -r bin_path error_msg <<< "$bin_info"
    if [ ! -x "$bin_path" ]; then
        echo "ERROR: $error_msg"
        exit 1
    fi
done

echo "✓ Prerequisites OK"
echo "  Mnemonic: $(echo $MAINNET_MNEMONIC | cut -d' ' -f1-3)..."
echo "  Binaries: all found"
