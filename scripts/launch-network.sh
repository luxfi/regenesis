#!/usr/bin/env bash
# Launch bootstrap network nodes
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_ROOT="$ROOT_DIR/../node"
LUXD="$NODE_ROOT/build/luxd"
VALIDATORS_DIR="$ROOT_DIR/output/validators/mainnet"
CONFIG_DIR="$ROOT_DIR/output/config/mainnet"
DATA_DIR="$ROOT_DIR/output/data"
LOGS_DIR="$ROOT_DIR/output/logs"

source "$ROOT_DIR/.env"

# Launch only bootstrap validators
BOOTSTRAP_COUNT=${BOOTSTRAP_VALIDATORS:-5}
NETWORK_ID=${NETWORK_ID:-96369}

BASE_HTTP_PORT=9650
BASE_STAKING_PORT=9651

echo "Launching $BOOTSTRAP_COUNT bootstrap nodes..."
echo ""

for i in $(seq 1 $BOOTSTRAP_COUNT); do
    HTTP_PORT=$((BASE_HTTP_PORT + (i-1)*2))
    STAKING_PORT=$((BASE_STAKING_PORT + (i-1)*2))
    NODE_DIR="$DATA_DIR/node$i"

    echo "[$i/$BOOTSTRAP_COUNT] Starting bootstrap node $i"
    echo "  HTTP Port: $HTTP_PORT"
    echo "  Staking Port: $STAKING_PORT"

    mkdir -p "$NODE_DIR" "$LOGS_DIR"

    # Check if staking files exist
    if [ ! -f "$VALIDATORS_DIR/node$i/staking/staker.crt" ]; then
        echo "  ERROR: Validator keys not found for node$i"
        echo "  Run 'make validators' first"
        exit 1
    fi

    $LUXD \
        --network-id=$NETWORK_ID \
        --data-dir="$NODE_DIR" \
        --http-host=127.0.0.1 \
        --http-port=$HTTP_PORT \
        --staking-host=127.0.0.1 \
        --staking-port=$STAKING_PORT \
        --staking-tls-cert-file="$VALIDATORS_DIR/node$i/staking/staker.crt" \
        --staking-tls-key-file="$VALIDATORS_DIR/node$i/staking/staker.key" \
        --genesis-file="$CONFIG_DIR/genesis.json" \
        --bootstrap-ips="" \
        --log-dir="$LOGS_DIR" \
        --log-level=info \
        > "$LOGS_DIR/node$i.log" 2>&1 &

    echo $! > "$DATA_DIR/node$i.pid"
    echo "  PID: $(cat $DATA_DIR/node$i.pid)"
    echo ""
    sleep 3
done

echo "✓ Bootstrap network launched"
echo ""
echo "Active Nodes: $BOOTSTRAP_COUNT bootstrap validators"
echo "Genesis Validators: $((${VALIDATORS:-100} - BOOTSTRAP_COUNT)) (staked but not running)"
echo ""
echo "Node Ports:"
for i in $(seq 1 $BOOTSTRAP_COUNT); do
    HTTP_PORT=$((BASE_HTTP_PORT + (i-1)*2))
    echo "  Node $i: http://localhost:$HTTP_PORT"
done
echo ""
echo "Health Check: curl http://localhost:9650/ext/health"
echo "View Logs: make logs"
