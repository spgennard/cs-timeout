#!/bin/bash

# Script to update package manifests with hashes from GitHub release
# Run this after creating and publishing a GitHub release

set -e

VERSION=${1:-"1.0.0"}
REPO="spgennard/cs-timeout"
BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"

echo "Updating package manifests for version ${VERSION}..."

# Function to get SHA256 from GitHub release
get_github_sha256() {
    local filename=$1
    local url="${BASE_URL}/${filename}"
    echo "Fetching SHA256 for ${filename}..."
    curl -sL "$url" | shasum -a 256 | cut -d' ' -f1
}

# Get hashes from GitHub
echo "Fetching SHA256 hashes from GitHub release..."
ARM64_HASH=$(get_github_sha256 "timeout-${VERSION}-osx-arm64.tar.gz")
X64_HASH=$(get_github_sha256 "timeout-${VERSION}-osx-x64.tar.gz")
WIN_HASH=$(get_github_sha256 "timeout-${VERSION}-win-x64.zip")

echo ""
echo "=== Updating Homebrew Formula ==="

# Update Homebrew formula
if [ -f "homebrew-formula/timeout.rb" ]; then
    # Update version
    sed -i '' "s/version \".*\"/version \"${VERSION}\"/" homebrew-formula/timeout.rb
    
    # Update URLs
    sed -i '' "s|download/v.*/timeout-.*-osx-arm64.tar.gz|download/v${VERSION}/timeout-${VERSION}-osx-arm64.tar.gz|" homebrew-formula/timeout.rb
    sed -i '' "s|download/v.*/timeout-.*-osx-x64.tar.gz|download/v${VERSION}/timeout-${VERSION}-osx-x64.tar.gz|" homebrew-formula/timeout.rb
    
    # Update SHA256 hashes
    sed -i '' "/if Hardware::CPU.arm?/,/else/ { s/sha256 \".*\"/sha256 \"${ARM64_HASH}\"/; }" homebrew-formula/timeout.rb
    sed -i '' "/else/,/end/ { s/sha256 \".*\"/sha256 \"${X64_HASH}\"/; }" homebrew-formula/timeout.rb
    
    echo "✅ Updated homebrew-formula/timeout.rb"
    echo "   ARM64 SHA256: ${ARM64_HASH}"
    echo "   x64 SHA256:   ${X64_HASH}"
else
    echo "❌ homebrew-formula/timeout.rb not found"
fi

echo ""
echo "=== Updating Scoop Manifest ==="

# Update Scoop manifest
if [ -f "scoop-manifest/timeout.json" ]; then
    # Update version, URL, and hash
    sed -i '' "s/\"version\": \".*\"/\"version\": \"${VERSION}\"/" scoop-manifest/timeout.json
    sed -i '' "s|download/v.*/timeout-.*-win-x64.zip|download/v${VERSION}/timeout-${VERSION}-win-x64.zip|" scoop-manifest/timeout.json
    sed -i '' "s/\"hash\": \".*\"/\"hash\": \"${WIN_HASH}\"/" scoop-manifest/timeout.json
    
    echo "✅ Updated scoop-manifest/timeout.json"
    echo "   Windows SHA256: ${WIN_HASH}"
else
    echo "❌ scoop-manifest/timeout.json not found"
fi

echo ""
echo "✅ Package manifests updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the updated files"
echo "2. Commit and push to your package repositories:"
echo "   - Copy homebrew-formula/timeout.rb to your homebrew-timeout repo"
echo "   - Copy scoop-manifest/timeout.json to your scoop-timeout repo"
echo "3. Users can now install the updated version!"