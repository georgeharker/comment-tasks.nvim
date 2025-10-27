-- Tests for Linear provider

local M = {}

-- Test Linear provider functionality
function M.run_tests(test_framework)
    local assert = test_framework.assert_true
    local assert_equal = test_framework.assert_equal
    local assert_not_nil = test_framework.assert_not_nil
    local assert_nil = test_framework.assert_nil

    print("Testing Linear provider...")

    -- Load provider
    local linear_provider = require("comment-tasks.providers.linear")
    local interface = require("comment-tasks.providers.interface")

    -- Test provider registration
    local provider_class = interface.get_provider_class("linear")
    assert_not_nil(provider_class, "Linear provider should be registered")
    assert_equal(provider_class, linear_provider, "Should return correct provider class")

    -- Test provider creation
    local config = {
        enabled = true,
        api_key_env = "LINEAR_API_KEY",
        team_id = "test-team-id"
    }
    local provider = linear_provider:new(config)
    assert_not_nil(provider, "Should create Linear provider instance")
    assert_equal(provider.config.team_id, "test-team-id", "Should set team_id")

    -- Test URL matching
    local valid_urls = {
        "https://linear.app/team/issue/ABC-123/issue-title",
        "https://linear.app/myteam/issue/DEF-456/another-issue"
    }
    
    for _, url in ipairs(valid_urls) do
        assert(provider:matches_url(url), "Should match Linear URL: " .. url)
        local issue_id = provider:extract_task_identifier(url)
        assert_not_nil(issue_id, "Should extract issue ID from: " .. url)
    end

    -- Test invalid URLs
    local invalid_urls = {
        "https://github.com/user/repo/issues/123",
        "https://app.clickup.com/t/abc123",
        "https://not-linear.com/team/issue/ABC-123"
    }
    
    for _, url in ipairs(invalid_urls) do
        assert_equal(provider:matches_url(url), false, "Should not match non-Linear URL: " .. url)
    end

    -- Test URL pattern
    local url_pattern = provider:get_url_pattern()
    assert_not_nil(url_pattern, "Should return URL pattern")
    
    -- Test status mapping
    local status_tests = {
        {status = "complete", expected_contains = "Done"},
        {status = "completed", expected_contains = "Done"},
        {status = "new", expected_contains = "Todo"},
        {status = "in_progress", expected_contains = "Progress"}
    }

    for _, test in ipairs(status_tests) do
        local mapped_status = provider:map_status_to_linear(test.status)
        assert_not_nil(mapped_status, "Should map status: " .. test.status)
    end

    -- Test interface compliance
    local required_methods = {
        "create_task",
        "update_task_status", 
        "add_file_to_task",
        "extract_task_identifier",
        "matches_url",
        "get_url_pattern",
        "is_enabled"
    }
    
    for _, method_name in ipairs(required_methods) do
        assert_equal(type(provider[method_name]), "function", 
                     "Should implement method: " .. method_name)
    end

    print("✓ Linear provider tests completed")
end

return M