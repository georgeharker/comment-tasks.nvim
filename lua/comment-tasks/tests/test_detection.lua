-- Enhanced comment detection tests using plenary

-- Import plenary test functions
local plenary = require("plenary.busted")
local describe = plenary.describe
local it = plenary.it
local before_each = plenary.before_each
local assert = require("luassert")

describe("comment-tasks detection", function()
    ---@diagnostic disable-next-line: unused-local
    local detection, config, utils

    before_each(function()
        -- Clear any cached modules
        for module_name, _ in pairs(package.loaded) do
            if module_name:match("^comment%-tasks") then
                package.loaded[module_name] = nil
            end
        end
        ---@diagnostic disable-next-line: unused-local
        detection = require("comment-tasks.core.detection")
        config = require("comment-tasks.core.config")
        utils = require("comment-tasks.core.utils")
    end)

    describe("URL detection", function()
        it("should detect provider from URLs", function()
            local clickup_url = "https://app.clickup.com/t/abc123"
            local github_url = "https://github.com/owner/repo/issues/123"
            local todoist_url = "https://todoist.com/showTask?id=123456789"
            local gitlab_url = "https://gitlab.com/owner/project/-/issues/123"

            assert.equals("clickup", utils.get_provider_from_url(clickup_url))
            assert.equals("github", utils.get_provider_from_url(github_url))
            assert.equals("todoist", utils.get_provider_from_url(todoist_url))
            assert.equals("gitlab", utils.get_provider_from_url(gitlab_url))
        end)

        it("should extract provider-specific URLs", function()
            local clickup_url = "https://app.clickup.com/t/abc123"
            local github_url = "https://github.com/owner/repo/issues/123"
            local todoist_url = "https://todoist.com/showTask?id=123456789"
            local gitlab_url = "https://gitlab.com/owner/project/-/issues/123"

            assert.equals(clickup_url, utils.extract_clickup_url(clickup_url))
            assert.equals(github_url, utils.extract_github_url(github_url))
            assert.equals(todoist_url, utils.extract_todoist_url(todoist_url))
            assert.equals(gitlab_url, utils.extract_gitlab_url(gitlab_url))
        end)

        it("should extract generic task URLs", function()
            local clickup_url = "https://app.clickup.com/t/abc123"
            local github_url = "https://github.com/owner/repo/issues/123"
            local todoist_url = "https://todoist.com/showTask?id=123456789"
            local gitlab_url = "https://gitlab.com/owner/project/-/issues/123"

            assert.equals(clickup_url, utils.extract_task_url(clickup_url))
            assert.equals(github_url, utils.extract_task_url(github_url))
            assert.equals(todoist_url, utils.extract_task_url(todoist_url))
            assert.equals(gitlab_url, utils.extract_task_url(gitlab_url))
        end)
    end)

    describe("comment prefix handling", function()
        it("should trim comment prefixes correctly", function()
            local test_cases = {
                {input = "TODO: Fix this bug", expected = "Fix this bug"},
                {input = "FIXME: handle edge case", expected = "handle edge case"},
                {input = "BUG: memory leak here", expected = "memory leak here"},
                {input = "HACK: Quick workaround", expected = "Quick workaround"},
                {input = "NOTE: Important detail", expected = "Important detail"}
            }

            for _, test_case in ipairs(test_cases) do
                local trimmed = utils.trim_comment_prefixes(test_case.input, config.default_config.comment_prefixes)
                assert.equals(test_case.expected, trimmed)
            end
        end)
    end)

    describe("file utilities", function()
        it("should normalize and dedupe files", function()
            local files = {"./src/test.lua", "src/test.py", ".venv/lib/something.py", "src/../test.js"}
            local normalized = utils.normalize_and_dedupe_files(files)

            -- Check if normalized contains expected files
            local found_lua = false
            local found_py = false
            local found_venv = false

            for _, file in ipairs(normalized) do
                if file == "src/test.lua" then found_lua = true end
                if file == "src/test.py" then found_py = true end
                if file:find(".venv") then found_venv = true end
            end

            assert.is_true(found_lua)
            assert.is_true(found_py)
            assert.is_false(found_venv) -- Should filter out .venv files
        end)
    end)

    describe("comprehensive language detection", function()
        it("should run language-specific detection tests", function()
            -- This would normally run the detection tests, but for now we'll just verify
            -- that the detection system can handle different languages
            local languages = config.default_config.languages

            local expected_languages = {
                "lua", "python", "javascript", "typescript", "rust",
                "c", "cpp", "go", "java", "ruby", "php"
            }

            for _, lang in ipairs(expected_languages) do
                assert.is_not_nil(languages[lang])
                assert.is_not_nil(languages[lang].comment_nodes)
                assert.is_not_nil(languages[lang].comment_styles)
            end
        end)
    end)
end)
