#!/usr/bin/env bash
# Launch network nodes
set -e

VALIDATOR_COUNT=${1:-5}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_ROOT="$ROOT_DIR/../node"
LUXD="$NODE_ROOT/build/luxd"
VALIDATORS_DIR="$ROOT_DIR/output/validators/mainnet"
CONFIG_DIR="$ROOT_DIR/output/config/mainnet"
DATA_DIR="$ROOT_DIR/output/data"
LOGS_DIR="$ROOT_DIR/output/logs"

NETWORK_ID=96369
BASE_HTTP_PORT=9650
BASE_STAKING_PORT=9651

echo "Launching $VALIDATOR_COUNT nodes..."

for i in $(seq 1 $VALIDATOR_COUNT); do
    NODE_NUM=$i
    HTTP_PORT=$((BASE_HTTP_PORT + (i-1)*2))
    STAKING_PORT=$((BASE_STAKING_PORT + (i-1)*2))
    NODE_DIR="$DATA_DIR/node$i"
    NODE_ID=$(cat "$VALIDATORS_DIR/node$i/NodeID")

    echo "[$i/$VALIDATOR_COUNT] Starting node$i (HTTP:$HTTP_PORT, Staking:$STAKING_PORT)"
    echo "  NodeID: $NODE_ID"

    mkdir -p "$NODE_DIR" "$LOGS_DIR"

    $LUXD \
        --network-id=$NETWORK_ID \
        --data-dir="$NODE_DIR" \
        --http-port=$HTTP_PORT \
        --staking-port=$STAKING_PORT \
        --staking-tls-cert-file="$VALIDATORS_DIR/node$i/staking/staker.crt" \
        --staking-tls-key-file="$VALIDATORS_DIR/node$i/staking/staker.key" \
        --genesis-file="$CONFIG_DIR/genesis.json" \
        --bootstrap-ips="" \
        --log-dir="$LOGS_DIR" \
        --log-level=info \
        > "$LOGS_DIR/node$i.log" 2>&1 &

    echo $! > "$DATA_DIR/node$i.pid"
    sleep 2
done

echo ""
echo "✓ Network launched"
echo "  Nodes: $VALIDATOR_COUNT"
echo "  HTTP ports: 9650, 9652, 9654, 9656, 9658"
echo "  Health: http://localhost:9650/ext/health"
