#!/bin/bash
# Example callback: Toggle SSH server

if systemctl is-active --quiet sshd 2>/dev/null; then
    echo "SSH server is currently running."
    echo "Stopping SSH server..."
    # systemctl stop sshd
    echo "SSH server stopped."
else
    echo "SSH server is currently stopped."
    echo "Starting SSH server..."
    # systemctl start sshd
    echo "SSH server started."
    echo ""
    echo "You can now connect via SSH to this machine."
fi

exit 0
