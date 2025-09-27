-- Detection test runner for all language comment styles

local M = {}

-- Import all language-specific test modules
local test_modules = {
    require("comment-tasks.tests.detection.test_lua"),
    require("comment-tasks.tests.detection.test_python"),
    require("comment-tasks.tests.detection.test_javascript"),
    require("comment-tasks.tests.detection.test_typescript"),
    require("comment-tasks.tests.detection.test_rust"),
    require("comment-tasks.tests.detection.test_c_cpp"),
    require("comment-tasks.tests.detection.test_go"),
    require("comment-tasks.tests.detection.test_java"),
    require("comment-tasks.tests.detection.test_ruby"),
    require("comment-tasks.tests.detection.test_php"),
    require("comment-tasks.tests.detection.test_css"),
    require("comment-tasks.tests.detection.test_html"),
    require("comment-tasks.tests.detection.test_shell"),
    require("comment-tasks.tests.detection.test_vim"),
    require("comment-tasks.tests.detection.test_yaml"),
    require("comment-tasks.tests.detection.test_json"),
}

-- Test runner function
function M.run_tests(assert)
    print("\n=== Language-Specific Detection Tests ===")
    
    local total_passed = 0
    local total_failed = 0
    
    for _, test_module in ipairs(test_modules) do
        local module_name = test_module.language or "Unknown"
        print("\n--- Testing " .. module_name .. " ---")
        
        local start_passed = assert.passed or 0
        local start_failed = assert.failed or 0
        
        -- Run the language-specific tests
        test_module.run_tests(assert)
        
        local module_passed = (assert.passed or 0) - start_passed
        local module_failed = (assert.failed or 0) - start_failed
        
        total_passed = total_passed + module_passed
        total_failed = total_failed + module_failed
        
        print(string.format("%s: %d passed, %d failed", module_name, module_passed, module_failed))
    end
    
    print(string.format("\n=== Detection Tests Complete: %d passed, %d failed ===", total_passed, total_failed))
    
    return total_failed == 0
end

return M