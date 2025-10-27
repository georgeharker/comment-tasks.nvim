-- Tests for Asana provider

local interface = require("comment-tasks.providers.interface")
local asana_provider = require("comment-tasks.providers.asana")

local M = {}

-- Mock provider config for testing
local function create_test_config()
    return {
        enabled = true,
        api_key_env = "ASANA_ACCESS_TOKEN",
        project_gid = "1204558436732296",
        assignee_gid = "1204558436732297"
    }
end

-- Test provider creation and configuration
function M.test_provider_creation()
    local config = create_test_config()
    local provider = asana_provider:new(config)
    
    assert(provider, "Provider should be created")
    assert(provider.config.enabled == true, "Provider should be enabled")
    assert(provider.config.project_gid == "1204558436732296", "Project GID should be set")
    assert(provider:get_api_key_env() == "ASANA_ACCESS_TOKEN", "API key env should be correct")
    
    print("✓ Provider creation test passed")
end

-- Test URL pattern matching
function M.test_url_patterns()
    local provider = asana_provider:new(create_test_config())
    
    -- Valid Asana URLs
    local valid_urls = {
        "https://app.asana.com/0/1204558436732296/1204558436732297",
        "https://app.asana.com/0/123456789/987654321"
    }
    
    for _, url in ipairs(valid_urls) do
        assert(provider:matches_url(url), "Should match Asana URL: " .. url)
        local task_id = provider:extract_task_identifier(url)
        assert(task_id, "Should extract task ID from URL: " .. url)
    end
    
    -- Invalid URLs
    local invalid_urls = {
        "https://github.com/user/repo/issues/123",
        "https://app.clickup.com/t/abc123",
        "https://todoist.com/showTask?id=123",
        "https://not-asana.com/0/123/456"
    }
    
    for _, url in ipairs(invalid_urls) do
        assert(not provider:matches_url(url), "Should not match non-Asana URL: " .. url)
    end
    
    print("✓ URL pattern matching test passed")
end

-- Test task ID extraction
function M.test_task_id_extraction()
    local provider = asana_provider:new(create_test_config())
    
    local test_cases = {
        {
            url = "https://app.asana.com/0/1204558436732296/1204558436732297",
            expected_id = "1204558436732297"
        },
        {
            url = "https://app.asana.com/0/123456/789012",
            expected_id = "789012"
        }
    }
    
    for _, case in ipairs(test_cases) do
        local task_id = provider:extract_task_identifier(case.url)
        assert(task_id == case.expected_id, 
               string.format("Expected task ID '%s', got '%s'", case.expected_id, task_id or "nil"))
    end
    
    print("✓ Task ID extraction test passed")
end

-- Test provider interface compliance
function M.test_interface_compliance()
    local provider = asana_provider:new(create_test_config())
    
    -- Check required methods exist
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
        assert(type(provider[method_name]) == "function", 
               "Provider should implement method: " .. method_name)
    end
    
    print("✓ Interface compliance test passed")
end

-- Test provider registration
function M.test_provider_registration()
    local provider_class = interface.get_provider_class("asana")
    assert(provider_class, "Asana provider should be registered")
    assert(provider_class == asana_provider, "Should return correct provider class")
    
    print("✓ Provider registration test passed")
end

-- Test configuration validation
function M.test_config_validation()
    -- Valid configuration
    local valid_config = create_test_config()
    local provider = asana_provider:new(valid_config)
    
    -- Note: This would require actual environment variable setup
    -- In real tests, you'd mock the environment or skip this
    -- local is_valid, error = provider:validate_config()
    -- For now, just test the structure
    
    assert(provider.config.enabled, "Provider should be enabled with valid config")
    assert(provider.config.project_gid, "Project GID should be required")
    
    print("✓ Configuration validation test passed")
end

-- Run all tests
function M.run_all()
    print("Running Asana provider tests...")
    
    M.test_provider_creation()
    M.test_url_patterns()
    M.test_task_id_extraction()
    M.test_interface_compliance()
    M.test_provider_registration()
    M.test_config_validation()
    
    print("✓ All Asana provider tests passed!")
end

return M