#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# DTS with TUI-SH integration
# This script replaces the original dts.sh menu rendering with TUI-SH library

# Get script directory
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUI_LIB_DIR="${SCRIPT_DIR}/../../lib"

# Source DTS environment and functions
# These would normally be sourced from DTS_ENV, DTS_FUNCS, DTS_SUBS
# For this example, we'll mock the essential variables
export DTS_SCRIPTS="${SCRIPT_DIR}/callbacks"

# Source the TUI library
source "${TUI_LIB_DIR}/tui-lib.sh"

# Mock DTS environment variables (in real integration, these come from dts-environment.sh)
# These would be loaded from the actual DTS environment files
setup_dts_environment() {
    # Version info (normally from /etc/os-release)
    export DTS_VERSION="${DTS_VERSION:-2.7.1}"

    # Hardware info (normally from dmidecode)
    export SYSTEM_VENDOR="${SYSTEM_VENDOR:-$(dmidecode -s system-manufacturer 2>/dev/null || echo "Unknown")}"
    export SYSTEM_MODEL="${SYSTEM_MODEL:-$(dmidecode -s system-product-name 2>/dev/null || echo "Unknown")}"
    export BOARD_MODEL="${BOARD_MODEL:-$(dmidecode -s baseboard-product-name 2>/dev/null || echo "Unknown")}"
    export CPU_VERSION="${CPU_VERSION:-$(dmidecode -s processor-version 2>/dev/null || echo "Unknown")}"
    export RAM_INFO="${RAM_INFO:-Not Specified}"

    # Firmware info (normally from dmidecode)
    export BIOS_VENDOR="${BIOS_VENDOR:-$(dmidecode -s bios-vendor 2>/dev/null || echo "Unknown")}"
    export BIOS_VERSION="${BIOS_VERSION:-$(dmidecode -s bios-version 2>/dev/null || echo "Unknown")}"

    # Menu option keys (from dts-environment.sh)
    export HCL_REPORT_OPT="1"
    export DASHARO_FIRM_OPT="2"
    export REST_FIRM_OPT="3"
    export DPP_KEYS_OPT="4"
    export DPP_SUBMENU_OPT="5"
    export TRANSITION_OPT="6"
    export FUSE_OPT="7"
    export REBOOT_OPT_UP="R"
    export POWEROFF_OPT_UP="P"
    export SHELL_OPT_UP="S"
    export SSH_OPT_UP="K"
    export SEND_LOGS_OPT="L"
    export TOGGLE_DISP_CRED_OPT_UP="C"

    # DPP state
    export DPP_IS_LOGGED="${DPP_IS_LOGGED:-}"
    export DPP_EMAIL="${DPP_EMAIL:-}"
    export DPP_PASSWORD="${DPP_PASSWORD:-}"
    export DISPLAY_CREDENTIALS="${DISPLAY_CREDENTIALS:-false}"

    # SSH state
    export SEND_LOGS_ACTIVE="${SEND_LOGS_ACTIVE:-false}"
}

# Update dynamic variables before each render
# This replaces the logic from show_* functions in dts-functions.sh
update_dynamic_state() {
    # Check if Dasharo firmware (logic from check_if_dasharo)
    if [[ "$BIOS_VENDOR" == *"3mdeb"* && "$BIOS_VERSION" == *"Dasharo"* ]]; then
        export SHOW_DASHARO_FIRMWARE="true"
        export DASHARO_FIRMWARE_LABEL="Update Dasharo Firmware"
        export SHOW_TRANSITION="true"
        export SHOW_FUSE="true"
    elif [[ "$SYSTEM_VENDOR" != "QEMU" && "$SYSTEM_VENDOR" != "Emulation" ]]; then
        export SHOW_DASHARO_FIRMWARE="true"
        export DASHARO_FIRMWARE_LABEL="Install Dasharo Firmware"
        export SHOW_TRANSITION=""
        export SHOW_FUSE=""
    else
        export SHOW_DASHARO_FIRMWARE=""
        export SHOW_TRANSITION=""
        export SHOW_FUSE=""
    fi

    # Restore firmware option (hide on QEMU/Emulation)
    if [[ "$SYSTEM_VENDOR" != "QEMU" && "$SYSTEM_VENDOR" != "Emulation" ]]; then
        export SHOW_RESTORE_FIRMWARE="true"
    else
        export SHOW_RESTORE_FIRMWARE=""
    fi

    # DTS extensions (check if submenu JSON exists)
    if [ -f "/var/dasharo-package-manager/packages-scripts/submenu.json" ]; then
        export SHOW_DTS_EXTENSIONS="true"
    else
        export SHOW_DTS_EXTENSIONS=""
    fi

    # DPP credentials display
    if [ -n "$DPP_IS_LOGGED" ]; then
        if [ "$DISPLAY_CREDENTIALS" == "true" ]; then
            export DPP_EMAIL_DISPLAY="$DPP_EMAIL"
            export DPP_PASSWORD_DISPLAY="$DPP_PASSWORD"
            export DPP_KEYS_LABEL="Edit your DPP keys"
            export DISPLAY_CRED_LABEL="hide DPP credentials"
        else
            export DPP_EMAIL_DISPLAY="***************"
            export DPP_PASSWORD_DISPLAY="***************"
            export DPP_KEYS_LABEL="Edit your DPP keys"
            export DISPLAY_CRED_LABEL="display DPP credentials"
        fi
    else
        export DPP_KEYS_LABEL="Load your DPP keys"
        export DISPLAY_CRED_LABEL=""
    fi

    # SSH status (logic from show_ssh_info)
    if systemctl is-active sshd.service >/dev/null 2>&1; then
        export SSH_ACTIVE="true"
        export SSH_STATUS="${TUI_GREEN}ON${TUI_NORMAL}"
        local ip
        ip=$(ip -br -f inet a show scope global | grep UP | awk '{ print $3 }' | tr '\n' ' ')
        if [[ -z "$ip" ]]; then
            export SSH_IP="${TUI_RED}check your connection${TUI_NORMAL}"
        else
            export SSH_IP="$ip"
        fi
        export SSH_LABEL="stop SSH server"
    else
        export SSH_ACTIVE=""
        export SSH_STATUS=""
        export SSH_IP=""
        export SSH_LABEL="launch SSH server"
    fi

    # Send logs label (logic from show_footer)
    if [ "$SEND_LOGS_ACTIVE" == "true" ]; then
        export SEND_LOGS_LABEL="disable sending DTS logs"
    else
        export SEND_LOGS_LABEL="enable sending DTS logs"
    fi
}

# Override tui_render to call subscription_routine and update state
# This replaces the logic from the main loop in dts.sh

# Save the original tui_render function
eval "$(echo "tui_render_original()"; declare -f tui_render | tail -n +2)"

# Override with our custom version
tui_render() {
    # Subscription routine (from dts.sh main loop)
    # In real integration, this would call subscription_routine function
    # subscription_routine

    # Update dynamic state before rendering
    update_dynamic_state

    # Call original render
    tui_render_original
}

# Main function
main() {
    # Setup DTS environment
    setup_dts_environment

    # Trap handlers (from dts.sh)
    trap : 2  # Ignore SIGINT
    trap : 3  # Ignore SIGQUIT
    trap wait_for_input EXIT

    wait_for_input() {
        local code=$?
        if [[ $code -ne 0 ]]; then
            read -p "Press Enter to continue."
        fi
        exit $code
    }

    # Run the TUI
    tui_run "${SCRIPT_DIR}/dts-tui.yaml"
}

# Run main
main
