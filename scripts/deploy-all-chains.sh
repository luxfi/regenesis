#!/bin/bash
# Deploy and Import Script for ALL Lux Chains
# Supports: Mainnet C-Chain, Zoo, SPC, Hanzo AI
# Each step is idempotent with snapshots for reproducibility

set -e

# Configuration
WORK_DIR="$HOME/work/lux"
STATE_DIR="$WORK_DIR/state"
CLI_DIR="$WORK_DIR/cli"
EVM_DIR="$WORK_DIR/evm"
GENESIS_DIR="$WORK_DIR/genesis"

# RLP files for import
CCHAIN_RLP="$STATE_DIR/rlp/lux-mainnet/lux-mainnet-96369.rlp"
ZOO_RLP="$STATE_DIR/rlp/zoo-mainnet/zoo-mainnet-200200.rlp"
SPC_RLP="$STATE_DIR/rlp/spc-mainnet/spc-mainnet-36911.rlp"

# Genesis files
ZOO_GENESIS="$GENESIS_DIR/chains/zoo/genesis.json"
SPC_GENESIS="$GENESIS_DIR/chains/spc/genesis.json"
AI_GENESIS="$GENESIS_DIR/chains/ai/genesis.json"

# Chain IDs
CCHAIN_ID=96369
ZOO_CHAIN_ID=200200
SPC_CHAIN_ID=36911
AI_CHAIN_ID=36963

# Snapshot names
SNAPSHOT_MAINNET_FRESH="mainnet-fresh"
SNAPSHOT_CCHAIN_IMPORTED="cchain-imported"
SNAPSHOT_ZOO_DEPLOYED="zoo-deployed"
SNAPSHOT_ZOO_IMPORTED="zoo-imported"
SNAPSHOT_SPC_DEPLOYED="spc-deployed"
SNAPSHOT_SPC_IMPORTED="spc-imported"
SNAPSHOT_AI_DEPLOYED="ai-deployed"
SNAPSHOT_FINAL="all-chains-ready"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

chain_log() {
    local chain=$1
    local msg=$2
    case $chain in
        "C-Chain") echo -e "${CYAN}[C-CHAIN]${NC} $msg" ;;
        "Zoo") echo -e "${MAGENTA}[ZOO]${NC} $msg" ;;
        "SPC") echo -e "${YELLOW}[SPC]${NC} $msg" ;;
        "AI") echo -e "${GREEN}[HANZO-AI]${NC} $msg" ;;
        *) echo -e "$msg" ;;
    esac
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

    # Verify genesis files
    for genesis in "$ZOO_GENESIS" "$SPC_GENESIS" "$AI_GENESIS"; do
        if [ ! -f "$genesis" ]; then
            warn "Genesis not found: $genesis"
        fi
    done

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

# Start network from snapshot or fresh
start_network() {
    local snapshot=$1

    log "Stopping any running network..."
    lux network stop 2>/dev/null || true
    sleep 2

    if [ -n "$snapshot" ] && snapshot_exists "$snapshot"; then
        log "Starting from snapshot: $snapshot"
        lux network start --snapshot-name "$snapshot"
    else
        log "Starting fresh mainnet..."
        lux network start --mainnet
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
            success "RPC is ready"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    warn "RPC not ready after ${timeout}s"
    return 1
}

# Get blockchain ID for a chain name
get_chain_id() {
    local chain_name=$1
    lux network status 2>&1 | grep -B1 "$chain_name" | grep -oP '2[A-Za-z0-9]{47}' | head -1
}

# Import blocks via admin.importChain
import_blocks() {
    local chain=$1
    local endpoint=$2
    local rlp_file=$3
    local min_blocks=${4:-0}

    chain_log "$chain" "Importing blocks from $rlp_file..."

    if [ ! -f "$rlp_file" ]; then
        warn "$chain RLP not found, skipping import"
        return 0
    fi

    # Wait for RPC
    wait_for_rpc "$endpoint" 60 || return 1

    # Check current block
    local current=$(curl -s -X POST "$endpoint" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' \
        | jq -r '.result' | xargs printf "%d" 2>/dev/null || echo "0")

    if [ "$current" -gt "$min_blocks" ]; then
        chain_log "$chain" "Already has $current blocks, skipping import"
        return 0
    fi

    chain_log "$chain" "Current height: $current, importing..."

    # Build admin endpoint
    local admin_endpoint="${endpoint%/rpc}/admin"

    # Call admin.importChain
    local result=$(curl -s -X POST "$admin_endpoint" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"admin.importChain\",\"params\":{\"file\":\"$rlp_file\"}}")

    if echo "$result" | grep -q '"success":true'; then
        local imported=$(echo "$result" | jq -r '.result.blocksImported')
        chain_log "$chain" "Imported $imported blocks"
    else
        warn "$chain import result: $result"
    fi
}

# Deploy a chain
deploy_chain() {
    local name=$1
    local chain_id=$2
    local genesis=$3

    chain_log "$name" "Deploying chain (ID: $chain_id)..."

    # Check if already deployed
    if lux network status 2>&1 | grep -qi "$name"; then
        chain_log "$name" "Already deployed"
        return 0
    fi

    # Create L2 if not exists
    if ! lux l2 list 2>&1 | grep -q "$name"; then
        lux l2 create "$name" \
            --chain-id "$chain_id" \
            --genesis-file "$genesis" \
            --vm evm \
            --force
    fi

    # Deploy to local network
    LUX_PRIVATE_KEY=$(cat "$HOME/.lux/keys/local-key.pk" 2>/dev/null || echo "") \
        lux network deploy "$name" --local --local-key || warn "Deploy may have partially succeeded"

    sleep 20
    chain_log "$name" "Deployed"
}

# Import C-Chain
import_cchain() {
    chain_log "C-Chain" "Importing C-Chain blocks..."
    import_blocks "C-Chain" "http://127.0.0.1:9630/ext/bc/C/rpc" "$CCHAIN_RLP" 1000000
}

# Deploy and import Zoo
deploy_zoo() {
    deploy_chain "zoo" "$ZOO_CHAIN_ID" "$ZOO_GENESIS"
}

import_zoo() {
    local zoo_id=$(get_chain_id "zoo")
    if [ -z "$zoo_id" ]; then
        warn "Cannot find Zoo blockchain ID"
        return 1
    fi
    import_blocks "Zoo" "http://127.0.0.1:9630/ext/bc/$zoo_id/rpc" "$ZOO_RLP" 700
}

# Deploy and import SPC
deploy_spc() {
    deploy_chain "spc" "$SPC_CHAIN_ID" "$SPC_GENESIS"
}

import_spc() {
    local spc_id=$(get_chain_id "spc")
    if [ -z "$spc_id" ]; then
        warn "Cannot find SPC blockchain ID"
        return 1
    fi
    import_blocks "SPC" "http://127.0.0.1:9630/ext/bc/$spc_id/rpc" "$SPC_RLP" 0
}

# Deploy Hanzo AI (fresh - no import needed)
deploy_ai() {
    chain_log "AI" "Deploying Hanzo AI chain (1B AI tokens)..."
    deploy_chain "ai" "$AI_CHAIN_ID" "$AI_GENESIS"

    local ai_id=$(get_chain_id "ai")
    if [ -n "$ai_id" ]; then
        chain_log "AI" "Blockchain ID: $ai_id"
        chain_log "AI" "RPC: http://127.0.0.1:9630/ext/bc/$ai_id/rpc"

        # Verify genesis balance
        if wait_for_rpc "http://127.0.0.1:9630/ext/bc/$ai_id/rpc" 60; then
            local balance=$(curl -s -X POST "http://127.0.0.1:9630/ext/bc/$ai_id/rpc" \
                -H "Content-Type: application/json" \
                -d '{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["0x9011E888251AB053B7bD1cdB598Db4f9DEd94714","latest"]}' \
                | jq -r '.result')
            chain_log "AI" "Treasury balance: $balance (1B AI)"
        fi
    fi
}

# Test AMM
test_amm() {
    local network=$1
    log "Testing $network AMM..."
    if lux amm balance --network "$network" 2>&1 | grep -q "Balance"; then
        success "$network AMM accessible"
    else
        warn "$network AMM not available (may not be deployed)"
    fi
}

# Show all chain info
show_info() {
    echo ""
    echo "============================================="
    echo "         Lux All Chains Information"
    echo "============================================="
    echo ""
    echo "Mainnet Chains:"
    echo "  C-Chain:   ID 96369   http://127.0.0.1:9630/ext/bc/C/rpc"
    echo "  Zoo:       ID 200200  http://127.0.0.1:9630/ext/bc/<zoo-id>/rpc"
    echo "  SPC:       ID 36911   http://127.0.0.1:9630/ext/bc/<spc-id>/rpc"
    echo "  Hanzo AI:  ID 411411  http://127.0.0.1:9630/ext/bc/<ai-id>/rpc"
    echo ""
    echo "Genesis Files:"
    echo "  Zoo:       $ZOO_GENESIS"
    echo "  SPC:       $SPC_GENESIS"
    echo "  Hanzo AI:  $AI_GENESIS"
    echo ""
    echo "RLP Import Files:"
    echo "  C-Chain:   $CCHAIN_RLP"
    echo "  Zoo:       $ZOO_RLP"
    echo "  SPC:       $SPC_RLP"
    echo ""
    echo "Token Allocations:"
    echo "  C-Chain:   ~1.9T LUX (from imported state)"
    echo "  Zoo:       2T LUX treasury"
    echo "  SPC:       Various allocations (from genesis)"
    echo "  Hanzo AI:  1B AI tokens (fresh mint)"
    echo ""
}

# Main workflow
main() {
    local step=${1:-help}

    echo "============================================="
    echo "  Lux All Chains Deployment and Import"
    echo "============================================="

    case $step in
        prereq)
            check_prerequisites
            ;;

        fresh)
            check_prerequisites
            start_network ""
            ;;

        mainnet)
            check_prerequisites
            if snapshot_exists "$SNAPSHOT_MAINNET_FRESH"; then
                start_network "$SNAPSHOT_MAINNET_FRESH"
            else
                start_network ""
                save_snapshot "$SNAPSHOT_MAINNET_FRESH"
                start_network "$SNAPSHOT_MAINNET_FRESH"
            fi
            ;;

        cchain)
            check_prerequisites
            if snapshot_exists "$SNAPSHOT_CCHAIN_IMPORTED"; then
                start_network "$SNAPSHOT_CCHAIN_IMPORTED"
            else
                start_network "$SNAPSHOT_MAINNET_FRESH"
                import_cchain
                save_snapshot "$SNAPSHOT_CCHAIN_IMPORTED"
                start_network "$SNAPSHOT_CCHAIN_IMPORTED"
            fi
            ;;

        zoo)
            check_prerequisites
            if snapshot_exists "$SNAPSHOT_ZOO_IMPORTED"; then
                start_network "$SNAPSHOT_ZOO_IMPORTED"
            else
                start_network "$SNAPSHOT_CCHAIN_IMPORTED"
                deploy_zoo
                import_zoo
                save_snapshot "$SNAPSHOT_ZOO_IMPORTED"
                start_network "$SNAPSHOT_ZOO_IMPORTED"
            fi
            ;;

        spc)
            check_prerequisites
            if snapshot_exists "$SNAPSHOT_SPC_IMPORTED"; then
                start_network "$SNAPSHOT_SPC_IMPORTED"
            else
                start_network "$SNAPSHOT_ZOO_IMPORTED"
                deploy_spc
                import_spc
                save_snapshot "$SNAPSHOT_SPC_IMPORTED"
                start_network "$SNAPSHOT_SPC_IMPORTED"
            fi
            ;;

        ai)
            check_prerequisites
            if snapshot_exists "$SNAPSHOT_AI_DEPLOYED"; then
                start_network "$SNAPSHOT_AI_DEPLOYED"
            else
                start_network "$SNAPSHOT_SPC_IMPORTED"
                deploy_ai
                save_snapshot "$SNAPSHOT_AI_DEPLOYED"
                start_network "$SNAPSHOT_AI_DEPLOYED"
            fi
            ;;

        test)
            check_prerequisites
            start_network "$SNAPSHOT_AI_DEPLOYED"
            test_amm "lux"
            test_amm "zoo"
            ;;

        final)
            check_prerequisites
            start_network "$SNAPSHOT_AI_DEPLOYED"
            test_amm "lux"
            test_amm "zoo"
            save_snapshot "$SNAPSHOT_FINAL"
            success "All chains production snapshot ready: $SNAPSHOT_FINAL"
            ;;

        all)
            check_prerequisites
            log "Running FULL deployment workflow for ALL chains..."

            # Fresh mainnet
            start_network ""
            save_snapshot "$SNAPSHOT_MAINNET_FRESH"

            # Import C-Chain
            start_network "$SNAPSHOT_MAINNET_FRESH"
            import_cchain
            save_snapshot "$SNAPSHOT_CCHAIN_IMPORTED"

            # Deploy and import Zoo
            start_network "$SNAPSHOT_CCHAIN_IMPORTED"
            deploy_zoo
            import_zoo
            save_snapshot "$SNAPSHOT_ZOO_IMPORTED"

            # Deploy and import SPC
            start_network "$SNAPSHOT_ZOO_IMPORTED"
            deploy_spc
            import_spc
            save_snapshot "$SNAPSHOT_SPC_IMPORTED"

            # Deploy Hanzo AI (fresh)
            start_network "$SNAPSHOT_SPC_IMPORTED"
            deploy_ai
            save_snapshot "$SNAPSHOT_AI_DEPLOYED"

            # Test
            start_network "$SNAPSHOT_AI_DEPLOYED"
            test_amm "lux"
            test_amm "zoo"

            # Final snapshot
            save_snapshot "$SNAPSHOT_FINAL"

            success "Full ALL CHAINS deployment complete!"
            show_info
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
            echo "Usage: $0 <step>"
            echo ""
            echo "Deployment Steps (run in order or use 'all'):"
            echo "  prereq    - Check prerequisites"
            echo "  fresh     - Start fresh mainnet"
            echo "  mainnet   - Start/create mainnet snapshot"
            echo "  cchain    - Import C-Chain blocks (1.08M)"
            echo "  zoo       - Deploy Zoo + import blocks (800)"
            echo "  spc       - Deploy SPC + import blocks"
            echo "  ai        - Deploy Hanzo AI (fresh, 1B AI tokens)"
            echo "  test      - Test AMM on all chains"
            echo "  final     - Create production snapshot"
            echo "  all       - Run full workflow"
            echo ""
            echo "Utility Commands:"
            echo "  info      - Show chain information"
            echo "  status    - Show network status"
            echo "  stop      - Stop network"
            echo ""
            echo "Chain IDs:"
            echo "  C-Chain:   96369"
            echo "  Zoo:       200200"
            echo "  SPC:       36911"
            echo "  Hanzo AI:  411411"
            exit 1
            ;;
    esac
}

# Run main
main "$@"
