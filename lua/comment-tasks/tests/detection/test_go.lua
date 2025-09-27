-- Go comment detection tests
local M = { language = "Go" }
local function setup_mock_vim(lines, cursor_pos, filetype)
    local original_vim = _G.vim
    _G.vim = {
        api = { nvim_win_get_cursor = function() return cursor_pos or {1, 0} end, nvim_buf_get_lines = function() return lines or {} end },
        bo = { filetype = filetype or "go" },
        treesitter = { get_parser = function(_, _) return nil end },
        pesc = function(str) return str:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") end,
        tbl_contains = function(t, value) for _, v in ipairs(t) do if v == value then return true end end return false end
    }
    return function() _G.vim = original_vim end
end

function M.run_tests(assert)
    print("  Testing Go comment detection...")
    local cleanup = setup_mock_vim({
        "// TODO: Add proper error handling",
        "// Current implementation panics on error",
        "func ProcessData(data string) error {"
    }, {1, 0}, "go")
    
    local detection = require("comment-tasks.core.detection")
    local config = require("comment-tasks.core.config")
    local comment_info = detection.get_comment_info_regex("go", config.default_config.languages)
    assert.assert_not_nil(comment_info, "Should detect Go comments")
    cleanup()
    print("  ✅ Go detection tests completed")
end
return M