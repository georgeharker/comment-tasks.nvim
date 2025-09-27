-- Neovim integration tests using plenary test framework

local M = {}

-- Use plenary test framework if available
local has_plenary, plenary = pcall(require, "plenary.busted")

if not has_plenary then
    print("Plenary not available - skipping Neovim integration tests")
    return M
end

-- Import plenary test functions
local describe = plenary.describe
local it = plenary.it
local before_each = plenary.before_each
local assert = require("luassert")

-- Test helper functions
local function create_test_buffer(content, filetype)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.bo[buf].filetype = filetype
    return buf
end

local function setup_test_environment()
    -- Mock environment variables
    vim.env.CLICKUP_API_KEY = "test_clickup_key"
            vim.env.GITHUB_TOKEN = "test_github_token"
    vim.env.TODOIST_API_KEY = "test_todoist_token"
    vim.env.GITLAB_API_KEY = "test_gitlab_token"

    -- Setup plugin with test configuration
    require("comment-tasks").setup({
        default_provider = "github",
        providers = {
            clickup = {
                enabled = true,
                list_id = "test_list_id"
            },
            github = {
                enabled = true,
                repo_owner = "test_owner",
                repo_name = "test_repo"
            },
            todoist = {
                enabled = true,
                project_id = "test_project"
            },
            gitlab = {
                enabled = true,
                project_id = "12345"
            }
        }
    })
end

local function mock_http_requests()
    -- Mock plenary.curl for testing
    package.loaded["plenary.curl"] = {
        request = function(opts)
            local callback = opts.callback
            local url = opts.url

            -- Simulate async response
            vim.schedule(function()
                local response = {
                    status = 201,
                    body = vim.fn.json_encode({
                        id = "mock_task_123",
                        html_url = "https://github.com/test/repo/issues/123",
                        web_url = "https://gitlab.com/test/project/-/issues/123"
                    })
                }

                -- Simulate different responses for different providers
                if url:match("clickup") then
                    response.body = vim.fn.json_encode({
                        id = "clickup_123",
                        url = "https://app.clickup.com/t/clickup_123"
                    })
                elseif url:match("todoist") then
                    response.body = vim.fn.json_encode({
                        id = "123456789",
                        url = "https://todoist.com/showTask?id=123456789"
                    })
                elseif url:match("gitlab") then
                    response.body = vim.fn.json_encode({
                        iid = "123",
                        web_url = "https://gitlab.com/test/project/-/issues/123"
                    })
                end

                callback(response)
            end)
        end
    }
end

-- Test suite using plenary describe/it
describe("Comment Tasks Neovim Integration", function()
    before_each(function()
        setup_test_environment()
        mock_http_requests()
    end)

    describe("Comment Detection", function()
        it("should detect Lua comments", function()
            local buf = create_test_buffer({
                "-- TODO: Fix this function",
                "-- It needs better error handling",
                "local function test()",
                "    return nil",
                "end"
            }, "lua")

            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_win_set_cursor(0, {1, 0}) -- Position on TODO comment

            local detection = require("comment-tasks.core.detection")
            local config = require("comment-tasks.core.config")

            local comment_info = detection.get_comment_info(
                nil,
                config.get_config().languages,
                config.get_config().fallback_to_regex
            )

            comment_info = assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
            assert.equals("lua", comment_info.lang)

            vim.api.nvim_buf_delete(buf, {force = true})
        end)

        it("should detect Python comments", function()
            local buf = create_test_buffer({
                "# TODO: Implement authentication",
                "# This is a critical security feature",
                "def login(username, password):",
                "    pass"
            }, "python")

            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_win_set_cursor(0, {1, 0})

            local detection = require("comment-tasks.core.detection")
            local config = require("comment-tasks.core.config")

            local comment_info = detection.get_comment_info(
                nil,
                config.get_config().languages,
                config.get_config().fallback_to_regex
            )

            comment_info = assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
            assert.equals("python", comment_info.lang)

            vim.api.nvim_buf_delete(buf, {force = true})
        end)

        it("should detect JavaScript block comments", function()
            local buf = create_test_buffer({
                "/*",
                " * TODO: Refactor this component",
                " * It's getting too complex",
                " */",
                "function Component() {",
                "    return null;",
                "}"
            }, "javascript")

            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_win_set_cursor(0, {2, 0}) -- Position inside block comment

            local detection = require("comment-tasks.core.detection")
            local config = require("comment-tasks.core.config")

            local comment_info = detection.get_comment_info(
                nil,
                config.get_config().languages,
                config.get_config().fallback_to_regex
            )

            comment_info = assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
            assert.equals("javascript", comment_info.lang)

            vim.api.nvim_buf_delete(buf, {force = true})
        end)
    end)

    describe("Content Extraction", function()
        it("should extract clean content from TODO comments", function()
            local buf = create_test_buffer({
                "-- TODO: Fix memory leak in parser",
                "-- This affects performance significantly"
            }, "lua")

            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_win_set_cursor(0, {1, 0})

            local detection = require("comment-tasks.core.detection")
            local config = require("comment-tasks.core.config")

            local comment_info = detection.get_comment_info(
                nil,
                config.get_config().languages,
                config.get_config().fallback_to_regex
            )

            if comment_info then
                local content = detection.extract_comment_content(
                    comment_info,
                    config.get_config().comment_prefixes
                )

                assert.is_not_nil(content)
                assert.matches("Fix memory leak", content)
                assert.not_matches("TODO:", content) -- Should be trimmed
            end

            vim.api.nvim_buf_delete(buf, {force = true})
        end)

        it("should handle multiple comment prefixes", function()
            local prefixes = {"TODO", "FIXME", "BUG", "HACK"}
            local config = require("comment-tasks.core.config")

            for _, prefix in ipairs(prefixes) do
                local buf = create_test_buffer({
                    "// " .. prefix .. ": This is a test comment",
                    "// More details here"
                }, "javascript")

                vim.api.nvim_set_current_buf(buf)
                vim.api.nvim_win_set_cursor(0, {1, 0})

                local detection = require("comment-tasks.core.detection")
                local comment_info = detection.get_comment_info(
                    nil,
                    config.get_config().languages,
                    config.get_config().fallback_to_regex
                )

                if comment_info then
                    local content = detection.extract_comment_content(
                        comment_info,
                        config.get_config().comment_prefixes
                    )

                    assert.is_not_nil(content)
                    assert.matches("This is a test comment", content)
                    assert.not_matches(prefix .. ":", content)
                end

                vim.api.nvim_buf_delete(buf, {force = true})
            end
        end)
    end)

    describe("URL Detection and Extraction", function()
        it("should detect existing task URLs in comments", function()
            local buf = create_test_buffer({
                "# TODO: Fix authentication bug",
                "# https://github.com/owner/repo/issues/123",
                "def authenticate(token):",
                "    pass"
            }, "python")

            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_win_set_cursor(0, {1, 0})

            local detection = require("comment-tasks.core.detection")
            local config = require("comment-tasks.core.config")

            local comment_info = detection.get_comment_info(
                nil,
                config.get_config().languages,
                config.get_config().fallback_to_regex
            )

            if comment_info then
                local has_url = detection.comment_has_url(comment_info)
                assert.is_true(has_url)

                local extracted_url = detection.extract_task_url_from_comment(comment_info)
                assert.is_not_nil(extracted_url)
                assert.matches("github.com", extracted_url)
            end

            vim.api.nvim_buf_delete(buf, {force = true})
        end)

        it("should detect different provider URLs", function()
            local test_cases = {
                {
                    url = "https://app.clickup.com/t/abc123",
                    provider = "clickup"
                },
                {
                    url = "https://github.com/owner/repo/issues/123",
                    provider = "github"
                },
                {
                    url = "https://todoist.com/showTask?id=123456789",
                    provider = "todoist"
                },
                {
                    url = "https://gitlab.com/owner/project/-/issues/123",
                    provider = "gitlab"
                }
            }

            local utils = require("comment-tasks.core.utils")

            for _, test_case in ipairs(test_cases) do
                local detected_provider = utils.get_provider_from_url(test_case.url)
                assert.equals(test_case.provider, detected_provider)

                local extracted_url = utils.extract_task_url(test_case.url)
                assert.equals(test_case.url, extracted_url)
            end
        end)
    end)

    describe("Provider Integration", function()
        it("should create provider instances", function()
            local interface = require("comment-tasks.providers.interface")

            -- Test all providers can be created with proper config
            local providers = {"clickup", "github", "todoist", "gitlab"}
            for _, provider_name in ipairs(providers) do
                local config_map = {
                    clickup = { enabled = true, list_id = "test" },
                    github = { enabled = true, repo_owner = "test", repo_name = "repo" },
                    todoist = { enabled = true },
                    gitlab = { enabled = true, project_id = "12345" }
                }

                local provider, error_msg = interface.create_provider(provider_name, config_map[provider_name])
                assert.is_not_nil(provider, "Should create " .. provider_name .. " provider")
                if error_msg then
                    print("Provider creation error: " .. error_msg)
                end
            end
        end)

        it("should validate provider configurations using is_enabled", function()
            local interface = require("comment-tasks.providers.interface")

            -- Test ClickUp requires list_id - creation succeeds but is_enabled fails
            local clickup_provider, _error_msg = interface.create_provider("clickup", {
                enabled = true
                -- Missing list_id
            })
            clickup_provider = assert.is_not_nil(clickup_provider)

            -- But is_enabled should fail due to missing list_id
            local enabled, error_reason = clickup_provider:is_enabled()
            assert.is_false(enabled)
            assert.is_not_nil(error_reason)

            -- Test GitHub requires repo info - creation succeeds but is_enabled fails
            local github_provider, _github_error = interface.create_provider("github", {
                enabled = true
                -- Missing repo_owner and repo_name
            })
            github_provider = assert.is_not_nil(github_provider)

            -- But is_enabled should fail due to missing repo info
            local gh_enabled, gh_error = github_provider:is_enabled()
            assert.is_false(gh_enabled)
            assert.is_not_nil(gh_error)

            -- Test GitLab requires project_id - creation succeeds but is_enabled fails
            local gitlab_provider, _gitlab_error = interface.create_provider("gitlab", {
                enabled = true
                -- Missing project_id
            })
            gitlab_provider = assert.is_not_nil(gitlab_provider)

            -- But is_enabled should fail due to missing project_id
            local gl_enabled, gl_error = gitlab_provider:is_enabled()
            assert.is_false(gl_enabled)
            assert.is_not_nil(gl_error)
        end)
    end)

    describe("Task Management Workflow", function()
        it("should handle task creation workflow", function()
            local buf = create_test_buffer({
                "-- TODO: Implement cache invalidation",
                "-- This is needed for better performance"
            }, "lua")

            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_win_set_cursor(0, {1, 0})

            -- Mock user input for task creation
            local original_input = vim.ui.input
            vim.ui.input = function(opts, callback)
                -- Remove unused opts parameter warning
                _ = opts
                callback("Implement cache invalidation")
            end

            local main_plugin = require("comment-tasks")

            -- Test that task creation doesn't crash
            local ok, _task_error = pcall(main_plugin.create_github_task_from_comment)
            assert.is_true(ok, "Task creation should not crash")
            -- Ignore task_error for now since it's not used

            -- Restore original input
            vim.ui.input = original_input

            vim.api.nvim_buf_delete(buf, {force = true})
        end)

        it("should prevent duplicate task creation", function()
            local buf = create_test_buffer({
                "-- TODO: Fix authentication bug",
                "-- https://github.com/owner/repo/issues/123"
            }, "lua")

            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_win_set_cursor(0, {1, 0})

            local detection = require("comment-tasks.core.detection")
            local config = require("comment-tasks.core.config")

            local comment_info = detection.get_comment_info(
                nil,
                config.get_config().languages,
                config.get_config().fallback_to_regex
            )

            if comment_info then
                local has_url = detection.comment_has_url(comment_info)
                assert.is_true(has_url, "Should detect existing URL")
            end

            vim.api.nvim_buf_delete(buf, {force = true})
        end)
    end)

    describe("Command Registration", function()
        it("should register all expected commands", function()
            -- We can't easily test command registration in a unit test,
            -- but we can verify the functions exist
            local main_plugin = require("comment-tasks")

            assert.is_not_nil(main_plugin.create_task_from_comment)
            assert.is_not_nil(main_plugin.close_task_from_comment)
            assert.is_not_nil(main_plugin.add_file_to_task_sources)
            assert.is_not_nil(main_plugin.create_clickup_task_from_comment)
            assert.is_not_nil(main_plugin.create_github_task_from_comment)
            assert.is_not_nil(main_plugin.create_todoist_task_from_comment)
            assert.is_not_nil(main_plugin.create_gitlab_task_from_comment)
        end)
    end)
end)

function M.run_tests()
    if has_plenary then
        print("Running Neovim integration tests with plenary...")
        -- The tests will run automatically when this file is loaded by plenary
        return true
    else
        print("Plenary not available - run with :PlenaryBustedFile to execute these tests")
        return false
    end
end

return M
