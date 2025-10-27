-- Tests for Notion provider

local M = {}

function M.run_tests(test_framework)
    local assert = test_framework.assert_true
    local assert_equal = test_framework.assert_equal
    local assert_not_nil = test_framework.assert_not_nil
    local assert_false = test_framework.assert_false

    print("Testing Notion provider...")

    -- Load provider
    local notion_provider = require("comment-tasks.providers.notion")
    local interface = require("comment-tasks.providers.interface")

    -- Test provider registration
    local provider_class = interface.get_provider_class("notion")
    assert_not_nil(provider_class, "Notion provider should be registered")

    -- Test provider creation
    local config = {
        enabled = true,
        api_key_env = "NOTION_API_KEY",
        database_id = "test_database_id"
    }
    local provider = notion_provider:new(config)
    assert_not_nil(provider, "Should create Notion provider instance")
    assert_equal(provider.config.database_id, "test_database_id", "Should set database_id")

    -- Test URL matching
    local valid_urls = {
        "https://notion.so/workspace/abc123def456789012345678901234ab",
        "https://www.notion.so/abc123def456789012345678901234ab", 
        "https://notion.so/abc123def456789012345678901234ab"
    }
    
    for _, url in ipairs(valid_urls) do
        assert(provider:matches_url(url), "Should match Notion URL: " .. url)
    end

    -- Test page ID extraction
    local test_cases = {
        {
            url = "https://notion.so/workspace/abc123def456789012345678901234ab",
            expected_id = "abc123def456789012345678901234ab"
        },
        {
            url = "https://www.notion.so/abc123def456789012345678901234ab",
            expected_id = "abc123def456789012345678901234ab"
        }
    }
    
    for _, case in ipairs(test_cases) do
        local page_id = provider:extract_task_identifier(case.url)
        assert_equal(page_id, case.expected_id, 
                    "Should extract correct page ID from: " .. case.url)
    end

    -- Test invalid URLs
    local invalid_urls = {
        "https://github.com/user/repo/issues/123",
        "https://linear.app/team/issue/ABC-123",
        "https://not-notion.com/workspace/abc123"
    }
    
    for _, url in ipairs(invalid_urls) do
        assert_false(provider:matches_url(url), "Should not match non-Notion URL: " .. url)
    end

    -- Test configuration validation
    local enabled, error_msg = provider:is_enabled()
    -- This will fail without actual API key, but should check config structure
    assert_not_nil(error_msg, "Should require API key for enabling")

    -- Test with missing database_id
    local incomplete_provider = notion_provider:new({
        enabled = true,
        api_key_env = "NOTION_API_KEY"
        -- Missing database_id
    })
    local enabled2, error_msg2 = incomplete_provider:is_enabled()
    assert_false(enabled2, "Should fail without database_id")
    assert_not_nil(error_msg2, "Should provide error message about database_id")

    -- Test URL pattern
    local url_pattern = provider:get_url_pattern()
    assert_not_nil(url_pattern, "Should return URL pattern")

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

    print("✓ Notion provider tests completed")
end

return M