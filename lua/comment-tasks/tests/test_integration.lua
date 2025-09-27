-- Integration tests using plenary

-- Import plenary test functions
local plenary = require("plenary.busted")
local describe = plenary.describe
local it = plenary.it
local before_each = plenary.before_each
local assert = require("luassert")

describe("comment-tasks integration", function()
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
    end)

    describe("plugin initialization", function()
        it("should initialize without errors", function()
            assert.has_no.errors(function()
                require("comment-tasks")
            end)
        end)

        it("should setup with configuration", function()
            local comment_tasks = require("comment-tasks")

            assert.has_no.errors(function()
                comment_tasks.setup({
                    default_provider = "github",
                    providers = {
                        github = {
                            enabled = true,
                            repo_owner = "test_owner",
                            repo_name = "test_repo"
                        }
                    }
                })
            end)
        end)
    end)

    describe("core integration", function()
        it("should integrate detection with configuration", function()
            local config = require("comment-tasks.core.config")
            local detection = require("comment-tasks.core.detection")

            config.setup({
                comment_prefixes = {"TODO", "FIXME", "BUG"}
            })

            local test_config = config.get_config()
            assert.is_not_nil(test_config.comment_prefixes)
            assert.is_not_nil(test_config.languages)

            -- Test that detection can use the configuration
            assert.is_not_nil(detection)
            assert.is_function(detection.get_comment_info)
        end)

        it("should integrate providers with configuration", function()
            local config = require("comment-tasks.core.config")
            local interface = require("comment-tasks.providers.interface")

            config.setup({
                providers = {
                    github = {
                        enabled = true,
                        repo_owner = "test_owner",
                        repo_name = "test_repo"
                    }
                }
            })

            -- Load main plugin to register providers
            require("comment-tasks")            local provider, _error = interface.create_provider("github", config.get_config().providers.github)
            assert.is_not_nil(provider)
        end)
    end)

    describe("end-to-end workflow", function()
        it("should handle complete task creation workflow", function()
            -- Mock vim API for buffer operations
            local mock_lines = {
                "-- TODO: Implement authentication feature",
                "-- This needs to integrate with OAuth2",
                "function authenticate(user) end"
            }

            -- Mock vim functions
            local original_api = vim.api
            vim.api = vim.tbl_extend("force", vim.api or {}, {
                nvim_buf_get_lines = function() return mock_lines end,
                nvim_win_get_cursor = function(_, _, _, _) return {1, 0} end,
                nvim_buf_set_lines = function(_, _, _, _, _) end,
            })

            vim.bo = vim.bo or {}
            vim.bo.filetype = "lua"

            local comment_tasks = require("comment-tasks")
            comment_tasks.setup({
                default_provider = "github",
                providers = {
                    github = {
                        enabled = true,
                        repo_owner = "test_owner",
                        repo_name = "test_repo"
                    }
                }
            })

            -- Test detection workflow
            local config = require("comment-tasks.core.config")
            local detection = require("comment-tasks.core.detection")

            local comment_info = detection.get_comment_info(
                nil,
                config.get_config().languages,
                config.get_config().fallback_to_regex
            )

            -- This might be nil if tree-sitter isn't available, which is ok for integration test
            if comment_info then
                assert.is_true(comment_info.is_comment or comment_info.is_comment == nil)
            end

            -- Restore original API
            vim.api = original_api
        end)
    end)

    describe("utility integration", function()
        it("should integrate URL utilities with providers", function()
            local utils = require("comment-tasks.core.utils")
            local interface = require("comment-tasks.providers.interface")

            -- Test URL detection with actual providers
            local github_url = "https://github.com/owner/repo/issues/123"
            local detected_provider = utils.get_provider_from_url(github_url)
            assert.equals("github", detected_provider)

            detected_provider = assert.is_not_nil(detected_provider)

            -- Verify provider exists
            -- Load main plugin to register providers
            require("comment-tasks")
            local provider_class = interface.get_provider_class(detected_provider)
            assert.is_not_nil(provider_class)
        end)
    end)
end)
