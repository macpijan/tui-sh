#!/bin/bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Toggle DPP credentials display
# This modifies environment variable that controls credential visibility

if [ "$DISPLAY_CREDENTIALS" == "true" ]; then
    unset DISPLAY_CREDENTIALS
    echo "DPP credentials will be hidden"
else
    export DISPLAY_CREDENTIALS="true"
    echo "DPP credentials will be displayed"
fi

exit 0
