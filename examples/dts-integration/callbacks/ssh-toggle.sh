#!/bin/bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Toggle SSH server (simplified example)
# In real DTS integration, this would call the actual footer_options SSH logic

echo "=== SSH Server Toggle ==="
echo

if systemctl is-active sshd.service >/dev/null 2>&1; then
    echo "Stopping SSH server..."
    systemctl stop sshd.service && echo "SSH server stopped" || echo "Failed to stop SSH"
else
    echo "Starting SSH server..."
    systemctl start sshd.service && {
        echo "SSH server started"
        local ip
        ip=$(ip -br -f inet a show scope global | grep UP | awk '{ print $3 }' | tr '\n' ' ')
        echo "Listening on IPs: ${ip:-No IP assigned}"
    } || echo "Failed to start SSH"
fi

exit 0
