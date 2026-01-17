# C# Timeout Command

A C# implementation of the GNU `timeout` command, compatible with the original's interface and behavior.

## Description

This timeout utility runs a command with a specified time limit. If the command doesn't complete within the given duration, it will be terminated.

## Features

- Compatible with GNU timeout command syntax
- Cross-platform support (Windows, macOS, Linux)
- Support for various time units (seconds, minutes, hours, days, milliseconds)
- Signal handling on Unix systems
- Multiple command-line options for fine-tuned control
- Proper exit codes matching GNU timeout behavior

## Building

### Prerequisites
- .NET 8.0 SDK or later

### Build Commands

```bash
# Debug build
dotnet build

# Release build
dotnet build -c Release

# Create self-contained executable
dotnet publish -c Release --self-contained true
```

## Usage

```bash
timeout [OPTION] DURATION COMMAND [ARG]...
```

### Examples

```bash
# Run a command with 10 second timeout
timeout 10s ping google.com

# Use minutes
timeout 5m long-running-script.sh

# Verbose mode with custom signal
timeout -v -s INT 30s some-command

# Kill after additional time if needed
timeout -k 10s 60s stuck-command

# Preserve the exit status of the command
timeout -p 30s command-that-might-fail
```

### Duration Format

DURATION is a floating point number with an optional suffix:
- `s` for seconds (default)
- `ms` for milliseconds  
- `m` for minutes
- `h` for hours
- `d` for days

Examples: `10`, `10s`, `1.5m`, `2h`, `0.5d`

### Options

- `-f, --foreground`: Allow COMMAND to read from TTY and get TTY signals
- `-k, --kill-after=DURATION`: Also send KILL signal after DURATION  
- `-p, --preserve-status`: Exit with same status as COMMAND
- `-s, --signal=SIGNAL`: Specify signal to send on timeout (Unix only)
- `-v, --verbose`: Diagnose to stderr any signal sent
- `--help`: Display help and exit
- `--version`: Output version information and exit

### Signals (Unix Systems)

- `TERM` (default) - Terminate signal
- `KILL` - Kill signal (cannot be caught)
- `INT` - Interrupt signal  
- `HUP` - Hangup signal
- `USR1`, `USR2` - User-defined signals
- Numeric values (e.g., `9` for KILL)

## Exit Codes

The timeout command uses these exit codes to indicate different conditions:

- `0`: Success (command completed normally)
- `124`: Timeout occurred (command was killed due to timeout)
- `125`: Internal timeout error
- `126`: Command found but not executable
- `127`: Command not found
- `137`: Command killed by KILL signal

When `--preserve-status` is used and timeout occurs, the exit code of the original command is returned instead of 124.

## Platform Differences

### Windows
- Signal handling is limited (only termination is supported)
- Process tree termination is used for better cleanup

### Unix/Linux/macOS  
- Full signal support using native system calls
- More precise process control

## Compatibility

This implementation aims for compatibility with GNU coreutils timeout command, supporting:

- All major command-line options
- Same exit code behavior  
- Compatible duration parsing
- Signal handling (where platform supports it)
- Help and version output format

## Examples in Practice

```bash
# Timeout a network operation
timeout 30s curl https://slow-website.example.com

# Run a backup with 2 hour limit, kill forcefully after additional 10 minutes
timeout -k 10m 2h backup-script.sh

# Test if a service responds within 5 seconds, preserve exit code
timeout -p 5s service-health-check.sh

# Run interactive command with TTY access
timeout -f 60s interactive-program

# Verbose logging of signal sending
timeout -v -s KILL 10s stubborn-process
```

## Building for Distribution

To create optimized, self-contained executables for distribution:

```bash
# For current platform
dotnet publish -c Release --self-contained true -p:PublishTrimmed=true

# For specific platforms
dotnet publish -c Release -r linux-x64 --self-contained true -p:PublishTrimmed=true
dotnet publish -c Release -r osx-arm64 --self-contained true -p:PublishTrimmed=true  
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishTrimmed=true
```

The resulting executable will be in `bin/Release/net8.0/{runtime}/publish/timeout` (or `timeout.exe` on Windows).

## Author

**Stephen Gennard**  
Email: stephen@gennard.net  
GitHub: https://github.com/spgennard/cs-timeout

## License

This project is open source. See the repository for license details.