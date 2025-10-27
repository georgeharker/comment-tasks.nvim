-- Tests for generalized status system

local M = {}

function M.run_tests(test_framework)
    local assert = test_framework.assert_true
    local assert_equal = test_framework.assert_equal
    local assert_not_nil = test_framework.assert_not_nil
    local assert_contains = test_framework.assert_contains

    print("Testing generalized status system...")

    -- Load config module
    local config = require("comment-tasks.core.config")

    -- Test basic status resolution
    local basic_status_tests = {
        -- ClickUp
        {provider = "clickup", status = "new", expected = "to do"},
        {provider = "clickup", status = "completed", expected = "complete"},
        {provider = "clickup", status = "review", expected = "review"},
        {provider = "clickup", status = "in_progress", expected = "in progress"},
        
        -- Asana
        {provider = "asana", status = "new", expected = "Not Started"},
        {provider = "asana", status = "completed", expected = "Complete"},
        {provider = "asana", status = "review", expected = "Review"},
        {provider = "asana", status = "in_progress", expected = "In Progress"},
        
        -- Linear
        {provider = "linear", status = "new", expected = "Todo"},
        {provider = "linear", status = "completed", expected = "Done"},
        {provider = "linear", status = "review", expected = "In Review"},
        {provider = "linear", status = "in_progress", expected = "In Progress"},
        
        -- Jira
        {provider = "jira", status = "new", expected = "To Do"},
        {provider = "jira", status = "completed", expected = "Done"},
        {provider = "jira", status = "review", expected = "In Review"},
        {provider = "jira", status = "in_progress", expected = "In Progress"},
        
        -- Notion
        {provider = "notion", status = "new", expected = "Not started"},
        {provider = "notion", status = "completed", expected = "Done"},
        {provider = "notion", status = "review", expected = "In review"},
        {provider = "notion", status = "in_progress", expected = "In progress"},
        
        -- Monday.com
        {provider = "monday", status = "new", expected = "Not Started"},
        {provider = "monday", status = "completed", expected = "Done"},
        {provider = "monday", status = "review", expected = "Review"},
        {provider = "monday", status = "in_progress", expected = "Working on it"}
    }

    for _, test in ipairs(basic_status_tests) do
        local resolved_status = config.get_provider_status(test.provider, test.status)
        assert_equal(resolved_status, test.expected,
                    string.format("Provider %s should resolve '%s' to '%s', got '%s'", 
                                  test.provider, test.status, test.expected, resolved_status))
    end

    -- Test fallback behavior
    local fallback_tests = {
        {provider = "clickup", status = "unknown", expected = "unknown"},
        {provider = "nonexistent", status = "new", expected = "new"},
        {provider = "asana", status = "custom_status", expected = "custom_status"}
    }

    for _, test in ipairs(fallback_tests) do
        local resolved_status = config.get_provider_status(test.provider, test.status)
        assert_equal(resolved_status, test.expected,
                    string.format("Provider %s should fallback '%s' to '%s'", 
                                  test.provider, test.status, test.expected))
    end

    -- Test get_fallback_status function
    local direct_fallback_tests = {
        {provider = "clickup", status = "new", expected = "to do"},
        {provider = "asana", status = "completed", expected = "Complete"},
        {provider = "linear", status = "review", expected = "In Review"},
        {provider = "unknown_provider", status = "anything", expected = "anything"}
    }

    for _, test in ipairs(direct_fallback_tests) do
        local fallback_status = config.get_fallback_status(test.provider, test.status)
        assert_equal(fallback_status, test.expected,
                    string.format("Fallback for %s '%s' should be '%s'", 
                                  test.provider, test.status, test.expected))
    end

    -- Test available statuses
    local available_statuses = config.get_provider_available_statuses("clickup")
    assert_not_nil(available_statuses, "Should return available statuses")
    assert_contains(available_statuses, "new", "Should contain 'new' status")
    assert_contains(available_statuses, "completed", "Should contain 'completed' status")

    -- Test legacy compatibility
    local legacy_clickup_status = config.get_clickup_status("new")
    local generic_clickup_status = config.get_provider_status("clickup", "new")
    assert_equal(legacy_clickup_status, generic_clickup_status, 
                "Legacy function should match new generic function")

    -- Test legacy available statuses
    local legacy_available = config.get_clickup_available_statuses()
    local generic_available = config.get_provider_available_statuses("clickup")
    assert_equal(#legacy_available, #generic_available, 
                "Legacy and generic available statuses should match")

    print("✓ Generalized status system tests completed")
end

return M