#!/bin/bash
# Test runner script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if bats is installed
if ! command -v bats &>/dev/null; then
    echo "Error: bats is not installed"
    echo ""
    echo "Install bats:"
    echo "  - Ubuntu/Debian: sudo apt-get install bats"
    echo "  - macOS: brew install bats-core"
    echo "  - From source: git clone https://github.com/bats-core/bats-core.git && cd bats-core && sudo ./install.sh /usr/local"
    exit 1
fi

# Check if yq is installed
if ! command -v yq &>/dev/null; then
    echo "Warning: yq is not installed. Some tests will be skipped."
    echo ""
    echo "Install yq:"
    echo "  - macOS: brew install yq"
    echo "  - Linux: sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq"
    echo ""
fi

echo "Running TUI library tests..."
echo ""

# Run tests
bats "$SCRIPT_DIR/tui-lib.bats"

echo ""
echo "Tests completed!"
