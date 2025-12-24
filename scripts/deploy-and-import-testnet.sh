#!/bin/bash
# Deploy and Import Script for Lux TESTNET + Zoo EVM Testnet
# Handles full process: deploy, import blocks, snapshot, test
# Each step is idempotent and can be resumed

set -e

# Configuration
WORK_DIR="$HOME/work/lux"
STATE_DIR="$WORK_DIR/state"
CLI_DIR="$WORK_DIR/cli"
EVM_DIR="$WORK_DIR/evm"
GENESIS_DIR="$WORK_DIR/genesis"

# TESTNET RLP files for import
CCHAIN_RLP="$STATE_DIR/rlp/lux-testnet/lux-testnet-96368.rlp"
ZOO_RLP="$STATE_DIR/rlp/zoo-testnet/zoo-testnet-200201.rlp"

# Genesis files (use testnet variants if they exist)
ZOO_GENESIS="$GENESIS_DIR/chains/zoo/genesis-testnet.json"

# Fallback to mainnet genesis if testnet doesn't exist
if [ ! -f "$ZOO_GENESIS" ]; then
    ZOO_GENESIS="$GENESIS_DIR/chains/zoo/genesis.json"
fi

# TESTNET Snapshot names (prefixed with testnet-)
SNAPSHOT_TESTNET_FRESH="testnet-fresh"
SNAPSHOT_CCHAIN_IMPORTED="testnet-cchain-imported"
SNAPSHOT_ZOO_DEPLOYED="testnet-zoo-deployed"
SNAPSHOT_ZOO_IMPORTED="testnet-zoo-imported"
SNAPSHOT_FINAL="testnet-production-ready"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${CYAN}[TESTNET]${NC} ${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${CYAN}[TESTNET]${NC} ${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${CYAN}[TESTNET]${NC} ${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${CYAN}[TESTNET]${NC} ${RED}[ERROR]${NC} $1"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check lux CLI
    if ! command -v lux &> /dev/null; then
        error "lux CLI not found. Please install it first."
    fi

    # Check EVM plugin
    if [ ! -f "$HOME/.lux/plugins/srEXiWaHuhNyGwPUi444Tu47ZEDwxTWrbQiuD7FmgSAQ6X7Dy" ]; then
        warn "EVM plugin not found. Building..."
        build_evm_plugin
    fi

    # Check RLP files exist
    if [ ! -f "$CCHAIN_RLP" ]; then
        warn "C-Chain testnet RLP not found at $CCHAIN_RLP"
    fi

    if [ ! -f "$ZOO_RLP" ]; then
        warn "Zoo testnet RLP not found at $ZOO_RLP"
    fi

    success "Prerequisites check passed"
}

# Build EVM plugin
build_evm_plugin() {
    log "Building EVM plugin..."
    cd "$EVM_DIR"
    go build -o "$HOME/.lux/plugins/srEXiWaHuhNyGwPUi444Tu47ZEDwxTWrbQiuD7FmgSAQ6X7Dy" ./plugin
    success "EVM plugin built"
}

# Check if snapshot exists
snapshot_exists() {
    local name=$1
    if [ -d "$HOME/.lux/snapshots/anr-snapshot-$name" ]; then
        return 0
    fi
    return 1
}

# Start network from snapshot or fresh (TESTNET)
start_network() {
    local snapshot=$1

    log "Stopping any running network..."
    lux network stop 2>/dev/null || true
    sleep 2

    if [ -n "$snapshot" ] && snapshot_exists "$snapshot"; then
        log "Starting from snapshot: $snapshot"
        lux network start --snapshot-name "$snapshot"
    else
        log "Starting fresh TESTNET..."
        lux network start --testnet
    fi

    # Wait for network to be healthy
    log "Waiting for network to be healthy..."
    sleep 30

    # Verify network is up
    if ! lux network status | grep -q "Healthy: true"; then
        error "Network failed to start"
    fi

    success "Network started successfully"
}

# Save snapshot
save_snapshot() {
    local name=$1
    log "Saving snapshot: $name"

    # Stop network to create clean snapshot
    lux network stop
    sleep 2

    # Copy current network state to snapshot
    if [ -d "$HOME/.lux/runs/local_network" ]; then
        mkdir -p "$HOME/.lux/snapshots"
        cp -r "$HOME/.lux/runs/local_network" "$HOME/.lux/snapshots/anr-snapshot-$name"
        success "Snapshot saved: $name"
    else
        error "No network state to snapshot"
    fi
}

# Wait for RPC to be ready
wait_for_rpc() {
    local endpoint=$1
    local timeout=${2:-60}
    local elapsed=0

    log "Waiting for RPC at $endpoint..."

    while [ $elapsed -lt $timeout ]; do
        if curl -s -X POST "$endpoint" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' \
            | grep -q '"result"'; then
            success "RPC is ready at $endpoint"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    error "RPC not ready after ${timeout}s"
}

# Import C-Chain blocks (TESTNET)
import_cchain() {
    log "Importing C-Chain TESTNET blocks..."

    if [ ! -f "$CCHAIN_RLP" ]; then
        warn "C-Chain testnet RLP not found, skipping import"
        return 0
    fi

    # Wait for C-Chain RPC (testnet uses same ports)
    wait_for_rpc "http://127.0.0.1:9630/ext/bc/C/rpc"

    # Check current block
    local current=$(curl -s -X POST http://127.0.0.1:9630/ext/bc/C/rpc \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' \
        | jq -r '.result' | xargs printf "%d" 2>/dev/null || echo "0")

    if [ "$current" -gt 1000 ]; then
        success "C-Chain already has $current blocks, skipping import"
        return 0
    fi

    log "Current C-Chain height: $current, importing from RLP..."

    # Call admin.importChain
    local result=$(curl -s -X POST http://127.0.0.1:9630/ext/bc/C/admin \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"admin.importChain\",\"params\":{\"file\":\"$CCHAIN_RLP\"}}")

    if echo "$result" | grep -q '"success":true'; then
        local imported=$(echo "$result" | jq -r '.result.blocksImported')
        success "Imported $imported C-Chain testnet blocks"
    else
        error "C-Chain testnet import failed: $result"
    fi
}

# Deploy Zoo subnet (TESTNET)
deploy_zoo() {
    log "Deploying Zoo TESTNET subnet..."

    # Check if Zoo is already deployed
    if lux network status 2>&1 | grep -q "zoo"; then
        success "Zoo already deployed"
        return 0
    fi

    # Deploy Zoo
    log "Creating Zoo L2 for TESTNET..."

    # Create Zoo if it doesn't exist
    if ! lux l2 list 2>&1 | grep -q "zoo-testnet"; then
        lux l2 create zoo-testnet \
            --chain-id 200201 \
            --genesis-file "$ZOO_GENESIS" \
            --vm evm \
            --force
    fi

    # Deploy to local network
    LUX_PRIVATE_KEY=$(cat "$HOME/.lux/keys/local-key.pk" 2>/dev/null || echo "") \
        lux network deploy zoo-testnet --local --local-key

    # Wait for Zoo RPC
    sleep 20

    success "Zoo testnet deployed"
}

# Import Zoo blocks (TESTNET)
import_zoo() {
    log "Importing Zoo TESTNET blocks..."

    if [ ! -f "$ZOO_RLP" ]; then
        warn "Zoo testnet RLP not found, skipping import"
        return 0
    fi

    # Get Zoo blockchain ID
    local zoo_id=$(lux network status 2>&1 | grep -oP '2[A-Za-z0-9]{47}' | head -1)

    if [ -z "$zoo_id" ]; then
        error "Cannot find Zoo blockchain ID"
    fi

    log "Zoo blockchain ID: $zoo_id"

    # Wait for Zoo RPC
    wait_for_rpc "http://127.0.0.1:9630/ext/bc/$zoo_id/rpc" 120

    # Check current block
    local current=$(curl -s -X POST "http://127.0.0.1:9630/ext/bc/$zoo_id/rpc" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' \
        | jq -r '.result' | xargs printf "%d" 2>/dev/null || echo "0")

    if [ "$current" -gt 100 ]; then
        success "Zoo testnet already has $current blocks, skipping import"
        return 0
    fi

    log "Current Zoo height: $current, importing from RLP..."

    # Call admin.importChain
    local result=$(curl -s -X POST "http://127.0.0.1:9630/ext/bc/$zoo_id/admin" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"admin.importChain\",\"params\":{\"file\":\"$ZOO_RLP\"}}")

    if echo "$result" | grep -q '"success":true'; then
        local imported=$(echo "$result" | jq -r '.result.blocksImported')
        success "Imported $imported Zoo testnet blocks"
    else
        warn "Zoo testnet import result: $result"
    fi
}

# Test AMM on C-Chain
test_cchain_amm() {
    log "Testing C-Chain TESTNET AMM..."

    if lux amm balance --network lux-testnet 2>&1 | grep -q "Balance"; then
        success "C-Chain testnet AMM accessible"
    else
        warn "C-Chain testnet AMM test failed (may not be deployed)"
    fi
}

# Test AMM on Zoo
test_zoo_amm() {
    log "Testing Zoo TESTNET AMM..."

    if lux amm balance --network zoo-testnet 2>&1 | grep -q "Balance"; then
        success "Zoo testnet AMM accessible"
    else
        warn "Zoo testnet AMM test failed (may not be deployed)"
    fi
}

# Show testnet info
show_info() {
    echo ""
    echo "============================================="
    echo "         Lux TESTNET Information"
    echo "============================================="
    echo ""
    echo "Network: TESTNET"
    echo "C-Chain ID: 96368"
    echo "Zoo Chain ID: 200201"
    echo ""
    echo "RPC Endpoints:"
    echo "  C-Chain: http://127.0.0.1:9630/ext/bc/C/rpc"
    echo "  Zoo:     http://127.0.0.1:9630/ext/bc/<zoo-id>/rpc"
    echo ""
    echo "RLP Files:"
    echo "  C-Chain: $CCHAIN_RLP"
    echo "  Zoo:     $ZOO_RLP"
    echo ""
}

# Main workflow
main() {
    local step=${1:-all}

    echo "============================================="
    echo "Lux TESTNET + Zoo Deployment and Import"
    echo "============================================="

    check_prerequisites

    case $step in
        fresh)
            # Start fresh, no snapshots
            start_network ""
            ;;

        testnet)
            # Step 1: Start fresh testnet
            if snapshot_exists "$SNAPSHOT_TESTNET_FRESH"; then
                start_network "$SNAPSHOT_TESTNET_FRESH"
            else
                start_network ""
                save_snapshot "$SNAPSHOT_TESTNET_FRESH"
                start_network "$SNAPSHOT_TESTNET_FRESH"
            fi
            ;;

        cchain)
            # Step 2: Import C-Chain testnet blocks
            if snapshot_exists "$SNAPSHOT_CCHAIN_IMPORTED"; then
                start_network "$SNAPSHOT_CCHAIN_IMPORTED"
            else
                start_network "$SNAPSHOT_TESTNET_FRESH"
                import_cchain
                save_snapshot "$SNAPSHOT_CCHAIN_IMPORTED"
                start_network "$SNAPSHOT_CCHAIN_IMPORTED"
            fi
            ;;

        zoo-deploy)
            # Step 3: Deploy Zoo testnet
            if snapshot_exists "$SNAPSHOT_ZOO_DEPLOYED"; then
                start_network "$SNAPSHOT_ZOO_DEPLOYED"
            else
                start_network "$SNAPSHOT_CCHAIN_IMPORTED"
                deploy_zoo
                save_snapshot "$SNAPSHOT_ZOO_DEPLOYED"
                start_network "$SNAPSHOT_ZOO_DEPLOYED"
            fi
            ;;

        zoo-import)
            # Step 4: Import Zoo testnet blocks
            if snapshot_exists "$SNAPSHOT_ZOO_IMPORTED"; then
                start_network "$SNAPSHOT_ZOO_IMPORTED"
            else
                start_network "$SNAPSHOT_ZOO_DEPLOYED"
                import_zoo
                save_snapshot "$SNAPSHOT_ZOO_IMPORTED"
                start_network "$SNAPSHOT_ZOO_IMPORTED"
            fi
            ;;

        test)
            # Step 5: Test everything
            start_network "$SNAPSHOT_ZOO_IMPORTED"
            test_cchain_amm
            test_zoo_amm
            ;;

        final)
            # Step 6: Save final production snapshot
            start_network "$SNAPSHOT_ZOO_IMPORTED"
            test_cchain_amm
            test_zoo_amm
            save_snapshot "$SNAPSHOT_FINAL"
            success "Testnet production snapshot ready: $SNAPSHOT_FINAL"
            ;;

        all)
            # Full workflow
            log "Running full TESTNET deployment workflow..."

            # Fresh testnet
            start_network ""
            save_snapshot "$SNAPSHOT_TESTNET_FRESH"

            # Import C-Chain
            start_network "$SNAPSHOT_TESTNET_FRESH"
            import_cchain
            save_snapshot "$SNAPSHOT_CCHAIN_IMPORTED"

            # Deploy Zoo
            start_network "$SNAPSHOT_CCHAIN_IMPORTED"
            deploy_zoo
            save_snapshot "$SNAPSHOT_ZOO_DEPLOYED"

            # Import Zoo
            start_network "$SNAPSHOT_ZOO_DEPLOYED"
            import_zoo
            save_snapshot "$SNAPSHOT_ZOO_IMPORTED"

            # Test everything
            start_network "$SNAPSHOT_ZOO_IMPORTED"
            test_cchain_amm
            test_zoo_amm

            # Final snapshot
            save_snapshot "$SNAPSHOT_FINAL"

            success "Full TESTNET deployment complete!"
            ;;

        info)
            show_info
            ;;

        status)
            lux network status
            ;;

        stop)
            lux network stop
            ;;

        *)
            echo "Usage: $0 [fresh|testnet|cchain|zoo-deploy|zoo-import|test|final|all|info|status|stop]"
            echo ""
            echo "TESTNET Deployment Steps:"
            echo "  fresh       - Start fresh testnet"
            echo "  testnet     - Start/create testnet snapshot"
            echo "  cchain      - Import C-Chain testnet blocks"
            echo "  zoo-deploy  - Deploy Zoo testnet subnet"
            echo "  zoo-import  - Import Zoo testnet blocks"
            echo "  test        - Test AMM on both chains"
            echo "  final       - Create production snapshot"
            echo "  all         - Run full workflow"
            echo "  info        - Show testnet information"
            echo "  status      - Show network status"
            echo "  stop        - Stop network"
            exit 1
            ;;
    esac
}

# Run main
main "$@"
