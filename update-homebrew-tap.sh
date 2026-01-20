#!/bin/bash

# Script to update the Homebrew tap with latest formula
# Usage: ./update-homebrew-tap.sh [version]

set -e

VERSION=${1:-"1.0.0"}
HOMEBREW_TAP_DIR="/Users/spg/src/homebrew-timeout"
RELEASE_DIR="releases"

echo "Updating Homebrew tap for version ${VERSION}..."

# Check if homebrew tap directory exists
if [ ! -d "$HOMEBREW_TAP_DIR" ]; then
    echo "❌ Homebrew tap directory not found: $HOMEBREW_TAP_DIR"
    exit 1
fi

# Check if release files exist
ARM64_FILE="${RELEASE_DIR}/timeout-${VERSION}-osx-arm64.tar.gz"
X64_FILE="${RELEASE_DIR}/timeout-${VERSION}-osx-x64.tar.gz"

if [ ! -f "$ARM64_FILE" ] || [ ! -f "$X64_FILE" ]; then
    echo "❌ Release files not found. Run build-release.sh first."
    echo "Looking for:"
    echo "  - $ARM64_FILE"
    echo "  - $X64_FILE"
    exit 1
fi

# Calculate SHA256 hashes
echo "Calculating SHA256 hashes..."
ARM64_HASH=$(shasum -a 256 "$ARM64_FILE" | cut -d' ' -f1)
X64_HASH=$(shasum -a 256 "$X64_FILE" | cut -d' ' -f1)

echo "ARM64 SHA256: $ARM64_HASH"
echo "x64 SHA256:   $X64_HASH"

# Create updated formula
cat > "${HOMEBREW_TAP_DIR}/Formula/timeout.rb" << EOF
class Timeout < Formula
  desc "C# implementation of the GNU timeout command"
  homepage "https://github.com/spgennard/cs-timeout"
  version "${VERSION}"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/spgennard/cs-timeout/releases/download/v${VERSION}/timeout-${VERSION}-osx-arm64.tar.gz"
    sha256 "${ARM64_HASH}"
  else
    url "https://github.com/spgennard/cs-timeout/releases/download/v${VERSION}/timeout-${VERSION}-osx-x64.tar.gz"
    sha256 "${X64_HASH}"
  end

  def install
    bin.install "timeout"
  end

  test do
    # Test basic functionality
    assert_match "Usage:", shell_output("#{bin}/timeout --help 2>&1")
    
    # Test that it can run a simple command with timeout
    output = shell_output("#{bin}/timeout 1s echo 'test' 2>&1")
    assert_match "test", output
    
    # Test version output if available
    system "#{bin}/timeout", "--version"
  end
end
EOF

echo "✅ Updated Formula/timeout.rb"

# Commit and push to homebrew tap if it's a git repo
cd "$HOMEBREW_TAP_DIR"

if [ -d ".git" ]; then
    echo "Committing changes to homebrew tap..."
    git add Formula/timeout.rb
    git commit -m "Update timeout to version ${VERSION}

- ARM64 SHA256: ${ARM64_HASH}
- x64 SHA256: ${X64_HASH}"
    
    echo "Pushing to GitHub..."
    git push origin main || git push origin master
    echo "✅ Homebrew tap updated and pushed!"
else
    echo "⚠️  Homebrew tap is not a git repository. Please commit manually."
fi

echo ""
echo "🍺 Homebrew tap ready!"
echo "Users can now install with:"
echo "  brew tap spgennard/timeout"
echo "  brew install timeout"