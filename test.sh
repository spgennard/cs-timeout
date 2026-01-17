#!/bin/bash

# Test script for the C# timeout implementation

echo "Building the timeout project..."
dotnet build -c Release

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Running tests..."

# Test 1: Basic timeout functionality
echo "Test 1: Basic timeout (should timeout after 2 seconds)"
dotnet run --project . --configuration Release -- 2s sleep 5
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
    echo "✅ Test 1 passed: Timeout occurred as expected (exit code $EXIT_CODE)"
else
    echo "❌ Test 1 failed: Expected exit code 124, got $EXIT_CODE"
fi

echo ""

# Test 2: Command completes before timeout
echo "Test 2: Command completion (should complete normally)"
dotnet run --project . --configuration Release -- 5s sleep 1
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test 2 passed: Command completed normally (exit code $EXIT_CODE)"
else
    echo "❌ Test 2 failed: Expected exit code 0, got $EXIT_CODE"
fi

echo ""

# Test 3: Verbose mode
echo "Test 3: Verbose mode (should show signal information)"
dotnet run --project . --configuration Release -- -v 2s sleep 5
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
    echo "✅ Test 3 passed: Verbose timeout occurred as expected (exit code $EXIT_CODE)"
else
    echo "❌ Test 3 failed: Expected exit code 124, got $EXIT_CODE"
fi

echo ""

# Test 4: Help option
echo "Test 4: Help display"
dotnet run --project . --configuration Release -- --help
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test 4 passed: Help displayed successfully (exit code $EXIT_CODE)"
else
    echo "❌ Test 4 failed: Expected exit code 0, got $EXIT_CODE"
fi

echo ""

# Test 5: Version option
echo "Test 5: Version display"
dotnet run --project . --configuration Release -- --version
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test 5 passed: Version displayed successfully (exit code $EXIT_CODE)"
else
    echo "❌ Test 5 failed: Expected exit code 0, got $EXIT_CODE"
fi

echo ""

# Test 6: Invalid command
echo "Test 6: Invalid command (should return 127)"
dotnet run --project . --configuration Release -- 5s nonexistent_command_12345
EXIT_CODE=$?
if [ $EXIT_CODE -eq 127 ]; then
    echo "✅ Test 6 passed: Invalid command handled correctly (exit code $EXIT_CODE)"
else
    echo "❌ Test 6 failed: Expected exit code 127, got $EXIT_CODE"
fi

echo ""

# Test 7: Different time units
echo "Test 7: Different time units (1500ms = 1.5s, should timeout)"
dotnet run --project . --configuration Release -- 1500ms sleep 3
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
    echo "✅ Test 7 passed: Millisecond timeout worked (exit code $EXIT_CODE)"
else
    echo "❌ Test 7 failed: Expected exit code 124, got $EXIT_CODE"
fi

echo ""
echo "All tests completed!"