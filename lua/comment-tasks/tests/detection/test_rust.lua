-- Comprehensive Rust comment detection tests

local M = {
    language = "Rust"
}

local function setup_mock_vim(lines, cursor_pos, filetype)
    local original_vim = _G.vim
    
    _G.vim = {
        api = {
            nvim_win_get_cursor = function() return cursor_pos or {1, 0} end,
            nvim_buf_get_lines = function() return lines or {} end
        },
        bo = { filetype = filetype or "rust" },
        treesitter = { get_parser = function(_, _) return nil end },
        pesc = function(str) return str:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") end,
        tbl_contains = function(t, value) for _, v in ipairs(t) do if v == value then return true end end return false end
    }
    
    return function() _G.vim = original_vim end
end

function M.run_tests(assert)
    local detection = require("comment-tasks.core.detection")
    local config = require("comment-tasks.core.config")
    local languages_config = config.default_config.languages
    
    -- Test 1: Single-line comments (//)
    print("  Testing Rust single-line comments...")
    local cleanup = setup_mock_vim({
        "// TODO: Implement proper error handling",
        "// Current Result<T, E> usage is inconsistent",
        "pub fn process_data(input: &str) -> Result<String, Box<dyn Error>> {"
    }, {1, 0}, "rust")
    
    local comment_info = detection.get_comment_info_regex("rust", languages_config)
    assert.assert_not_nil(comment_info, "Should detect Rust single-line comments")
    cleanup()
    
    -- Test 2: Doc comments (///)
    print("  Testing Rust doc comments...")
    cleanup = setup_mock_vim({
        "/// TODO: Add more comprehensive examples",
        "/// This function processes input data",
        "/// # Arguments",
        "/// * `input` - The input string to process",
        "pub fn process(input: &str) -> String {"
    }, {1, 0}, "rust")
    
    comment_info = detection.get_comment_info_regex("rust", languages_config)
    assert.assert_not_nil(comment_info, "Should detect Rust doc comments")
    cleanup()
    
    -- Test 3: Inner doc comments (//!)
    print("  Testing Rust inner doc comments...")
    cleanup = setup_mock_vim({
        "//! TODO: Add module-level documentation",
        "//! This module handles data processing",
        "//! FIXME: Missing examples and usage instructions"
    }, {1, 0}, "rust")
    
    comment_info = detection.get_comment_info_regex("rust", languages_config)
    assert.assert_not_nil(comment_info, "Should detect Rust inner doc comments")
    cleanup()
    
    -- Test 4: Block comments (/* */)
    print("  Testing Rust block comments...")
    cleanup = setup_mock_vim({
        "/*",
        " * TODO: Implement async version",
        " * Current sync implementation blocks the thread",
        " */"
    }, {2, 0}, "rust")
    
    comment_info = detection.get_comment_info_regex("rust", languages_config)
    assert.assert_not_nil(comment_info, "Should detect Rust block comments")
    cleanup()
    
    print("  ✅ All Rust detection tests completed")
end

return M