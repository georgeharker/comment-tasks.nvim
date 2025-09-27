#!/bin/bash

# Test runner script for comment-tasks.nvim
# Runs all plenary tests with comprehensive reporting

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Running comment-tasks.nvim Test Suite${NC}"
echo "=================================================="

# Function to run tests and show results
run_tests() {
    local test_path="$1"
    local description="$2"
    
    echo -e "\n${YELLOW}Testing: $description${NC}"
    echo "Path: $test_path"
    
    if nvim --headless -c "PlenaryBustedFile $test_path" -c "qa!" 2>/dev/null; then
        echo -e "${GREEN}✅ PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
}

run_directory_tests() {
    local test_dir="$1"
    local description="$2"
    
    echo -e "\n${YELLOW}Testing: $description${NC}"
    echo "Directory: $test_dir"
    
    if nvim --headless -c "PlenaryBustedDirectory $test_dir" -c "qa!" 2>/dev/null; then
        echo -e "${GREEN}✅ PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
}

# Track results
passed=0
failed=0

# Run all test suites
echo -e "\n${BLUE}=== Core Plugin Tests ===${NC}"

if run_directory_tests "." "Top-level Integration Tests"; then
    ((passed++))
else
    ((failed++))
fi

echo -e "\n${BLUE}=== Internal Module Tests ===${NC}"

if run_tests "../lua/comment-tasks/tests/test_config.lua" "Configuration Management"; then
    ((passed++))
else
    ((failed++))
fi

if run_tests "../lua/comment-tasks/tests/test_detection.lua" "Detection & URL Utilities"; then
    ((passed++))
else
    ((failed++))
fi

if run_tests "../lua/comment-tasks/tests/test_providers.lua" "Provider Functionality"; then
    ((passed++))
else
    ((failed++))
fi

if run_tests "../lua/comment-tasks/tests/test_integration.lua" "Cross-module Integration"; then
    ((passed++))
else
    ((failed++))
fi

if run_tests "../lua/comment-tasks/tests/test_neovim_integration.lua" "Neovim Integration"; then
    ((passed++))
else
    ((failed++))
fi

echo -e "\n${BLUE}=== Language Detection Tests ===${NC}"

if run_tests "../lua/comment-tasks/tests/detection_languages_spec.lua" "Multi-language Detection"; then
    ((passed++))
else
    ((failed++))
fi

# Final summary
total=$((passed + failed))
echo -e "\n${BLUE}=================================================="
echo -e "📊 Test Results Summary${NC}"
echo "=================================================="

if [ "$failed" -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TEST SUITES PASSED!${NC}"
    echo -e "${GREEN}✅ $passed/$total test suites passing (100%)${NC}"
    echo ""
    echo -e "${GREEN}Ready for production! 🚀${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some test suites failed${NC}"
    echo -e "${GREEN}✅ Passed: $passed${NC}"
    echo -e "${RED}❌ Failed: $failed${NC}"
    echo -e "📊 Total: $passed/$total test suites passing ($(( passed * 100 / total ))%)"
    echo ""
    echo -e "${YELLOW}Please check failed tests above${NC}"
    exit 1
fi