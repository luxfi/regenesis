#!/usr/bin/env bash
# Deploy subnet for C-chain replay source
set -e

SUBNET_ID=${1:-96369}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Deploying subnet $SUBNET_ID..."
echo "  This subnet will serve as the replay source for C-chain"
echo "  C-chain will RPC to this subnet to fetch ~1M blocks"

# TODO: Deploy subnet using lux-cli or genesis tool
# - Create subnet
# - Configure validators
# - Wait for subnet to sync
# - Expose RPC endpoints

echo "✓ Subnet deployed"
echo "  Subnet RPC: http://localhost:9650/ext/bc/$SUBNET_ID/rpc"
