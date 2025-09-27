-- CSS comment detection tests
local M = { language = "CSS" }
local function setup_mock_vim(lines, cursor_pos, filetype)
    local original_vim = _G.vim
    _G.vim = {
        api = { nvim_win_get_cursor = function(_, _, _) return cursor_pos or {1, 0} end, nvim_buf_get_lines = function() return lines or {} end },
        bo = { filetype = filetype or "css" },
        treesitter = { get_parser = function(_, _) return nil end },
        pesc = function(str) return str:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") end,
        tbl_contains = function(t, value) for _, v in ipairs(t) do if v == value then return true end end return false end
    }
    return function() _G.vim = original_vim end
end

function M.run_tests(assert)
    print("  Testing CSS comment detection...")
    local cleanup = setup_mock_vim({
        "/*",
        " * TODO: Implement responsive breakpoints",
        " * Current design only works on desktop",
        " */",
        ".container {"
    }, {2, 0}, "css")

    local detection = require("comment-tasks.core.detection")
    local config = require("comment-tasks.core.config")
    local comment_info = detection.get_comment_info_regex("css", config.default_config.languages)
    assert.assert_not_nil(comment_info, "Should detect CSS comments")
    cleanup()
    print("  ✅ CSS detection tests completed")
end
return M
