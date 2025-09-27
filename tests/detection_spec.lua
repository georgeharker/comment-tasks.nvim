-- Comment detection tests using plenary test harness

-- Import plenary test functions
local plenary = require("plenary.busted")
local describe = plenary.describe
local it = plenary.it
local before_each = plenary.before_each
local assert = require("luassert")

describe("comment detection system", function()
    local config, detection, utils

    before_each(function()
        -- Load modules fresh for each test
        config = require("comment-tasks.core.config")
        detection = require("comment-tasks.core.detection")
        utils = require("comment-tasks.core.utils")

        -- Mock buffer operations
        local mock_lines = {}
        local mock_cursor = {1, 0}

        vim.api = vim.api or {}
        vim.api.nvim_buf_get_lines = function() return mock_lines end
        vim.api.nvim_win_get_cursor = function() return mock_cursor end
        vim.bo = vim.bo or {}

        -- Helper to set up mock buffer
        _G.set_mock_buffer = function(lines, cursor_line, filetype)
            mock_lines = lines
            mock_cursor = {cursor_line or 1, 0}
            vim.bo.filetype = filetype or "lua"
        end
    end)

    describe("single-line comment detection", function()
        it("should detect Python single-line comments", function()
            set_mock_buffer({"# TODO: Fix this bug"}, 1, "python")

            local comment_info = detection.get_comment_info(
                "python",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
            assert.equals("python", comment_info.lang)
        end)

        it("should detect JavaScript single-line comments", function()
            set_mock_buffer({"// TODO: Implement feature"}, 1, "javascript")

            local comment_info = detection.get_comment_info(
                "javascript",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
            assert.equals("javascript", comment_info.lang)
        end)

        it("should detect Lua single-line comments", function()
            set_mock_buffer({"-- FIXME: Add error handling"}, 1, "lua")

            local comment_info = detection.get_comment_info(
                "lua",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
            assert.equals("lua", comment_info.lang)
        end)

        it("should detect Rust single-line comments", function()
            set_mock_buffer({"// BUG: Handle edge case"}, 1, "rust")

            local comment_info = detection.get_comment_info(
                "rust",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
        end)

        it("should detect C/C++ single-line comments", function()
            set_mock_buffer({"// HACK: Memory optimization needed"}, 1, "c")

            local comment_info = detection.get_comment_info(
                "c",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
        end)
    end)

    describe("block comment detection", function()
        it("should detect JavaScript block comments", function()
            set_mock_buffer({
                "/*",
                " * TODO: Refactor this function",
                " * It's getting too complex",
                " */"
            }, 2, "javascript")

            local comment_info = detection.get_comment_info(
                "javascript",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
        end)

        it("should detect Lua block comments", function()
            set_mock_buffer({
                "--[[",
                "TODO: Add comprehensive error handling",
                "This module needs better validation",
                "--]]"
            }, 2, "lua")

            local comment_info = detection.get_comment_info(
                "lua",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)
            assert.is_true(comment_info.is_comment)
        end)
    end)

    describe("comment content extraction", function()
        it("should extract clean content from single-line comments", function()
            set_mock_buffer({"# TODO: Fix database connection issue"}, 1, "python")

            local comment_info = detection.get_comment_info(
                "python",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)

            local content = detection.extract_comment_content(
                comment_info,
                config.default_config.comment_prefixes
            )

            assert.equals("Fix database connection issue", content)
        end)

        it("should extract content from block comments", function()
            set_mock_buffer({
                "/*",
                " * TODO: Add input validation",
                " * This is critical for security",
                " */"
            }, 2, "javascript")

            local comment_info = detection.get_comment_info(
                "javascript",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)

            local content = detection.extract_comment_content(
                comment_info,
                config.default_config.comment_prefixes
            )

            assert.is_not_nil(content:match("Add input validation"))
        end)

        it("should handle different comment prefixes", function()
            local prefixes = {"TODO", "FIXME", "BUG", "HACK", "NOTE"}

            for _, prefix in ipairs(prefixes) do
                local text = prefix .. ": Test message"
                local result = utils.trim_comment_prefixes(text, prefixes)
                assert.equals("Test message", result)
            end
        end)
    end)

    describe("URL detection", function()
        it("should detect URLs in comments", function()
            set_mock_buffer({"# TODO: Fix bug https://app.clickup.com/t/abc123"}, 1, "python")

            local comment_info = detection.get_comment_info(
                "python",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)

            local has_url = detection.comment_has_url(comment_info)
            assert.is_true(has_url)
        end)

        it("should extract URLs from comments", function()
            set_mock_buffer({"# See task: https://github.com/user/repo/issues/42"}, 1, "python")

            local comment_info = detection.get_comment_info(
                "python",
                config.default_config.languages,
                true
            )

            assert.is_not_nil(comment_info)

            local task_url = detection.extract_task_url_from_comment(comment_info)
            assert.equals("https://github.com/user/repo/issues/42", task_url)
        end)
    end)

    describe("language support", function()
        it("should support major programming languages", function()
            local languages = config.default_config.languages

            local expected_languages = {
                "python", "javascript", "typescript", "lua", "rust",
                "c", "cpp", "go", "java", "ruby", "php", "css", "html"
            }

            for _, lang in ipairs(expected_languages) do
                assert.is_not_nil(languages[lang], "Should support " .. lang)
                assert.is_not_nil(languages[lang].comment_nodes, lang .. " should have comment_nodes")
                assert.is_not_nil(languages[lang].comment_styles, lang .. " should have comment_styles")
            end
        end)
    end)
end)
