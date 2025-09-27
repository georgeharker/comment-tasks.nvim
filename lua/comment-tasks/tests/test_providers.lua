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

        -- Load main plugin to register providers
        require("comment-tasks")        interface = require("comment-tasks.providers.interface")
    end)

    describe("provider registration", function()
        it("should have all expected providers registered", function()
            local provider_names = interface.get_provider_names()

            local expected_providers = {"clickup", "github", "todoist", "gitlab"}
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
end)
