#!/usr/bin/env bats
# Unit tests for TUI library

setup() {
    # Load the library
    source "${BATS_TEST_DIRNAME}/../lib/tui-lib.sh"

    # Create temporary directory for test files
    TEST_DIR=$(mktemp -d)
    export TEST_DIR
}

teardown() {
    # Clean up temporary directory
    rm -rf "$TEST_DIR"
}

# Test: Library can be sourced
@test "Library loads without errors" {
    run bash -c "source ${BATS_TEST_DIRNAME}/../lib/tui-lib.sh && echo success"
    [ "$status" -eq 0 ]
    [[ "$output" == *"success"* ]]
}

# Test: Environment variable expansion
@test "tui_expand_vars expands environment variables" {
    export TEST_VAR="hello"
    run tui_expand_vars "Value is \$TEST_VAR"
    [ "$status" -eq 0 ]
    [ "$output" = "Value is hello" ]
}

@test "tui_expand_vars handles missing variables" {
    unset MISSING_VAR
    run tui_expand_vars "Value is \${MISSING_VAR:-default}"
    [ "$status" -eq 0 ]
    [ "$output" = "Value is default" ]
}

# Test: Condition checking
@test "tui_check_condition returns true for non-empty string" {
    export CONDITION_VAR="true"
    run tui_check_condition "\$CONDITION_VAR"
    [ "$status" -eq 0 ]
}

@test "tui_check_condition returns false for empty string" {
    export CONDITION_VAR=""
    run tui_check_condition "\$CONDITION_VAR"
    [ "$status" -eq 1 ]
}

@test "tui_check_condition returns false for false value" {
    export CONDITION_VAR="false"
    run tui_check_condition "\$CONDITION_VAR"
    [ "$status" -eq 1 ]
}

@test "tui_check_condition returns false for 0 value" {
    export CONDITION_VAR="0"
    run tui_check_condition "\$CONDITION_VAR"
    [ "$status" -eq 1 ]
}

@test "tui_check_condition returns true for empty condition" {
    run tui_check_condition ""
    [ "$status" -eq 0 ]
}

# Test: YAML configuration loading
@test "tui_load_config fails for non-existent file" {
    run tui_load_config "$TEST_DIR/nonexistent.yaml"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "tui_load_config loads valid YAML file" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    # Create a simple test YAML
    cat > "$TEST_DIR/test.yaml" <<EOF
header:
  title: "Test Title"
menu:
  - key: "1"
    label: "Option 1"
EOF

    run tui_load_config "$TEST_DIR/test.yaml"
    [ "$status" -eq 0 ]
}

# Tests removed: tui_query and tui_query_length no longer exist
# Config data is now stored in bash arrays after loading

# Test: Terminal control functions
@test "tui_clear_screen outputs ANSI escape sequence" {
    run tui_clear_screen
    [ "$status" -eq 0 ]
    # Check for clear screen sequence
    [[ "$output" =~ $'\033' ]]
}

@test "tui_hide_cursor outputs ANSI escape sequence" {
    run tui_hide_cursor
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033' ]]
}

@test "tui_show_cursor outputs ANSI escape sequence" {
    run tui_show_cursor
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033' ]]
}

# Test: Callback finding
@test "tui_find_menu_callback returns callback for valid key" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    cat > "$TEST_DIR/test.yaml" <<EOF
menu:
  - key: "1"
    label: "Option 1"
    callback: "/path/to/script.sh"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_find_menu_callback "1"
    [ "$status" -eq 0 ]
    [ "$output" = "/path/to/script.sh" ]
}

@test "tui_find_menu_callback fails for invalid key" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    cat > "$TEST_DIR/test.yaml" <<EOF
menu:
  - key: "1"
    label: "Option 1"
    callback: "/path/to/script.sh"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_find_menu_callback "9"
    [ "$status" -eq 1 ]
}

@test "tui_find_footer_callback returns callback for valid key" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    cat > "$TEST_DIR/test.yaml" <<EOF
footer:
  - key: "R"
    label: "reboot"
    callback: "/path/to/reboot.sh"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_find_footer_callback "R"
    [ "$status" -eq 0 ]
    [ "$output" = "/path/to/reboot.sh" ]
}

# Test: Callback execution
@test "tui_execute_callback fails for non-existent script" {
    run tui_execute_callback "$TEST_DIR/nonexistent.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "tui_execute_callback fails for non-executable script" {
    touch "$TEST_DIR/not_executable.sh"
    run tui_execute_callback "$TEST_DIR/not_executable.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not executable"* ]]
}

@test "tui_execute_callback runs executable script" {
    # Create executable test script
    cat > "$TEST_DIR/test_callback.sh" <<'EOF'
#!/bin/bash
echo "callback executed"
exit 0
EOF
    chmod +x "$TEST_DIR/test_callback.sh"

    # Mock tui_read_key to avoid waiting for input
    tui_read_key() { echo ""; }
    export -f tui_read_key

    run tui_execute_callback "$TEST_DIR/test_callback.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"callback executed"* ]]
}

# Test: Header rendering
@test "tui_render_header outputs header content" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    cat > "$TEST_DIR/test.yaml" <<EOF
header:
  title: "Test Application"
  subtitle: "Version 1.0"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_render_header
    [ "$status" -eq 0 ]
    [[ "$output" == *"Test Application"* ]]
    [[ "$output" == *"Version 1.0"* ]]
}

# Test: Information sections rendering
@test "tui_render_info_sections renders sections with entries" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    cat > "$TEST_DIR/test.yaml" <<EOF
sections:
  - label: "SYSTEM INFO"
    entries:
      - label: "OS"
        value: "Linux"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_render_info_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"SYSTEM INFO"* ]]
    [[ "$output" == *"OS"* ]]
    [[ "$output" == *"Linux"* ]]
}

# Test: Menu rendering
@test "tui_render_menu renders menu options" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    cat > "$TEST_DIR/test.yaml" <<EOF
menu:
  - key: "1"
    label: "First Option"
  - key: "2"
    label: "Second Option"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_render_menu
    [ "$status" -eq 0 ]
    [[ "$output" == *"1)"* ]]
    [[ "$output" == *"First Option"* ]]
    [[ "$output" == *"2)"* ]]
    [[ "$output" == *"Second Option"* ]]
}

# Test: Footer rendering
@test "tui_render_footer renders footer actions" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    cat > "$TEST_DIR/test.yaml" <<EOF
footer:
  - key: "Q"
    label: "quit"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_render_footer
    [ "$status" -eq 0 ]
    [[ "$output" == *"Q to quit"* ]]
}

# Test: Conditional rendering
@test "tui_render_info_sections skips section when condition is false" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    export SHOW_SECTION=""
    cat > "$TEST_DIR/test.yaml" <<EOF
sections:
  - label: "HIDDEN SECTION"
    condition: "\$SHOW_SECTION"
    entries:
      - label: "Hidden"
        value: "Value"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_render_info_sections
    [ "$status" -eq 0 ]
    [[ "$output" != *"HIDDEN SECTION"* ]]
}

@test "tui_render_info_sections shows section when condition is true" {
    # Skip if yq is not installed
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    export SHOW_SECTION="1"
    cat > "$TEST_DIR/test.yaml" <<EOF
sections:
  - label: "VISIBLE SECTION"
    condition: "\$SHOW_SECTION"
    entries:
      - label: "Visible"
        value: "Value"
EOF

    tui_load_config "$TEST_DIR/test.yaml"
    run tui_render_info_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"VISIBLE SECTION"* ]]
}
