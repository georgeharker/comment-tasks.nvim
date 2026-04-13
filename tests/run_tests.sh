#!/bin/bash

# Test runner for comment-tasks.nvim
# Uses vusted (https://github.com/notomo/vusted) to run busted specs.
# Install: luarocks --lua-version=5.1 install vusted
#
# Run from the tests/ directory or the project root.

# Resolve project root (parent of this script's directory).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Resolve vusted binary — check PATH then common local-install locations.
if command -v vusted &>/dev/null; then
    VUSTED=vusted
elif [ -x "$HOME/.luarocks/bin/vusted" ]; then
    VUSTED="$HOME/.luarocks/bin/vusted"
elif [ -x "$HOME/.local/share/luarocks/bin/vusted" ]; then
    VUSTED="$HOME/.local/share/luarocks/bin/vusted"
else
    echo "vusted not found."
    echo "Install with: luarocks --lua-version=5.1 install vusted"
    exit 1
fi

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Running comment-tasks.nvim Test Suite${NC}"
echo "=================================================="

passed=0
failed=0

# Run spec files and track pass/fail by suite.
run_suite() {
    local description="$1"
    shift

    echo -e "\n${YELLOW}Testing: $description${NC}"

    local output exit_ok=0
    output=$("$VUSTED" "$@" 2>&1) || exit_ok=1

    local p f
    p=$(echo "$output" | grep -c "^ok " || true)
    f=$(echo "$output" | grep -c "^not ok " || true)

    if [ "$exit_ok" -eq 0 ]; then
        echo -e "${GREEN}PASSED (${p} tests)${NC}"
        passed=$((passed + 1))
    else
        if [ "$f" -gt 0 ]; then
            echo -e "${RED}FAILED (${f} failed, ${p} passed)${NC}"
            echo "$output" | grep "^not ok " || true
        else
            echo -e "${RED}ERROR: suite did not run${NC}"
            echo "$output"
        fi
        failed=$((failed + 1))
    fi
}

cd "$PROJECT_ROOT"

echo -e "\n${BLUE}=== Core Plugin Tests ===${NC}"
run_suite "Top-level Integration Tests" \
    tests/init_spec.lua \
    tests/detection_spec.lua

echo -e "\n${BLUE}=== Internal Module Tests ===${NC}"

run_suite "Configuration Management" \
    lua/comment-tasks/tests/test_config.lua

run_suite "Detection & URL Utilities" \
    lua/comment-tasks/tests/test_detection.lua

run_suite "Provider Functionality" \
    lua/comment-tasks/tests/test_providers.lua

run_suite "Cross-module Integration" \
    lua/comment-tasks/tests/test_integration.lua

run_suite "Neovim Integration" \
    lua/comment-tasks/tests/test_neovim_integration.lua

echo -e "\n${BLUE}=== Language Detection Tests ===${NC}"
run_suite "Multi-language Detection" \
    lua/comment-tasks/tests/detection_languages_spec.lua

# Summary
total=$((passed + failed))
echo -e "\n${BLUE}=================================================="
echo -e "Test Results Summary${NC}"
echo "=================================================="

if [ "$failed" -eq 0 ] && [ "$total" -gt 0 ]; then
    echo -e "${GREEN}ALL TEST SUITES PASSED!${NC}"
    echo -e "${GREEN}${passed}/${total} suites passing (100%)${NC}"
    exit 0
else
    echo -e "${RED}Some test suites failed${NC}"
    echo -e "${GREEN}Passed: ${passed}${NC}"
    echo -e "${RED}Failed: ${failed}${NC}"
    echo -e "Total: ${passed}/${total} suites passing"
    exit 1
fi
