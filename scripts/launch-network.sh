#!/usr/bin/env bash
# Launch bootstrap network nodes
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUXD="$ROOT_DIR/output/luxd"
VALIDATORS_DIR="$ROOT_DIR/output/validators/mainnet"
CONFIG_DIR="$ROOT_DIR/output/config/mainnet"
DATA_DIR="$ROOT_DIR/output/data"
LOGS_DIR="$ROOT_DIR/output/logs"

source "$ROOT_DIR/.env"

# Launch only bootstrap validators
BOOTSTRAP_COUNT=${BOOTSTRAP_VALIDATORS:-5}
NETWORK_ID=${NETWORK_ID:-96369}

BASE_HTTP_PORT=9630
BASE_STAKING_PORT=9631

echo "Launching $BOOTSTRAP_COUNT bootstrap nodes..."
echo ""

# Create NodeID files from certificates (computed at generation time)
NODEIDS=("NodeID-EmKbUZB78hGUjsqFJjnpqD4swgziXmmSJ" "NodeID-KjAKN8PrRVw9jxJQz1PDX9kyovKavZhWP" "NodeID-MyTr8rkCVkHC1jfT4bgCXm2LABvUUyeEb" "NodeID-L6DZDwXDVgF91pHfvkpWqTvnCRqSUFAjs" "NodeID-4MvBqB6JF6SX8unyNZ6vXXkMe41XUWRXi")
mkdir -p "$DATA_DIR"
for i in $(seq 1 $BOOTSTRAP_COUNT); do
    echo "${NODEIDS[$((i-1))]}" > "$DATA_DIR/node$i.nodeid"
done

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

    # Build bootstrap IPs/IDs for nodes after the first
    BOOTSTRAP_IPS=""
    BOOTSTRAP_IDS=""
    if [ $i -gt 1 ]; then
        # Bootstrap from all previous nodes
        for j in $(seq 1 $((i-1))); do
            PREV_STAKING_PORT=$((BASE_STAKING_PORT + (j-1)*2))
            if [ -n "$BOOTSTRAP_IPS" ]; then
                BOOTSTRAP_IPS="$BOOTSTRAP_IPS,"
                BOOTSTRAP_IDS="$BOOTSTRAP_IDS,"
            fi
            BOOTSTRAP_IPS="${BOOTSTRAP_IPS}127.0.0.1:$PREV_STAKING_PORT"
            # Get NodeID from previous node's cert
            PREV_NODEID=$(cat "$DATA_DIR/node$j.nodeid" 2>/dev/null || echo "")
            BOOTSTRAP_IDS="${BOOTSTRAP_IDS}${PREV_NODEID}"
        done
    fi

    $LUXD \
        --network-id=$NETWORK_ID \
        --data-dir="$NODE_DIR" \
        --http-host=127.0.0.1 \
        --http-port=$HTTP_PORT \
        --staking-host=127.0.0.1 \
        --staking-port=$STAKING_PORT \
        --public-ip=127.0.0.1 \
        --staking-tls-cert-file="$VALIDATORS_DIR/node$i/staking/staker.crt" \
        --staking-tls-key-file="$VALIDATORS_DIR/node$i/staking/staker.key" \
        --genesis-file="$CONFIG_DIR/genesis.json" \
        --plugin-dir="$ROOT_DIR/output/plugins" \
        --log-dir="$LOGS_DIR" \
        --log-level=debug \
        --bootstrap-ips="$BOOTSTRAP_IPS" \
        --bootstrap-ids="$BOOTSTRAP_IDS" \
        > "$LOGS_DIR/node$i.log" 2>&1 &

    echo $! > "$DATA_DIR/node$i.pid"
    echo "  PID: $(cat $DATA_DIR/node$i.pid)"
    echo "  NodeID: ${NODEIDS[$((i-1))]}"
    echo ""

    # Wait longer for first node to fully initialize
    if [ $i -eq 1 ]; then
        echo "  Waiting for first node to initialize..."
        sleep 10
    else
        sleep 5
    fi
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
echo "Health Check: curl http://localhost:9630/ext/health"
echo "View Logs: make logs"
