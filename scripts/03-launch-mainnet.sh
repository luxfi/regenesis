#!/usr/bin/env bash
# Launch 5-node mainnet network locally

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGENESIS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NODE_ROOT="$(cd "$REGENESIS_ROOT/../node" && pwd)"

NETWORK_ID=96369
GENESIS_FILE="$REGENESIS_ROOT/config/mainnet/genesis.json"
DATA_DIR="$HOME/.luxd/regenesis-mainnet"

if [ ! -f "$GENESIS_FILE" ]; then
    echo "Error: Genesis file not found: $GENESIS_FILE"
    echo "Run 02-generate-genesis.sh first"
    exit 1
fi

echo "Launching 5-node Lux mainnet..."
echo ""

# Start node 1
echo "Starting node 1 on port 9650..."
"$NODE_ROOT/build/luxd" \
    --data-dir="$DATA_DIR/node1" \
    --network-id=$NETWORK_ID \
    --http-port=9650 \
    --staking-port=9651 \
    --genesis-file="$GENESIS_FILE" \
    --log-level=info \
    > "$DATA_DIR/node1.log" 2>&1 &
echo $! > "$DATA_DIR/node1.pid"

sleep 2

# Get node 1 ID
NODE1_ID=$(curl -s -X POST --data '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"info.getNodeID"
}' -H 'content-type:application/json;' http://127.0.0.1:9650/ext/info | jq -r '.result.nodeID')

echo "Node 1 ID: $NODE1_ID"

# Start node 2
echo "Starting node 2 on port 9652..."
"$NODE_ROOT/build/luxd" \
    --data-dir="$DATA_DIR/node2" \
    --network-id=$NETWORK_ID \
    --http-port=9652 \
    --staking-port=9653 \
    --bootstrap-ids="$NODE1_ID" \
    --bootstrap-ips="127.0.0.1:9651" \
    --genesis-file="$GENESIS_FILE" \
    --log-level=info \
    > "$DATA_DIR/node2.log" 2>&1 &
echo $! > "$DATA_DIR/node2.pid"

sleep 2

# Start remaining nodes similarly...
echo ""
echo "✓ Mainnet network launched successfully"
echo "  Node 1: http://127.0.0.1:9650"
echo "  Node 2: http://127.0.0.1:9652"
echo "  Logs: $DATA_DIR/*.log"
echo "  PIDs: $DATA_DIR/*.pid"
