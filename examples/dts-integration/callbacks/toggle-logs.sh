#!/bin/bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Toggle DTS logs sending

if [ "$SEND_LOGS_ACTIVE" == "true" ]; then
    unset SEND_LOGS_ACTIVE
    echo "DTS logs sending disabled"
else
    export SEND_LOGS_ACTIVE="true"
    echo "DTS logs sending enabled"
fi

exit 0
