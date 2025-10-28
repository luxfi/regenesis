#!/usr/bin/env bash
# Generate validator keys for regenesis
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENESIS_ROOT="$ROOT_DIR/../genesis"
OUT_DIR="$ROOT_DIR/output/validators"

source "$ROOT_DIR/.env"

# Use VALIDATORS from .env, fallback to 100
VALIDATOR_COUNT=${VALIDATORS:-100}
BOOTSTRAP_COUNT=${BOOTSTRAP_VALIDATORS:-5}

echo "Generating $VALIDATOR_COUNT validators ($BOOTSTRAP_COUNT bootstrappers)..."

# Mainnet validators (accounts 0-99)
echo "[1/2] Mainnet validators (accounts 0-$((VALIDATOR_COUNT-1)))..."
"$GENESIS_ROOT/bin/derive-validators" \
    --mnemonic "$MAINNET_MNEMONIC" \
    --start 0 \
    --count $VALIDATOR_COUNT \
    --output "$OUT_DIR/mainnet" \
    --network mainnet

# Testnet validators (accounts 100-199)
echo "[2/2] Testnet validators (accounts $VALIDATOR_COUNT-$((VALIDATOR_COUNT*2-1)))..."
"$GENESIS_ROOT/bin/derive-validators" \
    --mnemonic "$MAINNET_MNEMONIC" \
    --start $VALIDATOR_COUNT \
    --count $VALIDATOR_COUNT \
    --output "$OUT_DIR/testnet" \
    --network testnet

echo ""
echo "✓ Validators generated"
echo ""
echo "Bootstrap Validators (first $BOOTSTRAP_COUNT):"
for i in $(seq 1 $BOOTSTRAP_COUNT); do
    if [ -f "$OUT_DIR/mainnet/node$i/staking/staker.crt" ]; then
        echo "  Validator $i: ✓ Keys generated"
    fi
done

echo ""
echo "Total Validators: $VALIDATOR_COUNT"
echo "  - Bootstrap: $BOOTSTRAP_COUNT (will run as nodes)"
echo "  - Genesis: $((VALIDATOR_COUNT - BOOTSTRAP_COUNT)) (staked but not running initially)"
echo ""
echo "All $VALIDATOR_COUNT validators will have:"
echo "  - 1B LUX allocation"
echo "  - 100-year vesting schedule"  
echo "  - 1% of historical fees from replay"
echo "  - P-Chain staking returns"
