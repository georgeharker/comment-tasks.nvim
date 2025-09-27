#!/bin/bash

# Comprehensive Test Runner for comment-tasks.nvim
# This script runs all converted plenary tests and provides a comprehensive test report

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_ERRORS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🧪 comment-tasks.nvim Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to run a test file and extract results
run_test() {
    local test_file="$1"
    local test_name="$2"
    
    echo -e "${BLUE}Testing: ${test_name}${NC}"
    echo "File: $test_file"
    
    # Run the test and capture output
    local output
    if output=$(nvim --headless -c "PlenaryBustedFile $test_file" -c "qa!" 2>&1); then
        # Extract results from output
        local success=$(echo "$output" | grep -o "Success: [0-9]*" | grep -o "[0-9]*" || echo "0")
        local failed=$(echo "$output" | grep -o "Failed : [0-9]*" | grep -o "[0-9]*" || echo "0")
        local errors=$(echo "$output" | grep -o "Errors : [0-9]*" | grep -o "[0-9]*" || echo "0")
        
        # Update counters
        TOTAL_TESTS=$((TOTAL_TESTS + success + failed + errors))
        TOTAL_PASSED=$((TOTAL_PASSED + success))
        TOTAL_FAILED=$((TOTAL_FAILED + failed))
        TOTAL_ERRORS=$((TOTAL_ERRORS + errors))
        
        if [ "$failed" -eq 0 ] && [ "$errors" -eq 0 ]; then
            echo -e "${GREEN}✅ PASSED: $success tests${NC}"
        else
            echo -e "${RED}❌ FAILED: $failed failed, $errors errors, $success passed${NC}"
            # Show failure details
            echo "$output" | grep -A 5 -B 5 "Fail\|Error" || true
        fi
    else
        echo -e "${RED}❌ ERROR: Test file failed to run${NC}"
        echo "$output"
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
    
    echo ""
}

# Function to run directory tests
run_directory_tests() {
    local test_dir="$1"
    local test_name="$2"
    
    echo -e "${BLUE}Testing: ${test_name}${NC}"
    echo "Directory: $test_dir"
    
    # Run the test and capture output
    local output
    if output=$(nvim --headless -c "PlenaryBustedDirectory $test_dir" -c "qa!" 2>&1); then
        # Extract results from output - directory tests show results per file
        local total_success=$(echo "$output" | grep -o "Success: [0-9]*" | grep -o "[0-9]*" | awk '{sum += $1} END {print sum+0}')
        local total_failed=$(echo "$output" | grep -o "Failed : [0-9]*" | grep -o "[0-9]*" | awk '{sum += $1} END {print sum+0}')
        local total_errors=$(echo "$output" | grep -o "Errors : [0-9]*" | grep -o "[0-9]*" | awk '{sum += $1} END {print sum+0}')
        
        # Update counters
        TOTAL_TESTS=$((TOTAL_TESTS + total_success + total_failed + total_errors))
        TOTAL_PASSED=$((TOTAL_PASSED + total_success))
        TOTAL_FAILED=$((TOTAL_FAILED + total_failed))
        TOTAL_ERRORS=$((TOTAL_ERRORS + total_errors))
        
        if [ "$total_failed" -eq 0 ] && [ "$total_errors" -eq 0 ]; then
            echo -e "${GREEN}✅ PASSED: $total_success tests${NC}"
        else
            echo -e "${RED}❌ FAILED: $total_failed failed, $total_errors errors, $total_success passed${NC}"
        fi
    else
        echo -e "${RED}❌ ERROR: Directory tests failed to run${NC}"
        echo "$output"
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
    
    echo ""
}

# 1. Top-level integration tests
echo -e "${YELLOW}📁 Top-level Integration Tests${NC}"
run_directory_tests "tests/" "Plugin Initialization & Detection System"

# 2. Internal module tests
echo -e "${YELLOW}🔧 Internal Module Tests${NC}"

run_test "lua/comment-tasks/tests/test_config.lua" "Configuration Management"
run_test "lua/comment-tasks/tests/test_detection.lua" "Enhanced Detection & URL Utilities"  
run_test "lua/comment-tasks/tests/test_providers.lua" "Provider Functionality"
run_test "lua/comment-tasks/tests/test_integration.lua" "Cross-module Integration"
run_test "lua/comment-tasks/tests/test_neovim_integration.lua" "Neovim-specific Integration"

# 3. Language-specific detection tests
echo -e "${YELLOW}🌐 Language-specific Detection Tests${NC}"
run_test "lua/comment-tasks/tests/detection_languages_spec.lua" "Multi-language Comment Detection"

# Final report
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo -e "${BLUE}========================================${NC}"

if [ "$TOTAL_FAILED" -eq 0 ] && [ "$TOTAL_ERRORS" -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}✅ Total: $TOTAL_PASSED/$TOTAL_TESTS tests passing (100%)${NC}"
    exit_code=0
else
    echo -e "${RED}⚠️  SOME TESTS FAILED${NC}"
    echo -e "${GREEN}✅ Passed: $TOTAL_PASSED${NC}"
    echo -e "${RED}❌ Failed: $TOTAL_FAILED${NC}"
    echo -e "${RED}💥 Errors: $TOTAL_ERRORS${NC}"
    echo -e "📊 Total: $TOTAL_PASSED/$TOTAL_TESTS tests passing ($(( TOTAL_PASSED * 100 / TOTAL_TESTS ))%)"
    exit_code=1
fi

echo ""
echo -e "${BLUE}Test Categories Covered:${NC}"
echo "• Plugin initialization and setup"
echo "• Comment detection system" 
echo "• Configuration management"
echo "• Provider functionality"
echo "• URL detection and extraction"
echo "• Cross-module integration"
echo "• Neovim-specific features"
echo "• Multi-language comment parsing (20 languages)"
echo ""

if [ "$exit_code" -eq 0 ]; then
    echo -e "${GREEN}🚀 Ready for production!${NC}"
else
    echo -e "${YELLOW}🔧 Some issues need attention${NC}"
fi

exit $exit_code