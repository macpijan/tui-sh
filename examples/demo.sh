#!/bin/bash
# Demo script for TUI library

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the TUI library
source "$PROJECT_ROOT/lib/tui-lib.sh"

# Set up example environment variables
export TOOL_VERSION="2.7.1"
export SYSTEM_INFO="Emulation QEMU x86 q35/ich9"
export BASEBOARD_INFO="Emulation QEMU x86 q35/ich9"
export CPU_INFO="Intel Core Processor (Skylake)"
export RAM_INFO="Not Specified"
export BIOS_INFO="3mdeb Dasharo (coreboot+UEFI) v0.2.1-rc1"

# DPP credentials (initially hidden)
export SHOW_DPP_CREDS=""
export DPP_EMAIL="***************"
export DPP_PASSWORD="***************"

# Run the TUI
tui_run "$SCRIPT_DIR/dasharo-tools.yaml"
