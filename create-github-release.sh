#!/bin/bash

# Script to create GitHub release and upload assets
# Requires: gh CLI tool (install with: brew install gh)

set -e

VERSION=${1:-"1.0.0"}
REPO="spgennard/cs-timeout"  # Update this to match your actual repo
RELEASE_DIR="releases"

echo "Creating GitHub release for timeout v${VERSION}..."

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is required but not installed."
    echo "Install it with: brew install gh"
    echo "Then authenticate with: gh auth login"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Please authenticate with GitHub CLI first:"
    echo "Run: gh auth login"
    exit 1
fi

# Check if release directory exists
if [ ! -d "$RELEASE_DIR" ]; then
    echo "❌ Release directory not found. Run build-release.sh first."
    exit 1
fi

# Check if tag already exists
if git tag -l | grep -q "^v${VERSION}$"; then
    echo "⚠️  Tag v${VERSION} already exists locally"
else
    echo "Creating git tag v${VERSION}..."
    git tag "v${VERSION}"
    echo "Pushing tag to GitHub..."
    git push origin "v${VERSION}"
fi

# Create release notes
RELEASE_NOTES="## C# Timeout Command v${VERSION}

Cross-platform implementation of the GNU timeout command.

### Downloads

- **macOS ARM64**: \`timeout-${VERSION}-osx-arm64.tar.gz\`
- **macOS Intel**: \`timeout-${VERSION}-osx-x64.tar.gz\`
- **Windows**: \`timeout-${VERSION}-win-x64.zip\`
- **Linux**: \`timeout-${VERSION}-linux-x64.tar.gz\`

### Installation

#### macOS (Homebrew)
\`\`\`bash
brew tap spgennard/timeout
brew install timeout
\`\`\`

#### Windows (Scoop)
\`\`\`powershell
scoop bucket add timeout https://github.com/spgennard/scoop-timeout
scoop install timeout
\`\`\`

#### Manual Installation
Download the appropriate binary for your platform and place it in your PATH."

# Create the release
echo "Creating GitHub release..."
gh release create "v${VERSION}" \
    --repo "$REPO" \
    --title "C# Timeout Command v${VERSION}" \
    --notes "$RELEASE_NOTES" \
    --draft

echo "Uploading release assets..."

# Upload all release files
UPLOAD_COUNT=0
for file in "${RELEASE_DIR}"/timeout-${VERSION}-*; do
    if [ -f "$file" ]; then
        echo "Uploading $(basename "$file")..."
        gh release upload "v${VERSION}" "$file" --repo "$REPO"
        ((UPLOAD_COUNT++))
    fi
done

if [ $UPLOAD_COUNT -eq 0 ]; then
    echo "❌ No release files found to upload"
    exit 1
fi

echo ""
echo "✅ GitHub release created successfully!"
echo "📁 Uploaded $UPLOAD_COUNT file(s)"
echo ""
echo "🔗 View release: https://github.com/${REPO}/releases/tag/v${VERSION}"
echo ""
echo "Next steps:"
echo "1. Review the draft release on GitHub"
echo "2. Publish the release when ready"
echo "3. Update package manifests with the release URLs"
echo "4. Run: ./update-package-hashes.sh ${VERSION}"