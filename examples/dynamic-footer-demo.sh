#!/bin/bash
# Demo script showing dynamic footer labels

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the TUI library
source "$PROJECT_ROOT/lib/tui-lib.sh"

# Initialize state file
STATE_FILE="/tmp/tui-ssh-state"
echo "disabled" > "$STATE_FILE"

# Function to update environment variables based on state file
update_env_from_state() {
    if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "enabled" ]]; then
        export SSH_STATUS="Enabled"
        export SSH_ACTION="disable SSH server"
    else
        export SSH_STATUS="Disabled"
        export SSH_ACTION="enable SSH server"
    fi
}

# Save original tui_render function
eval "$(echo "tui_render_original()"; declare -f tui_render | tail -n +2)"

# Override tui_render to update state before rendering
tui_render() {
    update_env_from_state
    tui_render_original
}

# Initial state
update_env_from_state

# Run the TUI
tui_run "$SCRIPT_DIR/dynamic-footer-demo.yaml"

# Cleanup
rm -f "$STATE_FILE"
