#!/bin/bash

# Multi-platform build script for timeout command

set -e

VERSION=${1:-"1.0.0"}
echo "Building timeout command v${VERSION} for multiple platforms..."

# Clean previous builds
rm -rf releases
mkdir -p releases

# Build for macOS (both architectures)
echo "Building for macOS ARM64..."
dotnet publish timeout.csproj -c Release -r osx-arm64 --self-contained -o "releases/osx-arm64"

echo "Building for macOS x64..."
dotnet publish timeout.csproj -c Release -r osx-x64 --self-contained -o "releases/osx-x64"

# Build for Windows
echo "Building for Windows x64..."
dotnet publish timeout.csproj -c Release -r win-x64 --self-contained -o "releases/win-x64"

# Build for Linux (for completeness)
echo "Building for Linux x64..."
dotnet publish timeout.csproj -c Release -r linux-x64 --self-contained -o "releases/linux-x64"

# Create release packages
echo "Creating release packages..."

# macOS packages
cd releases
tar -czf "timeout-${VERSION}-osx-arm64.tar.gz" -C osx-arm64 timeout
tar -czf "timeout-${VERSION}-osx-x64.tar.gz" -C osx-x64 timeout

# Windows package
zip -j "timeout-${VERSION}-win-x64.zip" win-x64/timeout.exe

# Linux package
tar -czf "timeout-${VERSION}-linux-x64.tar.gz" -C linux-x64 timeout

cd ..

echo "✅ Build complete! Release packages created in ./releases/"
echo "Files created:"
ls -la releases/*.tar.gz releases/*.zip 2>/dev/null || true

echo ""
echo "Next steps:"
echo "1. Upload these files to your GitHub release"
echo "2. Update the SHA256 hashes in your package manifests"
echo "3. Tag your release: git tag v${VERSION} && git push origin v${VERSION}"