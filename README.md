# TUI-SH - Text User Interface Library for Bash

A simple bash library for creating text-based user interfaces with immediate keypress response, ANSI color support, and YAML-based configuration.

## Features

- YAML-based configuration for menu layouts
- Immediate keypress handling (no need to press Enter)
- ANSI colors and styling (DTS-compatible color scheme)
- Serial port compatible
- Dynamic content from environment variables
- Conditional section/entry display
- Callback system for menu actions
- Full clear & redraw rendering
- 80-column terminal support with auto-wrapping footer
- Helper functions for custom rendering

## Requirements

- Bash 4.0 or later
- `yq` - YAML processor
- `jq` - JSON processor
- Optional: `bats` for running tests

## Quick Start

### 1. Create a YAML Configuration

Create a file `my-app.yaml`:

```yaml
header:
  title: " My Application ${APP_VERSION} "
  subtitle: " by Your Name "
  link: "https://github.com/yourusername/yourproject"

sections:
  - label: "SYSTEM INFORMATION"
    entries:
      - label: "Hostname"
        value: "${HOSTNAME}"
      - label: "User"
        value: "${USER}"

menu:
  - key: "1"
    label: "Run backup"
    callback: "callbacks/backup.sh"

  - key: "2"
    label: "Check status"
    callback: "callbacks/status.sh"

footer:
  - key: "Q"
    label: "quit"
    callback: "callbacks/quit.sh"

  - key: "R"
    label: "reboot"
    callback: "callbacks/reboot.sh"
```

### 2. Create Callback Scripts

Create `callbacks/backup.sh`:

```bash
#!/bin/bash
echo "Running backup..."
sleep 2
echo "Backup completed!"
exit 0
```

Make it executable:
```bash
chmod +x callbacks/backup.sh
```

### 3. Create Your Application Script

Create `my-app.sh`:

```bash
#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the TUI library
source "${SCRIPT_DIR}/lib/tui-lib.sh"

# Set environment variables
export APP_VERSION="1.0.0"

# Run the TUI
tui_run "${SCRIPT_DIR}/my-app.yaml"
```

### 4. Run Your Application

```bash
chmod +x my-app.sh
./my-app.sh
```

## YAML Configuration Reference

### Header Section

```yaml
header:
  title: "Application Title"        # Main title (supports env vars)
  subtitle: "Optional subtitle"     # Subtitle text (supports env vars)
  link: "https://example.com"       # Optional link (supports env vars)
```

### Information Sections

```yaml
sections:
  - label: "SECTION NAME"           # Section header
    condition: "${SHOW_SECTION}"    # Optional: show/hide section
    entries:
      - label: "Field Name"
        value: "${FIELD_VALUE}"     # Supports env vars
        condition: "${SHOW_FIELD}"  # Optional: show/hide entry
```

### Menu Options

```yaml
menu:
  - key: "1"                        # Single character key
    label: "Menu option text"       # Display text (supports env vars)
    callback: "path/to/script.sh"   # Script to execute
    condition: "${SHOW_OPTION}"     # Optional: show/hide option
```

### Footer Actions

```yaml
footer:
  - key: "Q"                        # Single character key (case-insensitive)
    label: "quit"                   # Action description
    callback: "path/to/script.sh"   # Script to execute
    condition: "${SHOW_ACTION}"     # Optional: show/hide action
```

## Dynamic Content with Environment Variables

Use standard bash variable syntax in your YAML:

```yaml
# Simple variable
value: "${MY_VAR}"

# Variable with default
value: "${MY_VAR:-default value}"

# Command substitution
value: "$(hostname)"
```

## Conditional Display

Control visibility using environment variables:

```yaml
sections:
  - label: "ADMIN SECTION"
    condition: "${IS_ADMIN}"  # Only shown if IS_ADMIN is non-empty and not "false" or "0"
    entries:
      - label: "Secret"
        value: "${SECRET_VALUE}"
```

In your script:
```bash
# Show section
export IS_ADMIN="true"

# Hide section
export IS_ADMIN=""
# or
export IS_ADMIN="false"
# or
export IS_ADMIN="0"
```

## Callback Scripts

Callback scripts are regular bash scripts that:

1. Are executed when a menu/footer option is selected
2. Must be executable (`chmod +x`)
3. Have full screen for output
4. Return to menu after user presses any key

Example callback:

```bash
#!/bin/bash

echo "=== My Action ==="
echo ""
echo "Performing action..."

# Do your work here
sleep 1

echo "Action completed!"

# Exit code is preserved
exit 0
```

The library automatically:
- Clears screen before running callback
- Waits for user keypress after callback completes
- Returns to menu
- Redraws menu

## Library API

### Main Functions

#### `tui_run "config.yaml"`
Main entry point. Loads configuration and starts the TUI loop.

#### `tui_stop`
Stop the TUI loop and exit cleanly.

### Rendering Functions

#### `tui_render`
Renders the complete menu (header, sections, menu, footer).

#### `tui_render_header`
Renders only the header section.

#### `tui_render_info_sections`
Renders all information sections.

#### `tui_render_menu`
Renders menu options.

#### `tui_render_footer`
Renders footer actions.

### Configuration Functions

#### `tui_load_config "file.yaml"`
Loads a YAML configuration file and parses it into bash arrays for fast rendering.

### Helper Functions

#### `tui_visible_length "text"`
Calculate visible text length (stripping ANSI escape codes).

#### `tui_generate_border length [char]`
Generate a border string of specified length (default char: `*`).

#### `tui_echo_normal/red/yellow/green/blue "text"`
Print colored text using ANSI escape codes.

#### `tui_print_warning "message"` / `tui_print_error "message"` / `tui_print_success "message"`
Print styled status messages.

#### `tui_print_border`
Print a full-width border line (respects TUI_MAX_WIDTH=80).

#### `tui_print_section_header "label"`
Print a section header with borders.

#### `tui_print_section_entry "label" "value"`
Print a section entry (label: value format).

#### `tui_print_menu_option "key" "label"`
Print a menu option line.

### Utility Functions

#### `tui_expand_vars "string"`
Expand environment variables in a string.

#### `tui_check_condition "condition"`
Check if a condition evaluates to true.

#### `tui_clear_screen`
Clear the terminal screen.

#### `tui_hide_cursor` / `tui_show_cursor`
Control cursor visibility.

#### `tui_read_key`
Read a single keypress without waiting for Enter.

## Running Tests

Install bats:

**Ubuntu/Debian:**
```bash
sudo apt-get install bats
```

**macOS:**
```bash
brew install bats-core
```

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

Run tests:
```bash
./tests/run-tests.sh
```

Or run bats directly:
```bash
bats tests/tui-lib.bats
```

## Example: Dasharo Tools Suite

See the `examples/` directory for a complete example based on the Dasharo Tools Suite:

```bash
cd examples
./demo.sh
```

This demonstrates:
- Multiple information sections
- Dynamic content from environment variables
- Conditional section display
- Menu options with callbacks
- Footer actions

## Serial Port Compatibility

The library is designed to work over serial ports:

- Uses ANSI escape codes (widely supported)
- Full clear & redraw (avoids complex cursor positioning)
- Immediate keypress handling
- No advanced terminal features required

Tested on:
- Local terminals (bash, zsh, etc.)
- SSH sessions
- Serial consoles (ttyS0, etc.)

## Design Principles

1. **Simplicity**: Easy to create new TUI tools with YAML + callback scripts
2. **Reliability**: Full clear/redraw approach works everywhere
3. **Flexibility**: Dynamic content and conditional display
4. **Maintainability**: Separation of UI (YAML) and logic (callbacks)

## Implementation Details

### Why both `yq` and `jq`?

The library uses both `yq` and `jq` for YAML parsing, which may seem redundant. Here's why:

**Current approach:**
1. `yq` converts YAML → JSON (once, at config load time)
2. `jq` parses the JSON into bash arrays (once, at config load time)
3. Rendering uses **pure bash** (zero external process calls)

**Alternative approaches considered:**

**Option 1: Use only `yq`**
- Pro: Single dependency
- Con: Would need to call `yq` multiple times during parsing
- Con: `yq` is slower than `jq` for JSON queries

**Option 2: Use `yq` with direct output format**
- Use `yq` to output TSV/CSV directly: `yq eval '.menu[] | .key + "\t" + .label' config.yaml`
- Pro: Single dependency
- Con: More complex escaping for special characters
- Con: Still need multiple `yq` calls for nested structures

**Option 3: Current hybrid approach (chosen)**
- `yq` once: YAML → JSON (fast, keeps JSON cached)
- `jq` multiple times: Parse JSON → bash arrays (fast for JSON operations)
- Rendering: Pure bash (instant, no external processes)
- Pro: Fastest overall performance (zero external calls during rendering)
- Pro: `jq` is typically pre-installed on most systems
- Con: Two dependencies instead of one

**Performance comparison:**
- Config loading: Once per application start (acceptable overhead)
- Rendering: **Zero external processes** = instant (critical for responsive UI)

The hybrid approach prioritizes rendering performance, which happens on every menu redraw, over a slightly simpler dependency chain.

## Limitations

- Menu limited to 0-10 options (single keypress)
- Footer limited to 0-10 actions (single keypress)
- No mouse support
- No complex layouts beyond defined sections
- Full screen redraw (brief flicker possible)
