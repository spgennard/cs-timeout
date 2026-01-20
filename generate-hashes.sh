#!/bin/bash

# Script to calculate SHA256 hashes for package manifests
# Run this after uploading release files to GitHub

VERSION=${1:-"1.0.0"}
RELEASE_DIR="releases"

echo "Calculating SHA256 hashes for version ${VERSION}..."
echo ""

if [ ! -d "$RELEASE_DIR" ]; then
    echo "❌ Release directory not found. Run build-release.sh first."
    exit 1
fi

echo "=== Homebrew Formula Hashes ==="
echo "For macOS ARM64:"
if [ -f "${RELEASE_DIR}/timeout-${VERSION}-osx-arm64.tar.gz" ]; then
    ARM64_HASH=$(shasum -a 256 "${RELEASE_DIR}/timeout-${VERSION}-osx-arm64.tar.gz" | cut -d' ' -f1)
    echo "sha256 \"${ARM64_HASH}\""
else
    echo "❌ ARM64 package not found"
fi

echo ""
echo "For macOS x64:"
if [ -f "${RELEASE_DIR}/timeout-${VERSION}-osx-x64.tar.gz" ]; then
    X64_HASH=$(shasum -a 256 "${RELEASE_DIR}/timeout-${VERSION}-osx-x64.tar.gz" | cut -d' ' -f1)
    echo "sha256 \"${X64_HASH}\""
else
    echo "❌ x64 package not found"
fi

echo ""
echo "=== Scoop Manifest Hash ==="
echo "For Windows x64:"
if [ -f "${RELEASE_DIR}/timeout-${VERSION}-win-x64.zip" ]; then
    WIN_HASH=$(shasum -a 256 "${RELEASE_DIR}/timeout-${VERSION}-win-x64.zip" | cut -d' ' -f1)
    echo "\"hash\": \"${WIN_HASH}\""
else
    echo "❌ Windows package not found"
fi

echo ""
echo "=== Update Instructions ==="
echo "1. Update homebrew-formula/timeout.rb with the macOS hashes"
echo "2. Update scoop-manifest/timeout.json with the Windows hash"
echo "3. Update version numbers in both files to ${VERSION}"
echo "4. Commit and push to your package repositories"