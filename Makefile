# Lux Mainnet Regenesis Makefile
# ================================
# Orchestrates 5-node mainnet launch with C-chain replay from subnet 96369

# ============================================================================
# Configuration
# ============================================================================

# Directories
ROOT_DIR := $(shell pwd)
GENESIS_ROOT := $(ROOT_DIR)/../genesis
NODE_ROOT := $(ROOT_DIR)/../node
CLI_ROOT := $(ROOT_DIR)/../cli

OUT_DIR := $(ROOT_DIR)/output
SCRIPTS_DIR := $(ROOT_DIR)/scripts

# Binaries
DERIVE_VALIDATORS := $(GENESIS_ROOT)/bin/derive-validators
GENESIS := $(GENESIS_ROOT)/bin/genesis
LUXD := $(NODE_ROOT)/build/luxd
LUX_CLI := $(CLI_ROOT)/cli

# Network
NETWORK_ID := 96369
VALIDATORS := 5
SUBNET_ID := 96369

# Load environment
-include $(ROOT_DIR)/.env
export

# ============================================================================
# Main Targets
# ============================================================================

.PHONY: all mainnet testnet clean help

all: validators genesis network subnet replay ## Complete regenesis workflow

mainnet: validators genesis network ## Launch mainnet (no subnet/replay)

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ============================================================================
# Phase Targets
# ============================================================================

validators: check-bins $(OUT_DIR)/validators/.done ## Generate validator keys

genesis: validators $(OUT_DIR)/config/.done ## Generate genesis files

network: genesis $(OUT_DIR)/network/.running ## Launch network

subnet: network $(OUT_DIR)/subnet/.deployed ## Deploy subnet 96369

replay: subnet $(OUT_DIR)/replay/.complete ## Replay C-chain history

# ============================================================================
# Implementation
# ============================================================================

check-bins:
	@$(SCRIPTS_DIR)/check-prerequisites.sh

$(OUT_DIR)/validators/.done:
	@mkdir -p $(OUT_DIR)/validators
	@echo "Generating validators..."
	@$(SCRIPTS_DIR)/generate-validators.sh $(VALIDATORS)
	@touch $@

$(OUT_DIR)/config/.done: $(OUT_DIR)/validators/.done
	@mkdir -p $(OUT_DIR)/config
	@echo "Generating genesis..."
	@$(SCRIPTS_DIR)/generate-genesis-proper.sh $(NETWORK_ID)
	@touch $@

$(OUT_DIR)/network/.running: $(OUT_DIR)/config/.done
	@mkdir -p $(OUT_DIR)/data $(OUT_DIR)/logs
	@echo "Launching network..."
	@$(SCRIPTS_DIR)/launch-network.sh $(VALIDATORS)
	@touch $@

$(OUT_DIR)/subnet/.deployed: $(OUT_DIR)/network/.running
	@echo "Deploying subnet..."
	@$(SCRIPTS_DIR)/deploy-subnet.sh $(SUBNET_ID)
	@touch $@

$(OUT_DIR)/replay/.complete: $(OUT_DIR)/subnet/.deployed
	@echo "Starting replay..."
	@$(SCRIPTS_DIR)/replay-cchain.sh $(SUBNET_ID)
	@touch $@

# ============================================================================
# Management
# ============================================================================

status: ## Show network status
	@$(SCRIPTS_DIR)/network-status.sh

logs: ## Tail logs
	@tail -f $(OUT_DIR)/logs/*.log

stop: ## Stop network
	@$(SCRIPTS_DIR)/stop-network.sh
	@rm -f $(OUT_DIR)/network/.running

clean: stop ## Clean output
	@rm -rf $(OUT_DIR)

.PHONY: status logs stop check-bins
