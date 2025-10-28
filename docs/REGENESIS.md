# Lux Regenesis - Public Launch Plan

## Overview

Complete plan for transparent, publicly-verifiable Lux mainnet regenesis with 100 genesis validators.

## Architecture

### Three-Chain Lock-Step Update
- **P-Chain**: Platform chain with validator staking
- **C-Chain**: Contract chain with replay from subnet 96369 (~1M blocks)
- **Q-Chain**: Quantum chain with quantum timestamps

All three chains update in lock-step during quantum replay process.

## Genesis Validators

### Configuration
- **Count**: 100 validators
- **Allocation**: 1B LUX per validator = 100B LUX total
- **Vesting**: Linear unlock over 100 years
- **Staking**: All 100B LUX staked from genesis on P-Chain
- **Recipients**: First 100 validator NFT holders

### Fee Distribution
Each of the 100 genesis validators receives:
- **1% of historical fees** from 1M replayed blocks
- **Staking returns** from P-Chain genesis stake
- This makes genesis validators more valuable than any later staked account

## C-Chain Replay Process

### Source Data
- **Subnet**: 96369
- **Blocks**: ~1,074,617 blocks
- **Method**: Runtime replay via RPC

### Fee Tracking During Replay
```
For each block during replay:
  1. Execute transactions
  2. Track transaction fees
  3. Accumulate fees per validator (1% each)
  4. Update P-Chain staking returns
  5. Update Q-Chain quantum stamps
  6. Commit all three chains atomically
```

### Performance
- **Speed**: 2,000-10,000 blocks/second
- **Duration**: ~11-45 minutes for full replay
- **Zero Downtime**: Replay happens while node is running

## Technical Components

### Repositories and Branches

#### luxfi/node
- **Branch**: `regenesis-runtime-replay`
- **Key Features**:
  - Runtime replay API (`lux_replayStart`, `lux_replayStatus`)
  - PebbleDB reader for SubnetEVM data
  - Blockchain reload for post-replay access
  - Fee tracking and distribution

#### luxfi/geth  
- **Branch**: `regenesis`
- **Key Features**:
  - SubnetEVM migration support
  - Enhanced fee calculation
  - Multi-chain state coordination

#### luxfi/evm
- **Branch**: `regenesis` (to be created)
- **Key Features**:
  - Vesting contract for 100-year unlock
  - Fee distribution contracts
  - NFT validator claim system

#### luxfi/cli
- **Branch**: `regenesis`
- **Key Features**:
  - Migration commands
  - Validator management
  - Network bootstrap tools

#### luxfi/genesis
- **Branch**: `main` (enhanced)
- **Key Features**:
  - 100-validator genesis generation
  - Vesting schedule configuration
  - Fee allocation setup

#### luxfi/regenesis
- **Branch**: `main`
- **Key Features**:
  - Orchestration scripts
  - CI/CD for public verification
  - Documentation

## Implementation Tasks

### Phase 1: Branch Preparation
- [ ] Sync all regenesis branches
- [ ] Resolve any conflicts
- [ ] Ensure consistent versions

### Phase 2: Genesis Configuration
- [ ] Generate 100 validator keys from mnemonic
  - Accounts 0-99 for mainnet validators
  - Accounts 100-199 for testnet validators
- [ ] Configure 1B LUX allocation per validator
- [ ] Set up 100-year vesting schedule
- [ ] Configure P-Chain staking from genesis

### Phase 3: Fee Tracking Implementation
- [ ] Add fee accumulation to replay process
- [ ] Track total fees per block
- [ ] Distribute 1% to each of 100 validators
- [ ] Store fee distribution in genesis state

### Phase 4: Multi-Chain Coordination
- [ ] Implement P/C/Q lock-step updates
- [ ] Sync staking returns across chains
- [ ] Add quantum timestamps to Q-Chain
- [ ] Ensure atomic commits

### Phase 5: Testing
- [ ] Test with small block range (1,000 blocks)
- [ ] Test with medium range (100,000 blocks)
- [ ] Full test with all 1M+ blocks
- [ ] Verify fee distributions
- [ ] Verify vesting schedules
- [ ] Verify staking returns

### Phase 6: CI/CD for Public Verification
- [ ] Publish all source code with tags
- [ ] Add reproducible build instructions
- [ ] CI builds binaries from tagged commits
- [ ] Publish genesis configuration publicly
- [ ] Publish validator public keys
- [ ] Publish fee distribution calculations

### Phase 7: Documentation
- [ ] Public regenesis guide
- [ ] Validator claim process
- [ ] Vesting schedule details
- [ ] Fee distribution methodology
- [ ] Audit trail documentation

### Phase 8: Production Launch
- [ ] Generate real validator keys (secure)
- [ ] Create genesis with 100 validators
- [ ] Launch 5-node bootstrap network
- [ ] Begin C-Chain replay (~11-45 min)
- [ ] Verify all chains synchronized
- [ ] Add remaining 95 validators
- [ ] Open network for public participation

## Test Mnemonic

For CI/CD testing and public verification:
```
copper verify boss hurt cargo mesh shine bunker museum glimpse sausage notable
```

**CRITICAL**: This is for testing only. Real validator keys use secure mnemonic.

## Version Tags

All repositories will be tagged with version:
```
v1.0.0-regenesis
```

This ensures:
- Reproducible builds
- Public verification
- No hidden changes
- Complete transparency

## Security Considerations

### Public Elements
✅ Source code (all tagged)
✅ Build instructions (reproducible)
✅ Genesis configuration (auditable)
✅ Validator public keys (verifiable)
✅ Fee distribution logic (transparent)
✅ Test mnemonic (for CI verification)

### Private Elements  
❌ Production mnemonic (secure offline storage)
❌ Validator private keys (never committed)
❌ Staking private keys (encrypted at rest)

## Success Criteria

1. **Reproducibility**: Anyone can rebuild binaries from source
2. **Transparency**: All genesis allocations publicly auditable
3. **Verifiability**: Fee distributions can be independently verified
4. **Fairness**: All 100 validators receive equal treatment
5. **Performance**: Replay completes in <1 hour
6. **Synchronization**: P/C/Q chains remain in perfect lock-step
7. **Decentralization**: Network opens to public after bootstrap

## Timeline

### Week 1: Preparation
- Branch synchronization
- Genesis configuration
- Fee tracking implementation

### Week 2: Testing
- Small/medium/large scale tests
- Multi-chain synchronization tests
- Performance optimization

### Week 3: Public Release
- Tag all versions
- Publish documentation
- Launch CI/CD verification

### Week 4: Production Launch
- Generate secure keys
- Bootstrap 5-node network
- Complete replay
- Add remaining validators

## Contact

For questions or clarifications:
- GitHub Issues: https://github.com/luxfi/regenesis/issues
- Public Verification: Check CI/CD workflows
- Audit Trail: All commits are signed and timestamped

---

**This is REGENESIS** 🚀
