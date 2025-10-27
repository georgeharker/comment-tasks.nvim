-- Provider tests using plenary

-- Import plenary test functions
local plenary = require("plenary.busted")
local describe = plenary.describe
local it = plenary.it
local before_each = plenary.before_each
local assert = require("luassert")

describe("comment-tasks providers", function()
    local interface

    before_each(function()
        -- Clear any cached modules
        for module_name, _ in pairs(package.loaded) do
            if module_name:match("^comment%-tasks") then
                package.loaded[module_name] = nil
            end
        end

        -- Mock environment variables
        vim.env.CLICKUP_API_KEY = "test_clickup_key"
        vim.env.GITHUB_TOKEN = "test_github_token"
        vim.env.TODOIST_API_KEY = "test_todoist_token"
        vim.env.GITLAB_API_KEY = "test_gitlab_token"
        vim.env.ASANA_ACCESS_TOKEN = "test_asana_token"
        vim.env.LINEAR_API_KEY = "test_linear_key"
        vim.env.JIRA_API_TOKEN = "test_jira_token"
        vim.env.NOTION_API_KEY = "test_notion_key"
        vim.env.MONDAY_API_TOKEN = "test_monday_token"
        vim.env.TRELLO_API_KEY = "test_trello_key"
        vim.env.TRELLO_API_TOKEN = "test_trello_token"

        -- Load main plugin to register providers
        require("comment-tasks")        interface = require("comment-tasks.providers.interface")
    end)

    describe("provider registration", function()
        it("should have all expected providers registered", function()
            local provider_names = interface.get_provider_names()

            local expected_providers = {
                "clickup", "github", "todoist", "gitlab", "asana", 
                "linear", "jira", "notion", "monday", "trello"
            }
            for _, expected in ipairs(expected_providers) do
                local found = false
                for _, actual in ipairs(provider_names) do
                    if actual == expected then
                        found = true
                        break
                    end
                end
                assert.is_true(found, "Should have " .. expected .. " provider registered")
            end
        end)

        it("should create provider instances", function()
            local clickup_provider, _error = interface.create_provider("clickup", {
                enabled = true,
                list_id = "test_list"
            })
            assert.is_not_nil(clickup_provider)

            local github_provider, _error2 = interface.create_provider("github", {
                enabled = true,
                repo_owner = "test_owner",
                repo_name = "test_repo"
            })
            assert.is_not_nil(github_provider)
        end)

        it("should fail for unknown providers", function()
            local provider, error_msg = interface.create_provider("unknown_provider", {})
            assert.is_nil(provider)
            assert.is_not_nil(error_msg)
        end)
    end)

    describe("provider validation", function()
        it("should validate required configuration", function()
            -- ClickUp requires list_id
            local clickup_provider, _error = interface.create_provider("clickup", {
                enabled = true,
                list_id = "test_list"
            })
            assert.is_not_nil(clickup_provider)
            local enabled, _error_msg = clickup_provider:is_enabled()
            assert.is_true(enabled)

            -- GitHub requires repo_owner and repo_name
            local github_provider, _error2 = interface.create_provider("github", {
                enabled = true,
                repo_owner = "test_owner",
                repo_name = "test_repo"
            })
            assert.is_not_nil(github_provider)
            local gh_enabled, _gh_error = github_provider:is_enabled()
            assert.is_true(gh_enabled)
        end)

        it("should fail validation for missing required config", function()
            -- GitHub without repo info should fail is_enabled
            local github_provider, _error = interface.create_provider("github", {
                enabled = true
                -- Missing repo_owner and repo_name
            })
            assert.is_not_nil(github_provider) -- Creates successfully

            local enabled, error_msg = github_provider:is_enabled()
            assert.is_false(enabled) -- But is_enabled fails
            assert.is_not_nil(error_msg)
        end)
    end)

    describe("provider API keys", function()
        it("should retrieve API keys from environment", function()
            local clickup_provider, _error = interface.create_provider("clickup", {
                enabled = true,
                list_id = "test_list"
            })
            assert.is_not_nil(clickup_provider)

            local api_key, _error_msg = clickup_provider:get_api_key()
            assert.equals("test_clickup_key", api_key)
        end)

        it("should use custom environment variable names", function()
            vim.env.CUSTOM_API_KEY = "custom_key_value"

            local provider, _error = interface.create_provider("clickup", {
                enabled = true,
                list_id = "test_list",
                api_key_env = "CUSTOM_API_KEY"
            })
            assert.is_not_nil(provider)

            local api_key, _error_msg = provider:get_api_key()
            assert.equals("custom_key_value", api_key)
        end)
    end)

    describe("new provider creation and validation", function()
        it("should create Asana provider with required config", function()
            local asana_provider, _error = interface.create_provider("asana", {
                enabled = true,
                project_gid = "test_project_gid"
            })
            assert.is_not_nil(asana_provider)

            local enabled, _error_msg = asana_provider:is_enabled()
            assert.is_true(enabled)
        end)

        it("should create Linear provider with required config", function()
            local linear_provider, _error = interface.create_provider("linear", {
                enabled = true,
                team_id = "test_team_id"
            })
            assert.is_not_nil(linear_provider)

            local enabled, _error_msg = linear_provider:is_enabled()
            assert.is_true(enabled)
        end)

        it("should create Jira provider with required config", function()
            local jira_provider, _error = interface.create_provider("jira", {
                enabled = true,
                server_url = "https://test.atlassian.net",
                project_key = "TEST"
            })
            assert.is_not_nil(jira_provider)

            local enabled, _error_msg = jira_provider:is_enabled()
            assert.is_true(enabled)
        end)

        it("should create Notion provider with required config", function()
            local notion_provider, _error = interface.create_provider("notion", {
                enabled = true,
                database_id = "test_database_id"
            })
            assert.is_not_nil(notion_provider)

            local enabled, _error_msg = notion_provider:is_enabled()
            assert.is_true(enabled)
        end)

        it("should create Monday provider with required config", function()
            local monday_provider, _error = interface.create_provider("monday", {
                enabled = true,
                board_id = "123456"
            })
            assert.is_not_nil(monday_provider)

            local enabled, _error_msg = monday_provider:is_enabled()
            assert.is_true(enabled)
        end)

        it("should create Trello provider with required config", function()
            local trello_provider, _error = interface.create_provider("trello", {
                enabled = true,
                board_id = "test_board_id",
                list_mapping = {
                    new = "To Do",
                    completed = "Done"
                }
            })
            assert.is_not_nil(trello_provider)

            local enabled, _error_msg = trello_provider:is_enabled()
            assert.is_true(enabled)
        end)
    end)

    describe("provider URL pattern matching", function()
        it("should match provider-specific URLs correctly", function()
            -- Test URL patterns for all providers
            local test_cases = {
                {
                    provider = "clickup",
                    url = "https://app.clickup.com/t/abc123",
                    should_match = true
                },
                {
                    provider = "github",
                    url = "https://github.com/user/repo/issues/123",
                    should_match = true
                },
                {
                    provider = "asana", 
                    url = "https://app.asana.com/0/1234567890/9876543210",
                    should_match = true
                },
                {
                    provider = "linear",
                    url = "https://linear.app/team/issue/ABC-123/issue-title",
                    should_match = true
                },
                {
                    provider = "jira",
                    url = "https://company.atlassian.net/browse/PROJ-123",
                    should_match = true
                },
                {
                    provider = "notion",
                    url = "https://notion.so/workspace/abc123def456",
                    should_match = true
                },
                {
                    provider = "monday",
                    url = "https://view.monday.com/items/123456",
                    should_match = true
                },
                {
                    provider = "trello",
                    url = "https://trello.com/c/abc123def",
                    should_match = true
                }
            }

            for _, case in ipairs(test_cases) do
                local provider, _error = interface.create_provider(case.provider, {
                    enabled = true,
                    -- Add minimal required config for each provider
                    list_id = case.provider == "clickup" and "test_list" or nil,
                    repo_owner = case.provider == "github" and "test_owner" or nil,
                    repo_name = case.provider == "github" and "test_repo" or nil,
                    project_gid = case.provider == "asana" and "test_project" or nil,
                    team_id = case.provider == "linear" and "test_team" or nil,
                    server_url = case.provider == "jira" and "https://test.atlassian.net" or nil,
                    project_key = case.provider == "jira" and "TEST" or nil,
                    database_id = case.provider == "notion" and "test_db" or nil,
                    board_id = (case.provider == "monday" and "123456") or (case.provider == "trello" and "test_board") or nil,
                    list_mapping = case.provider == "trello" and {new = "To Do"} or nil
                })
                
                if provider then
                    local matches = provider:matches_url(case.url)
                    assert.equals(case.should_match, matches, 
                        "Provider " .. case.provider .. " should " .. 
                        (case.should_match and "match" or "not match") .. " URL: " .. case.url)
                end
            end
        end)
    end)

    describe("generalized status system", function()
        local config
        
        before_each(function()
            config = require("comment-tasks.core.config")
        end)

        it("should resolve provider-specific statuses", function()
            -- Test status resolution for different providers
            local status_tests = {
                {provider = "clickup", status = "new", expected = "to do"},
                {provider = "clickup", status = "completed", expected = "complete"},
                {provider = "asana", status = "new", expected = "Not Started"},
                {provider = "asana", status = "completed", expected = "Complete"},
                {provider = "linear", status = "new", expected = "Todo"},
                {provider = "linear", status = "completed", expected = "Done"},
                {provider = "jira", status = "new", expected = "To Do"},
                {provider = "jira", status = "completed", expected = "Done"},
                {provider = "notion", status = "new", expected = "Not started"},
                {provider = "notion", status = "completed", expected = "Done"},
                {provider = "monday", status = "new", expected = "Not Started"},
                {provider = "monday", status = "completed", expected = "Done"}
            }

            for _, test in ipairs(status_tests) do
                local resolved_status = config.get_provider_status(test.provider, test.status)
                assert.equals(test.expected, resolved_status,
                    "Provider " .. test.provider .. " should resolve status '" .. 
                    test.status .. "' to '" .. test.expected .. "'")
            end
        end)

        it("should handle custom statuses", function()
            -- Mock a custom status configuration
            local mock_config = {
                providers = {
                    clickup = {
                        statuses = {
                            new = "📋 To Do",
                            completed = "✅ Complete",
                            custom = {
                                blocked = "🚫 Blocked",
                                testing = "🧪 Testing"
                            }
                        }
                    }
                }
            }
            
            -- Temporarily override the config
            local original_get_provider_config = config.get_provider_config
            config.get_provider_config = function(provider_name)
                return mock_config.providers[provider_name]
            end

            local blocked_status = config.get_provider_status("clickup", "blocked")
            assert.equals("🚫 Blocked", blocked_status)

            local testing_status = config.get_provider_status("clickup", "testing") 
            assert.equals("🧪 Testing", testing_status)

            -- Restore original function
            config.get_provider_config = original_get_provider_config
        end)

        it("should fall back to defaults for unconfigured statuses", function()
            -- Test fallback behavior for unknown statuses
            local unknown_status = config.get_provider_status("clickup", "unknown_status")
            assert.equals("unknown_status", unknown_status) -- Should return as-is
            
            local fallback_status = config.get_fallback_status("asana", "review")
            assert.equals("Review", fallback_status)
        end)
    end)
end)
