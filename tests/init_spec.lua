-- Main plugin initialization tests using plenary test harness

-- Import plenary test functions
local plenary = require("plenary.busted")
local describe = plenary.describe
local it = plenary.it
local before_each = plenary.before_each
local assert = require("luassert")

-- Mock plenary.curl for testing
package.preload["plenary.curl"] = function()
    return {
        request = function(opts)
            local response = {
                status = 200,
                body = '{"id": "test_123", "url": "https://example.com/task/123"}'
            }
            if opts.callback then
                vim.schedule(function() opts.callback(response) end)
            end
            return response
        end
    }
end

describe("comment-tasks plugin initialization", function()
    before_each(function()
        -- Clear any cached modules
        for module_name, _ in pairs(package.loaded) do
            if module_name:match("^comment%-tasks") then
                package.loaded[module_name] = nil
            end
        end
    end)

    describe("module loading", function()
        it("should load core modules without errors", function()
            local config = require("comment-tasks.core.config")
            local utils = require("comment-tasks.core.utils")
            local detection = require("comment-tasks.core.detection")
            local interface = require("comment-tasks.providers.interface")

            assert.is_not_nil(config)
            assert.is_not_nil(utils)
            assert.is_not_nil(detection)
            assert.is_not_nil(interface)
        end)

        it("should load provider modules without errors", function()
            assert.has_no.errors(function()
                require("comment-tasks.providers.clickup")
                require("comment-tasks.providers.github")
                require("comment-tasks.providers.todoist")
                require("comment-tasks.providers.gitlab")
            end)
        end)

        it("should load main plugin module", function()
            local comment_tasks = require("comment-tasks")

            assert.is_not_nil(comment_tasks)
            assert.is_function(comment_tasks.setup)
            assert.is_function(comment_tasks.create_task_from_comment)
        end)
    end)

    describe("plugin setup", function()
        it("should setup with empty configuration", function()
            local comment_tasks = require("comment-tasks")

            assert.has_no.errors(function()
                comment_tasks.setup({})
            end)
        end)

        it("should setup with custom configuration", function()
            local comment_tasks = require("comment-tasks")

            local config = {
                default_provider = "clickup",
                providers = {
                    clickup = {
                        enabled = false,
                        api_key_env = "TEST_CLICKUP_API_KEY",
                        list_id = "test_list_123"
                    }
                }
            }

            assert.has_no.errors(function()
                comment_tasks.setup(config)
            end)
        end)

        it("should have all provider-specific functions", function()
            local comment_tasks = require("comment-tasks")

            assert.is_function(comment_tasks.create_clickup_task_from_comment)
            assert.is_function(comment_tasks.create_github_task_from_comment)
            assert.is_function(comment_tasks.create_todoist_task_from_comment)
            assert.is_function(comment_tasks.create_gitlab_task_from_comment)
        end)

        it("should have status update functions", function()
            local comment_tasks = require("comment-tasks")

            assert.is_function(comment_tasks.close_task_from_comment)
            assert.is_function(comment_tasks.review_task_from_comment)
            assert.is_function(comment_tasks.in_progress_task_from_comment)
        end)

        it("should have safe wrapper functions", function()
            local comment_tasks = require("comment-tasks")

            assert.is_function(comment_tasks.close_task_from_comment_safe)
            assert.is_function(comment_tasks.review_task_from_comment_safe)
            assert.is_function(comment_tasks.in_progress_task_from_comment_safe)
            assert.is_function(comment_tasks.add_file_to_task_sources_safe)
        end)
    end)

    describe("utility functions", function()
        it("should extract URLs correctly", function()
            local utils = require("comment-tasks.core.utils")

            local clickup_line = "Check this: https://app.clickup.com/t/abc123def"
            local github_line = "See: https://github.com/user/repo/issues/42"
            local todoist_line = "Task: https://todoist.com/showTask?id=12345"

            assert.equals("https://app.clickup.com/t/abc123def", utils.extract_clickup_url(clickup_line))
            assert.equals("https://github.com/user/repo/issues/42", utils.extract_github_url(github_line))
            assert.equals("https://todoist.com/showTask?id=12345", utils.extract_todoist_url(todoist_line))
        end)

        it("should identify providers from URLs", function()
            local utils = require("comment-tasks.core.utils")

            assert.equals("clickup", utils.get_provider_from_url("https://app.clickup.com/t/123"))
            assert.equals("github", utils.get_provider_from_url("https://github.com/user/repo/issues/1"))
            assert.equals("todoist", utils.get_provider_from_url("https://todoist.com/showTask?id=123"))
            assert.equals("gitlab", utils.get_provider_from_url("https://gitlab.com/user/repo/-/issues/1"))
        end)

        it("should trim comment prefixes correctly", function()
            local utils = require("comment-tasks.core.utils")

            assert.equals("Fix this bug", utils.trim_comment_prefixes("TODO: Fix this bug"))
            assert.equals("Another issue", utils.trim_comment_prefixes("FIXME: Another issue"))
            assert.equals("Critical problem", utils.trim_comment_prefixes("BUG: Critical problem"))
            assert.equals("Memory leak", utils.trim_comment_prefixes("HACK: Memory leak"))
        end)

        it("should create command handlers", function()
            local utils = require("comment-tasks.core.utils")

            local test_function = function(lang)
                return "called with " .. (lang or "nil")
            end

            local handler = utils.create_command_handler(test_function)
            assert.is_function(handler)

            -- Test that handler properly processes opts
            local _result = handler({args = "lua"})
            -- Handler should call the function, we can't easily test the result
            -- in this context, but we can verify it's a function
        end)

        it("should create subcommand handlers", function()
            local utils = require("comment-tasks.core.utils")

            local test_results = {}
            local handlers = {
                new = function(lang) test_results.new = lang or "nil" end,
                close = function(lang) test_results.close = lang or "nil" end,
                review = function(lang) test_results.review = lang or "nil" end,
            }

            local subcommand_handler = utils.create_subcommand_handler(handlers)
            assert.is_function(subcommand_handler)

            -- Test no arguments (should default to "new")
            test_results = {}
            subcommand_handler({args = ""})
            assert.equals("nil", test_results.new)

            -- Test subcommand with language
            test_results = {}
            subcommand_handler({args = "close lua"})
            assert.equals("lua", test_results.close)

            -- Test unknown subcommand (should show error)
            -- We can't easily test vim.notify in this context, but we can verify
            -- that the function doesn't crash
            assert.has_no.errors(function()
                subcommand_handler({args = "unknown"})
            end)
        end)

        it("should create subcommand completion", function()
            local utils = require("comment-tasks.core.utils")
            local languages = { lua = {}, python = {} }

            local completion = utils.create_subcommand_completion(
                {"new", "close", "review"},
                languages
            )
            assert.is_function(completion)

            -- Test completing subcommands on first argument
            local matches = completion("c", ":TestCmd c", 10)
            assert.is_true(vim.tbl_contains(matches, "close"))
            -- Should NOT contain languages in first position anymore
            assert.is_false(vim.tbl_contains(matches, "lua"))

            -- Test completing languages after subcommand
            matches = completion("l", ":TestCmd close l", 15)
            assert.is_true(vim.tbl_contains(matches, "lua"))
        end)
    end)
end)
