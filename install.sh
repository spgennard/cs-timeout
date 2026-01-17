#!/bin/bash

# Build and install script for C# timeout command

set -e  # Exit on any error

echo "Building C# timeout command..."

# Build the project in Release mode
dotnet build -c Release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Create a self-contained executable
echo "Creating self-contained executable..."
dotnet publish -c Release --self-contained true -p:PublishTrimmed=true

if [ $? -ne 0 ]; then
    echo "❌ Publish failed!"
    exit 1
fi

echo "✅ Self-contained executable created!"

# Find the published executable
RUNTIME_ID=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $(uname -m) == "arm64" ]]; then
        RUNTIME_ID="osx-arm64"
    else
        RUNTIME_ID="osx-x64"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    RUNTIME_ID="linux-x64"
else
    echo "❌ Unsupported OS: $OSTYPE"
    exit 1
fi

PUBLISH_DIR="bin/Release/net8.0/$RUNTIME_ID/publish"
EXECUTABLE_PATH="$PUBLISH_DIR/timeout"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "❌ Executable not found at $EXECUTABLE_PATH"
    exit 1
fi

echo "✅ Executable found at: $EXECUTABLE_PATH"

# Test the executable
echo ""
echo "Testing the executable..."
echo "----------------------------------------"

# Test help
echo "Testing --help:"
$EXECUTABLE_PATH --help
echo ""

# Test version  
echo "Testing --version:"
$EXECUTABLE_PATH --version
echo ""

# Test basic functionality
echo "Testing basic timeout (1s timeout with 'sleep 0.5'):"
$EXECUTABLE_PATH 1s sleep 0.5
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Basic test passed"
else
    echo "❌ Basic test failed with exit code $EXIT_CODE"
    exit 1
fi

echo ""
echo "Testing timeout scenario (1s timeout with 'sleep 3'):"
$EXECUTABLE_PATH 1s sleep 3
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
    echo "✅ Timeout test passed"
else
    echo "❌ Timeout test failed with exit code $EXIT_CODE"
    exit 1
fi

echo ""
echo "----------------------------------------"
echo "✅ All tests passed!"

# Offer to install the executable
echo ""
echo "Installation options:"
echo "1. Copy to /usr/local/bin (requires sudo)"
echo "2. Copy to ~/bin (user local)"
echo "3. Skip installation"
echo ""
read -p "Choose option (1/2/3): " choice

case $choice in
    1)
        echo "Installing to /usr/local/bin..."
        sudo cp "$EXECUTABLE_PATH" /usr/local/bin/timeout-cs
        sudo chmod +x /usr/local/bin/timeout-cs
        echo "✅ Installed as 'timeout-cs' in /usr/local/bin"
        echo "You can now use: timeout-cs 10s some-command"
        ;;
    2)
        mkdir -p ~/bin
        cp "$EXECUTABLE_PATH" ~/bin/timeout-cs
        chmod +x ~/bin/timeout-cs
        echo "✅ Installed as 'timeout-cs' in ~/bin"
        echo "Make sure ~/bin is in your PATH"
        echo "You can now use: timeout-cs 10s some-command"
        ;;
    3)
        echo "Installation skipped."
        echo "You can run the executable directly from: $EXECUTABLE_PATH"
        ;;
    *)
        echo "Invalid option. Installation skipped."
        ;;
esac

echo ""
echo "Build and setup complete! 🎉"