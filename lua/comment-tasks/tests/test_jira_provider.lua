-- Tests for Jira provider

local M = {}

function M.run_tests(test_framework)
    local assert = test_framework.assert_true
    local assert_equal = test_framework.assert_equal
    local assert_not_nil = test_framework.assert_not_nil
    local assert_false = test_framework.assert_false

    print("Testing Jira provider...")

    -- Load provider
    local jira_provider = require("comment-tasks.providers.jira")
    local interface = require("comment-tasks.providers.interface")

    -- Test provider registration
    local provider_class = interface.get_provider_class("jira")
    assert_not_nil(provider_class, "Jira provider should be registered")

    -- Test provider creation
    local config = {
        enabled = true,
        api_key_env = "JIRA_API_TOKEN",
        server_url = "https://company.atlassian.net",
        project_key = "PROJ"
    }
    local provider = jira_provider:new(config)
    assert_not_nil(provider, "Should create Jira provider instance")
    assert_equal(provider.config.project_key, "PROJ", "Should set project_key")

    -- Test base URL generation
    local base_url = provider:get_base_url()
    assert_equal(base_url, "https://company.atlassian.net/rest/api/3", "Should generate correct base URL")

    -- Test URL matching
    local valid_urls = {
        "https://company.atlassian.net/browse/PROJ-123",
        "https://myorg.atlassian.net/browse/ABC-456"
    }
    
    for _, url in ipairs(valid_urls) do
        assert(provider:matches_url(url), "Should match Jira URL: " .. url)
        local issue_key = provider:extract_task_identifier(url)
        assert_not_nil(issue_key, "Should extract issue key from: " .. url)
    end

    -- Test issue key extraction
    local test_url = "https://company.atlassian.net/browse/PROJ-123"
    local issue_key = provider:extract_task_identifier(test_url)
    assert_equal(issue_key, "PROJ-123", "Should extract correct issue key")

    -- Test invalid URLs
    local invalid_urls = {
        "https://github.com/user/repo/issues/123",
        "https://linear.app/team/issue/ABC-123",
        "https://not-jira.com/browse/PROJ-123"
    }
    
    for _, url in ipairs(invalid_urls) do
        assert_false(provider:matches_url(url), "Should not match non-Jira URL: " .. url)
    end

    -- Test configuration validation
    local enabled, error_msg = provider:is_enabled()
    -- This will fail without actual API key, but should check config structure
    assert_not_nil(error_msg, "Should require API key for enabling")

    -- Test with missing required config
    local incomplete_provider = jira_provider:new({
        enabled = true,
        api_key_env = "JIRA_API_TOKEN"
        -- Missing server_url and project_key
    })
    local enabled2, error_msg2 = incomplete_provider:is_enabled()
    assert_false(enabled2, "Should fail without required config")
    assert_not_nil(error_msg2, "Should provide error message")

    -- Test interface compliance
    local required_methods = {
        "create_task",
        "update_task_status", 
        "add_file_to_task",
        "extract_task_identifier", 
        "matches_url",
        "get_url_pattern",
        "is_enabled",
        "get_base_url"
    }
    
    for _, method_name in ipairs(required_methods) do
        assert_equal(type(provider[method_name]), "function", 
                     "Should implement method: " .. method_name)
    end

    print("✓ Jira provider tests completed")
end

return M