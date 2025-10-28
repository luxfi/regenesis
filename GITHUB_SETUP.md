# GitHub Setup for Regenesis CI

## Repository Setup

### 1. Create Repository
```bash
# Option A: Create new repo
gh repo create luxfi/regenesis --public --description "Lux Mainnet Regenesis Workflow"

# Option B: Push to existing repo
cd ~/work/lux/regenesis
git init
git remote add origin git@github.com:luxfi/regenesis.git
```

### 2. Add GitHub Secret

Go to: `https://github.com/luxfi/regenesis/settings/secrets/actions`

Add new secret:
- **Name**: `TEST_MNEMONIC`
- **Value**: `cradle decrease involve tornado fatigue finger replace wash tilt leader bundle camp hospital auto hunt cricket wrong flock fan under door winner add athlete`

This is a **test-only mnemonic** for CI/CD. Never use for real funds!

### 3. Required Repository Settings

#### Workflow Permissions
Navigate to: `Settings → Actions → General → Workflow permissions`

Enable:
- ✅ Read and write permissions
- ✅ Allow GitHub Actions to create and approve pull requests

#### Branch Protection (Optional)
For `main` branch:
- ✅ Require status checks to pass before merging
- ✅ Require `E2E Regenesis Test` to pass

## CI/CD Workflows

### Automatic Triggers

**test-5-node-network** (always runs):
- ✅ On push to `main` or `develop`
- ✅ On pull requests
- ⏱️ Duration: ~5 minutes
- Tests: Generate keys → Genesis → Launch → Health check

**test-subnet-deployment** (always runs):
- ✅ On push to `main` or `develop`
- ✅ On pull requests
- ⏱️ Duration: ~10 minutes
- Tests: Full network + subnet deployment

**test-full-replay** (manual/main only):
- ⚠️ Manual trigger or `main` branch only
- ⏱️ Duration: ~6 hours
- Tests: Complete regenesis with C-chain replay (~1M blocks)

### Manual Workflow Trigger

To run full replay test:
```bash
# Via GitHub CLI
gh workflow run e2e-regenesis.yml --ref main -f run_replay=true

# Or via GitHub UI:
# Actions → E2E Regenesis Test → Run workflow → ✅ Run full replay
```

## State/Asset Requirements

### For Basic Tests (5-node network)
- No external state needed
- Generates everything from mnemonic
- ⏱️ Fast: ~5 minutes

### For Subnet Deployment
- **Optional**: Pre-synced subnet 96369 state
- Can deploy subnet from scratch (slower)
- **TODO**: Upload subnet state to S3/GitHub releases

### For Full Replay
- **Required**: Subnet 96369 full state (~1M blocks)
- **TODO**: Set up state backup/restore:
  ```bash
  # Upload state snapshot
  aws s3 sync ./subnet-96369-state/ s3://lux-mainnet-state/subnet-96369/

  # CI will download via:
  # aws s3 sync s3://lux-mainnet-state/subnet-96369/ ./output/subnet-state/
  ```

## Repository Structure

```
luxfi/regenesis/
├── .github/
│   └── workflows/
│       └── e2e-regenesis.yml    # Main CI workflow
├── scripts/                      # Helper scripts
├── Makefile                      # Orchestration
├── README.md                     # Main documentation
├── QUICKSTART.md                 # Quick start guide
├── GITHUB_SETUP.md              # This file
└── .env.example                  # Environment template
```

## CI Status Badges

Add to README.md:

```markdown
[![E2E Tests](https://github.com/luxfi/regenesis/actions/workflows/e2e-regenesis.yml/badge.svg)](https://github.com/luxfi/regenesis/actions/workflows/e2e-regenesis.yml)
```

## Testing the CI Pipeline

### 1. Test Locally First
```bash
cd ~/work/lux/regenesis

# Use test mnemonic
export MAINNET_MNEMONIC="cradle decrease involve tornado fatigue finger replace wash tilt leader bundle camp hospital auto hunt cricket wrong flock fan under door winner add athlete"
echo "MAINNET_MNEMONIC=\"$MAINNET_MNEMONIC\"" > .env

# Run full workflow
make all
```

### 2. Push and Monitor
```bash
git add .
git commit -m "Add regenesis CI/CD pipeline"
git push origin main

# Watch CI run
gh run watch
```

### 3. Debug CI Failures
```bash
# View logs
gh run view --log

# Download artifacts
gh run download <run-id>
```

## State Management Strategy

### Option 1: GitHub Releases (Small States <2GB)
```bash
# Create release with state snapshot
gh release create v1.0.0-state \
  --title "Subnet 96369 State Snapshot" \
  --notes "Full subnet state for regenesis testing" \
  subnet-96369-state.tar.gz
```

### Option 2: S3/Cloud Storage (Large States)
```yaml
# In CI workflow
- name: Download state
  run: |
    aws s3 sync s3://lux-mainnet-state/subnet-96369/ ./output/subnet-state/
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Option 3: IPFS/Filecoin (Decentralized)
```bash
# Upload to IPFS
ipfs add -r subnet-96369-state/
# CID: QmXxx...

# CI downloads via HTTP gateway
curl "https://ipfs.io/ipfs/QmXxx..." | tar xz
```

## Security

### Secrets Management
- ✅ `TEST_MNEMONIC` - Test-only, publicly documented
- ❌ Never commit production mnemonics
- ❌ Never commit validator private keys
- ❌ Never commit .env files

### State Data
- ✅ Public testnet state - safe to share
- ⚠️ Mainnet state - verify no sensitive data before sharing
- ✅ Use checksums to verify state integrity

## Troubleshooting

### CI times out
- Increase `timeout-minutes` in workflow
- Use faster runners (`ubuntu-latest-8-cores`)
- Cache Go modules for faster builds

### State download fails
- Check AWS credentials in secrets
- Verify S3 bucket permissions
- Use GitHub releases as fallback

### Network won't start in CI
- Check `make logs` output
- Verify all binaries built correctly
- Ensure ports aren't in use

## Next Steps

1. ✅ Add test mnemonic to GitHub secrets
2. ✅ Push code to GitHub
3. ⏳ Watch first CI run
4. ⏳ Upload subnet state snapshot (for full replay tests)
5. ⏳ Document any CI-specific quirks
6. ⏳ Add status badges to README
