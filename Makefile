.PHONY: build clean test install publish help

# Default target
all: build

# Build the project in debug mode
build:
	dotnet build

# Build in release mode
release:
	dotnet build -c Release

# Clean build artifacts
clean:
	dotnet clean
	rm -rf bin obj

# Run tests
test: build
	@echo "Running basic tests..."
	@echo "Testing help output:"
	@dotnet run -- --help
	@echo ""
	@echo "Testing version output:"
	@dotnet run -- --version
	@echo ""
	@echo "Testing command completion (should exit 0):"
	@dotnet run -- 2s sleep 1; echo "Exit code: $$?"
	@echo ""
	@echo "Testing timeout scenario (should exit 124):"
	@dotnet run -- 1s sleep 3; echo "Exit code: $$?"

# Create self-contained executable
publish: release
	dotnet publish -c Release --self-contained true -p:PublishTrimmed=true

# Install to /usr/local/bin (requires sudo)
install: publish
	@RUNTIME_ID=""; \
	if [ "$$(uname)" = "Darwin" ]; then \
		if [ "$$(uname -m)" = "arm64" ]; then \
			RUNTIME_ID="osx-arm64"; \
		else \
			RUNTIME_ID="osx-x64"; \
		fi; \
	elif [ "$$(uname)" = "Linux" ]; then \
		RUNTIME_ID="linux-x64"; \
	else \
		echo "Unsupported OS"; exit 1; \
	fi; \
	EXECUTABLE_PATH="bin/Release/net8.0/$$RUNTIME_ID/publish/timeout"; \
	if [ ! -f "$$EXECUTABLE_PATH" ]; then \
		echo "Executable not found. Run 'make publish' first."; exit 1; \
	fi; \
	sudo cp "$$EXECUTABLE_PATH" /usr/local/bin/timeout; \
	sudo chmod +x /usr/local/bin/timeout; \
	echo "Installed as 'timeout' in /usr/local/bin"

# Install to ~/bin
install-user: publish
	@RUNTIME_ID=""; \
	if [ "$$(uname)" = "Darwin" ]; then \
		if [ "$$(uname -m)" = "arm64" ]; then \
			RUNTIME_ID="osx-arm64"; \
		else \
			RUNTIME_ID="osx-x64"; \
		fi; \
	elif [ "$$(uname)" = "Linux" ]; then \
		RUNTIME_ID="linux-x64"; \
	else \
		echo "Unsupported OS"; exit 1; \
	fi; \
	EXECUTABLE_PATH="bin/Release/net8.0/$$RUNTIME_ID/publish/timeout"; \
	if [ ! -f "$$EXECUTABLE_PATH" ]; then \
		echo "Executable not found. Run 'make publish' first."; exit 1; \
	fi; \
	mkdir -p ~/bin; \
	cp "$$EXECUTABLE_PATH" ~/bin/timeout; \
	chmod +x ~/bin/timeout; \
	echo "Installed as 'timeout' in ~/bin"

# Show help
help:
	@echo "Available targets:"
	@echo "  build        - Build the project in debug mode"
	@echo "  release      - Build the project in release mode"  
	@echo "  clean        - Clean build artifacts"
	@echo "  test         - Run basic functionality tests"
	@echo "  publish      - Create self-contained executable"
	@echo "  install      - Install to /usr/local/bin (requires sudo)"
	@echo "  install-user - Install to ~/bin"
	@echo "  help         - Show this help message"