#!/bin/bash

# Complete release automation script
# This script combines building, releasing, and updating package manifests

set -e

VERSION=${1}

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.1"
    exit 1
fi

echo "🚀 Starting complete release process for version ${VERSION}..."

# Step 1: Build release packages
echo ""
echo "📦 Step 1: Building release packages..."
./build-release.sh "$VERSION"

# Step 2: Create GitHub release
echo ""
echo "🏷️  Step 2: Creating GitHub release..."
./create-github-release.sh "$VERSION"

echo ""
echo "⏸️  MANUAL STEP REQUIRED:"
echo "   1. Go to: https://github.com/spgennard/cs-timeout/releases/tag/v${VERSION}"
echo "   2. Review the draft release"
echo "   3. Click 'Publish release' when ready"
echo ""
read -p "Press Enter after you've published the release to continue..."

# Step 3: Update package manifests
echo ""
echo "🔄 Step 3: Updating package manifests..."
./update-package-hashes.sh "$VERSION"

echo ""
echo "✅ Release process completed!"
echo ""
echo "📋 Final steps:"
echo "1. Copy homebrew-formula/timeout.rb to your homebrew-timeout repository"
echo "2. Copy scoop-manifest/timeout.json to your scoop-timeout repository"
echo "3. Commit and push both repositories"
echo ""
echo "🎉 Users can now install timeout v${VERSION}!"