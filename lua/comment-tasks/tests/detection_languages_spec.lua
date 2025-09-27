-- Language-specific comment detection tests using plenary

-- Import plenary test functions
local plenary = require("plenary.busted")
local describe = plenary.describe
local it = plenary.it
local before_each = plenary.before_each
local assert = require("luassert")

describe("language-specific comment detection", function()
    local detection, config, languages_config

    -- Test helper function to create mock buffer environment
    local function create_mock_buffer(lines, cursor_pos, filetype)
        local original_api = vim.api
        local original_bo = vim.bo

        vim.api = vim.tbl_extend("force", vim.api or {}, {
            nvim_win_get_cursor = function() return cursor_pos or {1, 0} end,
            nvim_buf_get_lines = function(_, _, _, _) return lines or {} end,
            nvim_buf_set_lines = function(_, _, _, _, _) end
        })

        vim.bo = vim.tbl_extend("force", vim.bo or {}, {
            filetype = filetype or "lua"
        })

        return function() -- Cleanup function
            vim.api = original_api
            vim.bo = original_bo
        end
    end

    before_each(function()
        -- Clear any cached modules
        for module_name, _ in pairs(package.loaded) do
            if module_name:match("^comment%-tasks") then
                package.loaded[module_name] = nil
            end
        end

        detection = require("comment-tasks.core.detection")
        config = require("comment-tasks.core.config")
        languages_config = config.default_config.languages
    end)

    describe("lua comments", function()
        it("should detect single-line lua comments", function()
            local cleanup = create_mock_buffer({
                "-- TODO: Fix this function",
                "-- It needs better error handling",
                "local function test()",
                "    return nil",
                "end"
            }, {1, 0}, "lua")

            local comment_info = detection.get_comment_info_regex("lua", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals(1, comment_info.start_line)
                assert.equals(2, comment_info.end_line)
                assert.equals("lua", comment_info.lang)
                assert.is_true(comment_info.is_comment)
                assert.equals(2, #comment_info.lines)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Fix this function", content)
                assert.matches("better error handling", content)
            end

            cleanup()
        end)

        it("should detect lua block comments", function()
            local cleanup = create_mock_buffer({
                "--[[",
                "TODO: Refactor this entire module",
                "The current implementation is outdated",
                "--]]",
                "local M = {}"
            }, {2, 0}, "lua")

            local comment_info = detection.get_comment_info_regex("lua", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("lua", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Refactor this entire module", content)
            end

            cleanup()
        end)
    end)

    describe("python comments", function()
        it("should detect python single-line comments", function()
            local cleanup = create_mock_buffer({
                "# TODO: Implement user authentication",
                "# This function needs proper validation",
                "def authenticate(user):",
                "    pass"
            }, {1, 0}, "python")

            local comment_info = detection.get_comment_info_regex("python", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("python", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Implement user authentication", content)
                assert.matches("proper validation", content)
            end

            cleanup()
        end)

        it("should detect python docstring comments", function()
            local cleanup = create_mock_buffer({
                'def example():',
                '    """',
                '    TODO: Add comprehensive documentation',
                '    This function needs better docs',
                '    """',
                '    pass'
            }, {3, 4}, "python")

            local comment_info = detection.get_comment_info_regex("python", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("python", comment_info.lang)
                assert.is_true(comment_info.is_comment)
            end

            cleanup()
        end)
    end)

    describe("javascript comments", function()
        it("should detect javascript single-line comments", function()
            local cleanup = create_mock_buffer({
                "// TODO: Implement async/await pattern",
                "// Current callback approach is outdated",
                "function fetchData(callback) {",
                "    // Implementation here",
                "}"
            }, {1, 0}, "javascript")

            local comment_info = detection.get_comment_info_regex("javascript", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("javascript", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("async/await pattern", content)
            end

            cleanup()
        end)

        it("should detect javascript block comments", function()
            local cleanup = create_mock_buffer({
                "/*",
                " * TODO: Refactor this component",
                " * It's getting too complex and hard to maintain",
                " * Consider breaking into smaller pieces",
                " */",
                "function Component() {"
            }, {2, 0}, "javascript")

            local comment_info = detection.get_comment_info_regex("javascript", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("javascript", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Refactor this component", content)
            end

            cleanup()
        end)
    end)

    describe("typescript comments", function()
        it("should detect typescript single-line comments", function()
            local cleanup = create_mock_buffer({
                "// TODO: Add proper type definitions",
                "// The any type is too permissive here",
                "interface User {",
                "    name: string;",
                "}"
            }, {1, 0}, "typescript")

            local comment_info = detection.get_comment_info_regex("typescript", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("typescript", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("proper type definitions", content)
            end

            cleanup()
        end)
    end)

    describe("rust comments", function()
        it("should detect rust single-line comments", function()
            local cleanup = create_mock_buffer({
                "// TODO: Implement error handling",
                "// Consider using Result<T, E> type",
                "fn process_data(data: &str) -> String {",
                "    data.to_string()",
                "}"
            }, {1, 0}, "rust")

            local comment_info = detection.get_comment_info_regex("rust", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("rust", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Implement error handling", content)
            end

            cleanup()
        end)
    end)

    describe("go comments", function()
        it("should detect go single-line comments", function()
            local cleanup = create_mock_buffer({
                "// TODO: Add proper error handling",
                "// Current implementation panics on error",
                "func ProcessData(data string) error {",
                "    return nil",
                "}"
            }, {1, 0}, "go")

            local comment_info = detection.get_comment_info_regex("go", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("go", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("proper error handling", content)
            end

            cleanup()
        end)
    end)

    describe("c/cpp comments", function()
        it("should detect c single-line comments", function()
            local cleanup = create_mock_buffer({
                "// TODO: Optimize memory allocation",
                "// Current approach causes fragmentation",
                "int* allocate_buffer(size_t size) {",
                "    return malloc(size * sizeof(int));",
                "}"
            }, {1, 0}, "c")

            local comment_info = detection.get_comment_info_regex("c", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("c", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Optimize memory allocation", content)
            end

            cleanup()
        end)

        it("should detect c block comments", function()
            local cleanup = create_mock_buffer({
                "/*",
                " * TODO: Implement thread safety",
                " * This function is not thread-safe",
                " * Add mutex locks where needed",
                " */",
                "void critical_section() {"
            }, {2, 0}, "c")

            local comment_info = detection.get_comment_info_regex("c", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("c", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Implement thread safety", content)
            end

            cleanup()
        end)
    end)

    describe("java comments", function()
        it("should detect java single-line comments", function()
            local cleanup = create_mock_buffer({
                "// TODO: Add input validation",
                "// Method should check for null parameters",
                "public String processString(String input) {",
                "    return input.trim();",
                "}"
            }, {1, 0}, "java")

            local comment_info = detection.get_comment_info_regex("java", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("java", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Add input validation", content)
            end

            cleanup()
        end)
    end)

    describe("ruby comments", function()
        it("should detect ruby single-line comments", function()
            local cleanup = create_mock_buffer({
                "# TODO: Refactor this method",
                "# It's doing too many things",
                "def complex_method(args)",
                "  # Implementation",
                "end"
            }, {1, 0}, "ruby")

            local comment_info = detection.get_comment_info_regex("ruby", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("ruby", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Refactor this method", content)
            end

            cleanup()
        end)
    end)

    describe("php comments", function()
        it("should detect php single-line comments", function()
            local cleanup = create_mock_buffer({
                "// TODO: Add proper sanitization",
                "// SQL injection vulnerability here",
                "function getUserData($id) {",
                "    return query('SELECT * FROM users WHERE id = ' . $id);",
                "}"
            }, {1, 0}, "php")

            local comment_info = detection.get_comment_info_regex("php", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("php", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("proper sanitization", content)
            end

            cleanup()
        end)
    end)

    describe("css comments", function()
        it("should detect css comments", function()
            local cleanup = create_mock_buffer({
                "/* TODO: Optimize for mobile devices */",
                "/* Current styles don't work well on small screens */",
                ".container {",
                "    width: 1200px;",
                "}"
            }, {1, 0}, "css")

            local comment_info = detection.get_comment_info_regex("css", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("css", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Optimize for mobile", content)
            end

            cleanup()
        end)
    end)

    describe("html comments", function()
        it("should detect html comments", function()
            local cleanup = create_mock_buffer({
                "<!-- TODO: Add semantic HTML5 elements -->",
                "<!-- Current markup is not accessible -->",
                "<div class='content'>",
                "    <p>Content here</p>",
                "</div>"
            }, {1, 0}, "html")

            local comment_info = detection.get_comment_info_regex("html", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("html", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("semantic HTML5 elements", content)
            end

            cleanup()
        end)
    end)

    describe("shell comments", function()
        it("should detect shell script comments", function()
            local cleanup = create_mock_buffer({
                "#!/bin/bash",
                "# TODO: Add error handling",
                "# Script fails silently on errors",
                "echo 'Starting process...'",
                "process_files"
            }, {2, 0}, "sh")

            local comment_info = detection.get_comment_info_regex("sh", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("sh", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Add error handling", content)
            end

            cleanup()
        end)
    end)

    describe("yaml comments", function()
        it("should detect yaml comments", function()
            local cleanup = create_mock_buffer({
                "# TODO: Add environment-specific configs",
                "# Current config only works for development",
                "database:",
                "  host: localhost",
                "  port: 5432"
            }, {1, 0}, "yaml")

            local comment_info = detection.get_comment_info_regex("yaml", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("yaml", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("environment", content)
            end

            cleanup()
        end)
    end)

    describe("json comments", function()
        it("should handle json files (no standard comments)", function()
            local cleanup = create_mock_buffer({
                "{",
                '  "name": "test-project",',
                '  "version": "1.0.0"',
                "}"
            }, {1, 0}, "json")

            -- JSON doesn't have standard comments, so this should return nil
            local _comment_info = detection.get_comment_info_regex("json", languages_config)
            -- This is expected to be nil for JSON since it doesn't support comments
            cleanup()
        end)
    end)

    describe("vim script comments", function()
        it("should detect vim script comments", function()
            local cleanup = create_mock_buffer({
                '" TODO: Improve plugin performance',
                '" Current implementation is too slow',
                'function! MyFunction()',
                '  echo "hello"',
                'endfunction'
            }, {1, 0}, "vim")

            local comment_info = detection.get_comment_info_regex("vim", languages_config)
            assert.is_not_nil(comment_info)
            if comment_info then
                assert.equals("vim", comment_info.lang)
                assert.is_true(comment_info.is_comment)

                local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
                assert.matches("Improve plugin performance", content)
            end

            cleanup()
        end)
    end)
end)
