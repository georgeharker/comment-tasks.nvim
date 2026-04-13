#!/bin/bash

# Comprehensive Test Runner for comment-tasks.nvim
# Uses vusted (https://github.com/notomo/vusted) to run busted specs.
# Install: luarocks --lua-version=5.1 install vusted

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

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_PASSED=0
TOTAL_FAILED=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}comment-tasks.nvim Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Run a set of spec files via vusted and accumulate TAP counters.
# Usage: run_specs <label> <spec_file_or_dir...>
run_specs() {
    local label="$1"
    shift

    echo -e "${BLUE}Testing: ${label}${NC}"

    local output exit_ok=0
    output=$("$VUSTED" "$@" 2>&1) || exit_ok=1

    # TAP output: "ok N - description" / "not ok N - description"
    local passed failed
    passed=$(echo "$output" | grep -c "^ok " || true)
    failed=$(echo "$output" | grep -c "^not ok " || true)

    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))

    if [ "$exit_ok" -eq 0 ]; then
        echo -e "${GREEN}PASSED: ${passed} tests${NC}"
    else
        # exit_ok=1 means either vusted run error or test failures.
        if [ "$failed" -gt 0 ]; then
            echo -e "${RED}FAILED: ${failed} failed, ${passed} passed${NC}"
            echo "$output" | grep "^not ok " || true
        else
            # No TAP output at all — runner error (bad path, load error, etc.)
            echo -e "${RED}ERROR: suite did not run${NC}"
            echo "$output"
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
    fi

    echo ""
}

# 1. Top-level integration tests
echo -e "${YELLOW}Top-level Integration Tests${NC}"
run_specs "Plugin Initialization & Detection System" \
    tests/init_spec.lua \
    tests/detection_spec.lua

# 2. Internal module tests
echo -e "${YELLOW}Internal Module Tests${NC}"

run_specs "Configuration Management" \
    lua/comment-tasks/tests/test_config.lua

run_specs "Enhanced Detection & URL Utilities" \
    lua/comment-tasks/tests/test_detection.lua

run_specs "Provider Functionality" \
    lua/comment-tasks/tests/test_providers.lua

run_specs "Cross-module Integration" \
    lua/comment-tasks/tests/test_integration.lua

run_specs "Neovim-specific Integration" \
    lua/comment-tasks/tests/test_neovim_integration.lua

run_specs "Project Root Detection" \
    lua/comment-tasks/tests/test_project.lua

# 3. Language-specific detection tests
echo -e "${YELLOW}Language-specific Detection Tests${NC}"
run_specs "Multi-language Comment Detection" \
    lua/comment-tasks/tests/detection_languages_spec.lua

# Final report
TOTAL_TESTS=$((TOTAL_PASSED + TOTAL_FAILED))

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Results Summary${NC}"
echo -e "${BLUE}========================================${NC}"

if [ "$TOTAL_FAILED" -eq 0 ] && [ "$TOTAL_TESTS" -gt 0 ]; then
    echo -e "${GREEN}ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}Total: ${TOTAL_PASSED}/${TOTAL_TESTS} tests passing (100%)${NC}"
    exit_code=0
else
    echo -e "${RED}SOME TESTS FAILED${NC}"
    echo -e "${GREEN}Passed: ${TOTAL_PASSED}${NC}"
    echo -e "${RED}Failed: ${TOTAL_FAILED}${NC}"
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        echo -e "Total: ${TOTAL_PASSED}/${TOTAL_TESTS} tests passing ($(( TOTAL_PASSED * 100 / TOTAL_TESTS ))%)"
    fi
    exit_code=1
fi

echo ""
echo -e "${BLUE}Test Categories Covered:${NC}"
echo "  Plugin initialization and setup"
echo "  Comment detection system"
echo "  Configuration management"
echo "  Provider functionality"
echo "  URL detection and extraction"
echo "  Cross-module integration"
echo "  Neovim-specific features"
echo "  Multi-language comment parsing (20 languages)"
echo ""

exit $exit_code
