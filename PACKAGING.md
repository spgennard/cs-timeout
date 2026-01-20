# Cross-Platform Package Distribution Setup

This guide helps you set up package distribution for both macOS (Homebrew) and Windows (Scoop).

## Quick Setup

1. **Build releases**:
   ```bash
   chmod +x build-release.sh
   ./build-release.sh 1.0.0
   ```

2. **Create GitHub release** with the generated files

3. **Set up package repositories** (see below)

## macOS - Homebrew Setup

### 1. Create Homebrew Tap Repository
Create a new GitHub repository named: `homebrew-timeout`

### 2. Repository Structure
```
homebrew-timeout/
├── README.md
└── Formula/
    └── timeout.rb
```

### 3. Upload the Formula
Copy `homebrew-formula/timeout.rb` to `Formula/timeout.rb` in your tap repository.

### 4. Update SHA256 Hashes
After uploading release files to GitHub:
```bash
# Get SHA256 for macOS ARM64
shasum -a 256 timeout-1.0.0-osx-arm64.tar.gz

# Get SHA256 for macOS x64
shasum -a 256 timeout-1.0.0-osx-x64.tar.gz
```

Update the `sha256` values in the formula.

### 5. Installation
Users can install with:
```bash
brew tap spgennard/timeout
brew install timeout
```

## Windows - Scoop Setup

### 1. Create Scoop Bucket Repository
Create a new GitHub repository named: `scoop-timeout`

### 2. Repository Structure
```
scoop-timeout/
├── README.md
└── bucket/
    └── timeout.json
```

### 3. Upload the Manifest
Copy `scoop-manifest/timeout.json` to `bucket/timeout.json` in your bucket repository.

### 4. Update SHA256 Hash
```bash
# Get SHA256 for Windows
shasum -a 256 timeout-1.0.0-win-x64.zip
```

Update the `hash` value in the manifest.

### 5. Installation
Users can install with:
```powershell
scoop bucket add timeout https://github.com/spgennard/scoop-timeout
scoop install timeout
```

## Complete Workflow

1. **Make code changes**
2. **Run build script**: `./build-release.sh 1.0.1`
3. **Create GitHub release** with generated files
4. **Update SHA256 hashes** in both formula and manifest
5. **Commit package updates** to respective repositories
6. **Users get updates** automatically

## Repository URLs You'll Need

- Main project: `https://github.com/spgennard/cs-timeout`
- Homebrew tap: `https://github.com/spgennard/homebrew-timeout`  
- Scoop bucket: `https://github.com/spgennard/scoop-timeout`

## Testing Locally

### Test Homebrew Formula
```bash
brew install --build-from-source ./homebrew-formula/timeout.rb
brew test timeout
```

### Test Scoop Manifest
```powershell
scoop install ./scoop-manifest/timeout.json
```