# DTS-TUI Integration Example

This example demonstrates how to integrate the TUI-SH library with the Dasharo Tools Suite (DTS) to replace the manual menu rendering code in `dts.sh`.

## Overview

The original DTS (`dts-scripts/scripts/dts.sh`) uses a manual approach with:
- Custom `show_*` functions for rendering sections
- Case statements in `main_menu_options()` and `footer_options()` for handling input
- Manual state management for dynamic content

This integration replaces that with:
- **YAML-based menu configuration** (`dts-tui.yaml`)
- **Callback scripts** for each menu action
- **Dynamic state updates** via environment variables
- **Clean separation** between UI (YAML) and logic (callbacks)

## Architecture

### File Structure

```
dts-integration/
├── dts-tui.sh              # Main script (replaces dts.sh menu loop)
├── dts-tui.yaml            # Menu configuration (replaces show_* functions)
├── callbacks/              # Action handlers (replace *_options functions)
│   ├── hcl-report.sh
│   ├── dasharo-firmware.sh
│   ├── restore-firmware.sh
│   ├── dpp-keys.sh
│   ├── dts-extensions.sh
│   ├── transition.sh
│   ├── fuse.sh
│   ├── reboot.sh
│   ├── poweroff.sh
│   ├── shell.sh
│   ├── ssh-toggle.sh
│   ├── toggle-logs.sh
│   └── toggle-credentials.sh
└── README.md
```

### Integration Points

#### 1. Environment Setup (`setup_dts_environment()`)

Replaces sourcing of DTS environment files:
```bash
# Old DTS:
source $DTS_ENV
source $DTS_FUNCS
source $DTS_SUBS

# TUI Integration:
setup_dts_environment()  # Sets up all needed variables
```

#### 2. Dynamic State Updates (`update_dynamic_state()`)

Replaces the conditional logic from `show_*` functions:
```bash
# Old DTS:
if check_if_dasharo; then
  echo "Update Dasharo Firmware"
fi

# TUI Integration:
if [[ "$BIOS_VENDOR" == *"3mdeb"* ]]; then
  export SHOW_DASHARO_FIRMWARE="true"
  export DASHARO_FIRMWARE_LABEL="Update Dasharo Firmware"
fi
```

Then in YAML:
```yaml
menu:
  - key: "2"
    label: "${DASHARO_FIRMWARE_LABEL}"
    condition: "${SHOW_DASHARO_FIRMWARE}"
```

#### 3. Rendering Override (`tui_render()`)

Replaces the main loop rendering logic:
```bash
# Old DTS:
while :; do
  clear
  subscription_routine
  show_header
  show_hardsoft_inf
  show_main_menu
  show_footer
  read -n 1 OPTION
  main_menu_options $OPTION
done

# TUI Integration:
tui_render() {
  # subscription_routine  # Call if needed
  update_dynamic_state
  tui_render_original
}
tui_run "dts-tui.yaml"
```

#### 4. Callback Scripts

Replace the case statements in `*_options()` functions:

**Old DTS:**
```bash
main_menu_options() {
  case ${OPTION} in
  "1")
    print_disclaimer
    # ... HCL report logic ...
    ;;
  esac
}
```

**TUI Integration:**
```bash
# callbacks/hcl-report.sh
#!/bin/bash
print_disclaimer
# ... HCL report logic ...
```

## Mapping DTS to TUI-SH

### Header Section

**Old DTS (dts-functions.sh:1189-1196):**
```bash
show_header() {
  _os_version=$(grep "VERSION_ID" ${OS_VERSION_FILE} | cut -d "=" -f 2-)
  echo -e "${NORMAL}\n Dasharo Tools Suite Script ${_os_version}"
  echo -e "${NORMAL} (c) Dasharo <contact@dasharo.com>"
  echo -e "${NORMAL} Report issues at: https://github.com/Dasharo/dasharo-issues"
}
```

**TUI YAML:**
```yaml
header:
  title: " Dasharo Tools Suite Script ${DTS_VERSION} "
  subtitle: " (c) Dasharo <contact@dasharo.com> "
  link: "https://github.com/Dasharo/dasharo-issues"
```

### Hardware Information Section

**Old DTS (dts-functions.sh:1198-1211):**
```bash
show_hardsoft_inf() {
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${NORMAL}                HARDWARE INFORMATION"
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${YELLOW}    System Inf.: ${NORMAL}${SYSTEM_VENDOR} ${SYSTEM_MODEL}"
  # ... more entries ...
}
```

**TUI YAML:**
```yaml
sections:
  - label: "HARDWARE INFORMATION"
    entries:
      - label: "System Inf."
        value: "${SYSTEM_VENDOR} ${SYSTEM_MODEL}"
      # ... more entries ...
```

### Conditional Sections (SSH Info)

**Old DTS (dts-functions.sh:1228-1242):**
```bash
show_ssh_info() {
  if systemctl is-active sshd.service >/dev/null 2>&1; then
    ip=$(ip -br -f inet a show scope global | grep UP | awk '{ print $3 }')
    echo -e "${BLUE}**${NORMAL}    SSH status: ${GREEN}ON${NORMAL} IP: ${ip}"
  fi
}
```

**TUI Integration:**
```bash
# In update_dynamic_state():
if systemctl is-active sshd.service >/dev/null 2>&1; then
  export SSH_ACTIVE="true"
  export SSH_STATUS="${TUI_GREEN}ON${TUI_NORMAL}"
  export SSH_IP="$(ip ...)"
fi
```

**TUI YAML:**
```yaml
sections:
  - label: "SSH status: ${SSH_STATUS}"
    condition: "${SSH_ACTIVE}"
    entries:
      - label: "IP"
        value: "${SSH_IP}"
```

### Dynamic Footer Labels

**Old DTS (dts-functions.sh:1461-1465):**
```bash
if systemctl is-active sshd.service >/dev/null 2>&1; then
  echo -ne "${RED}K${NORMAL} to stop SSH server"
else
  echo -ne "${RED}K${NORMAL} to launch SSH server"
fi
```

**TUI Integration:**
```bash
# In update_dynamic_state():
if systemctl is-active sshd.service >/dev/null 2>&1; then
  export SSH_LABEL="stop SSH server"
else
  export SSH_LABEL="launch SSH server"
fi
```

**TUI YAML:**
```yaml
footer:
  - key: "K"
    label: "${SSH_LABEL}"
    callback: "callbacks/ssh-toggle.sh"
```

### Menu Option Handlers

**Old DTS (dts-functions.sh:1485-1500):**
```bash
footer_options() {
  case ${OPTION} in
  "K"|"k")
    if systemctl is-active sshd.service >/dev/null 2>&1; then
      systemctl stop sshd.service
    else
      systemctl start sshd.service
      echo "Listening on IPs: $(ip ...)"
    fi
    read -p "Press Enter to continue."
    return 0
    ;;
  esac
}
```

**TUI Integration (callbacks/ssh-toggle.sh):**
```bash
#!/bin/bash
if systemctl is-active sshd.service >/dev/null 2>&1; then
  systemctl stop sshd.service
else
  systemctl start sshd.service
  echo "Listening on IPs: $(ip ...)"
fi
exit 0
# Library automatically waits for keypress
```

## Real DTS Integration Steps

To integrate this into the actual DTS:

### 1. Add TUI-SH to DTS Repository

```bash
cd dasharo-tools-suite
mkdir -p scripts/lib
cp /path/to/tui-lib.sh scripts/lib/
```

### 2. Modify dts.sh

Replace the main loop in `dts-scripts/scripts/dts.sh`:

```bash
#!/usr/bin/env bash

# Source existing DTS files
source $DTS_ENV
source $DTS_FUNCS
source $DTS_SUBS

# Source TUI library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/tui-lib.sh"

# Add update_dynamic_state function (from this example)
update_dynamic_state() {
  # ... copy from dts-tui.sh ...
}

# Override tui_render
tui_render_original() { tui_render; }
tui_render() {
  subscription_routine
  update_dynamic_state
  tui_render_original
}

# Replace the while loop with:
trap : 2
trap : 3
trap wait_for_input EXIT

wait_for_input() {
  code=$?
  if [[ $code -ne 0 ]]; then
    read -p "Press Enter to continue."
  fi
  exit $code
}

tui_run "${SCRIPT_DIR}/dts-menu.yaml"
```

### 3. Create dts-menu.yaml

Copy `dts-tui.yaml` to `dts-scripts/scripts/dts-menu.yaml`

### 4. Create Callback Scripts

Move existing logic from `main_menu_options()` and `footer_options()` into individual callback scripts under `dts-scripts/scripts/callbacks/`

For example, extract the HCL report logic:
```bash
# callbacks/hcl-report.sh
#!/bin/bash
source $DTS_ENV
source $DTS_FUNCS

print_disclaimer
if ask_for_confirmation "Send logs?"; then
  export SEND_LOGS="true"
  # ... rest of HCL report logic from main_menu_options case "1" ...
fi
exit 0
```

### 5. Handle Submenu (DPP Extensions)

For the DPP submenu functionality, you can either:

**Option A:** Use TUI-SH submenu pattern
- Create a separate `dpp-submenu.yaml`
- Have the DTS extensions callback load that config
- Use `tui_run "dpp-submenu.yaml"` in the callback

**Option B:** Keep existing submenu logic
- The callback calls the existing submenu code
- Returns to main menu afterward

## Benefits of This Integration

1. **Cleaner Code**
   - YAML configuration is easier to read than echo statements
   - Logic separated into small, focused callback scripts
   - No deeply nested case statements

2. **Easier Maintenance**
   - Add new menu items by editing YAML (no code changes)
   - Modify menu order without touching bash code
   - Test callbacks independently

3. **Reusability**
   - Callbacks can be unit tested
   - State management logic is centralized
   - Same pattern works for submenus

4. **Consistency**
   - All menus use the same rendering engine
   - Automatic 80-column support with footer wrapping
   - Consistent color scheme and formatting

5. **Features**
   - Automatic keypress handling (no Enter needed)
   - Built-in conditional rendering
   - Environment variable expansion
   - Footer auto-wrapping for long action lists

## Demo Usage

Run the demo (requires root for dmidecode and systemctl):

```bash
cd examples/dts-integration
sudo ./dts-tui.sh
```

Test dynamic features:
- Press `K` to toggle SSH server (updates "launch/stop" label)
- Press `L` to toggle logs (updates "enable/disable" label)
- Press `C` to toggle credential display (if DPP_IS_LOGGED is set)
- Press `S` to enter shell (type `exit` to return)

## Notes

- This example uses mock data for hardware info (dmidecode calls)
- Callback scripts are stubs - they don't perform actual DTS operations
- In production, callbacks would call existing DTS functions from `dts-functions.sh`
- The `subscription_routine` call is commented out but can be enabled
- Error handling should be added for production use

## Compatibility

The integration maintains compatibility with:
- Serial port operation (ANSI colors only)
- Existing DTS logging infrastructure
- DPP authentication system
- Subscription management
- All existing hardware detection logic

The TUI-SH library handles:
- Screen clearing and rendering
- Keypress input
- Menu navigation
- Callback execution
- Wait-for-keypress after callbacks
