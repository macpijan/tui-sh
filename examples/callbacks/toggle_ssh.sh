#!/bin/bash
# Toggle SSH server state (simulated)

# Read current state from temp file (simulating systemd state)
STATE_FILE="/tmp/tui-ssh-state"

if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "enabled" ]]; then
    echo "SSH Server is currently: Enabled"
    echo "Disabling SSH server..."
    echo "disabled" > "$STATE_FILE"
    echo "SSH server disabled."
else
    echo "SSH Server is currently: Disabled"
    echo "Enabling SSH server..."
    echo "enabled" > "$STATE_FILE"
    echo "SSH server enabled."
fi

echo ""
echo "State saved to: $STATE_FILE"
echo "Current state: $(cat $STATE_FILE)"

exit 0
