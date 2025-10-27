-- Test runner for comment-tasks plugin

local M = {}

local test_detection = require("comment-tasks.tests.test_detection")
local test_providers = require("comment-tasks.tests.test_providers")
local test_config = require("comment-tasks.tests.test_config")
local test_integration = require("comment-tasks.tests.test_integration")

-- Import new provider tests
local test_asana_provider = require("comment-tasks.tests.test_asana_provider")
local test_linear_provider = require("comment-tasks.tests.test_linear_provider")
local test_jira_provider = require("comment-tasks.tests.test_jira_provider")
local test_notion_provider = require("comment-tasks.tests.test_notion_provider")
local test_status_system = require("comment-tasks.tests.test_status_system")

-- Test results tracking
local results = {
    passed = 0,
    failed = 0,
    tests = {}
}

-- Test utility functions
function M.assert_equal(actual, expected, message)
    if actual == expected then
        results.passed = results.passed + 1
        table.insert(results.tests, {
            status = "PASS",
            message = message or "Values are equal",
            actual = actual,
            expected = expected
        })
        return true
    else
        results.failed = results.failed + 1
        table.insert(results.tests, {
            status = "FAIL",
            message = message or "Values are not equal",
            actual = actual,
            expected = expected
        })
        return false
    end
end

function M.assert_not_nil(value, message)
    return M.assert_equal(value ~= nil, true, message or "Value should not be nil")
end

function M.assert_nil(value, message)
    return M.assert_equal(value, nil, message or "Value should be nil")
end

function M.assert_true(value, message)
    return M.assert_equal(value, true, message or "Value should be true")
end

function M.assert_false(value, message)
    return M.assert_equal(value, false, message or "Value should be false")
end

function M.assert_contains(haystack, needle, message)
    local found = false
    if type(haystack) == "string" then
        found = haystack:find(needle, 1, true) ~= nil
    elseif type(haystack) == "table" then
        for _, v in ipairs(haystack) do
            if v == needle then
                found = true
                break
            end
        end
    end
    return M.assert_true(found, message or ("Should contain: " .. tostring(needle)))
end

-- Test runner functions
function M.run_test_suite(name, test_function)
    print("\n=== " .. name .. " ===")
    local start_passed = results.passed
    local start_failed = results.failed

    local ok, error = pcall(test_function, M)

    if not ok then
        results.failed = results.failed + 1
        table.insert(results.tests, {
            status = "ERROR",
            message = "Test suite crashed: " .. tostring(error),
            suite = name
        })
    end

    local suite_passed = results.passed - start_passed
    local suite_failed = results.failed - start_failed

    print(string.format("Suite %s: %d passed, %d failed", name, suite_passed, suite_failed))
end

function M.run_all()
    print("Running Comment Tasks Test Suite")
    print("================================")

    -- Reset results
    results = { passed = 0, failed = 0, tests = {} }

    -- Run all test suites
    M.run_test_suite("Configuration Tests", test_config.run_tests)
    M.run_test_suite("Detection Tests", test_detection.run_tests)
    M.run_test_suite("Provider Tests", test_providers.run_tests)
    M.run_test_suite("Integration Tests", test_integration.run_tests)
    
    -- Run new provider tests
    M.run_test_suite("Status System Tests", test_status_system.run_tests)
    M.run_test_suite("Asana Provider Tests", test_asana_provider.run_tests)
    M.run_test_suite("Linear Provider Tests", test_linear_provider.run_tests)
    M.run_test_suite("Jira Provider Tests", test_jira_provider.run_tests)
    M.run_test_suite("Notion Provider Tests", test_notion_provider.run_tests)

    -- Print final results
    print("\n" .. string.rep("=", 50))
    print(string.format("FINAL RESULTS: %d passed, %d failed", results.passed, results.failed))

    if results.failed > 0 then
        print("\nFAILED TESTS:")
        for _, test in ipairs(results.tests) do
            if test.status == "FAIL" or test.status == "ERROR" then
                print(string.format("  ✗ %s", test.message))
                if test.actual and test.expected then
                    print(string.format("    Expected: %s", tostring(test.expected)))
                    print(string.format("    Actual:   %s", tostring(test.actual)))
                end
            end
        end
    end

    return results.failed == 0
end

return M
