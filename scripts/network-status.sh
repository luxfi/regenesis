#!/usr/bin/env bash
# Show network status
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$ROOT_DIR/output/data"

echo "Network Status"
echo "=============="
echo ""

for i in 1 2 3 4 5; do
    if [ -f "$DATA_DIR/node$i.pid" ]; then
        PID=$(cat "$DATA_DIR/node$i.pid")
        if kill -0 $PID 2>/dev/null; then
            HTTP_PORT=$((9650 + (i-1)*2))
            echo "Node $i: RUNNING (PID $PID, HTTP :$HTTP_PORT)"
        else
            echo "Node $i: STOPPED (stale PID)"
        fi
    else
        echo "Node $i: NOT STARTED"
    fi
done

echo ""
echo "Health Check:"
if curl -s http://localhost:9650/ext/health | grep -q "healthy"; then
    echo "✓ Node 1 responding"
else
    echo "✗ Node 1 not responding"
fi
