#!/usr/bin/env bash
# Stop all network nodes
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$ROOT_DIR/output/data"

echo "Stopping network..."

for i in 1 2 3 4 5; do
    if [ -f "$DATA_DIR/node$i.pid" ]; then
        PID=$(cat "$DATA_DIR/node$i.pid")
        if kill -0 $PID 2>/dev/null; then
            echo "Stopping node $i (PID $PID)..."
            kill $PID
            sleep 1
        fi
        rm -f "$DATA_DIR/node$i.pid"
    fi
done

echo "✓ Network stopped"
