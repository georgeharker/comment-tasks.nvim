-- Comprehensive Lua comment detection tests

local M = {
    language = "Lua"
}

-- Mock vim API for testing
local function setup_mock_vim(lines, cursor_pos, filetype)
    local original_vim = _G.vim
    
    _G.vim = {
        api = {
            nvim_win_get_cursor = function() return cursor_pos or {1, 0} end,
            nvim_buf_get_lines = function(bufnr, start, stop, strict_indexing)
                return lines or {}
            end,
            nvim_buf_set_lines = function() end
        },
        bo = {
            filetype = filetype or "lua"
        },
        treesitter = {
            get_parser = function(_, _) return nil end -- Force fallback to regex
        },
        pesc = function(str)
            return str:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
        end,
        tbl_contains = function(t, value)
            for _, v in ipairs(t) do
                if v == value then return true end
            end
            return false
        end
    }
    
    return function() -- Cleanup function
        _G.vim = original_vim
    end
end

function M.run_tests(assert)
    local detection = require("comment-tasks.core.detection")
    local config = require("comment-tasks.core.config")
    local languages_config = config.default_config.languages
    
    -- Test 1: Single-line comment at start of block
    print("  Testing single-line comment detection...")
    local cleanup = setup_mock_vim({
        "-- TODO: Fix this function",
        "-- It needs better error handling",
        "local function test()",
        "    return nil",
        "end"
    }, {1, 0}, "lua")
    
    local comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect single-line comment at start")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 2, "Should end at line 2") 
        assert.assert_equal(comment_info.lang, "lua", "Should detect Lua language")
        assert.assert_true(comment_info.is_comment, "Should be marked as comment")
        assert.assert_equal(#comment_info.lines, 2, "Should have 2 lines")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Fix this function", "Should extract main content")
        assert.assert_contains(content, "better error handling", "Should extract secondary content")
    end
    cleanup()
    
    -- Test 2: Single-line comment in middle of block
    print("  Testing single-line comment in middle of block...")
    cleanup = setup_mock_vim({
        "local function test()",
        "    -- TODO: Add input validation here",
        "    -- This is critical for security",
        "    return process_input(input)",
        "end"
    }, {2, 4}, "lua")
    
    comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment in middle")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should start at line 2")
        assert.assert_equal(comment_info.end_line, 3, "Should end at line 3")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Add input validation", "Should extract validation content")
    end
    cleanup()
    
    -- Test 3: Single-line comment at end
    print("  Testing single-line comment at end...")
    cleanup = setup_mock_vim({
        "local function test()",
        "    return nil",
        "end",
        "-- TODO: Write unit tests for this function",
        "-- Tests should cover edge cases"
    }, {4, 0}, "lua")
    
    comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment at end")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 4, "Should start at line 4")
        assert.assert_equal(comment_info.end_line, 5, "Should end at line 5")
    end
    cleanup()
    
    -- Test 4: Block comment (--[[ ]]) multiline
    print("  Testing multiline block comment...")
    cleanup = setup_mock_vim({
        "--[[",
        "TODO: Refactor this entire module",
        "It has grown too complex and needs:",
        "- Better separation of concerns", 
        "- More comprehensive error handling",
        "- Unit tests",
        "--]]",
        "local M = {}"
    }, {2, 0}, "lua")
    
    comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect multiline block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 7, "Should end at line 7")
        assert.assert_equal(comment_info.style_type, "block", "Should be block style")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Refactor this entire module", "Should extract main content")
        assert.assert_contains(content, "separation of concerns", "Should extract detailed content")
    end
    cleanup()
    
    -- Test 5: Block comment on single line
    print("  Testing single-line block comment...")
    cleanup = setup_mock_vim({
        "local x = 5",
        "--[[ TODO: Make this configurable --]]",
        "local y = 10"
    }, {2, 5}, "lua")
    
    comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect single-line block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should be on line 2")
        assert.assert_equal(comment_info.end_line, 2, "Should end on same line")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Make this configurable", "Should extract block content")
    end
    cleanup()
    
    -- Test 6: Repeated single-line comments with gaps
    print("  Testing single-line comments with gaps...")
    cleanup = setup_mock_vim({
        "-- TODO: Step 1 - Initialize data structures",
        "",
        "-- TODO: Step 2 - Process input data", 
        "-- This step is complex and needs attention",
        "",
        "local function process() end"
    }, {3, 0}, "lua")
    
    comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment with gaps")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 3, "Should start at line 3")
        assert.assert_equal(comment_info.end_line, 4, "Should end at line 4")
        -- Should not include the first comment due to gap
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Step 2", "Should extract step 2 content")
        assert.assert_contains(content, "complex and needs attention", "Should extract detailed content")
    end
    cleanup()
    
    -- Test 7: Nested block structure
    cleanup = setup_mock_vim({
        "--[[",
        "FIXME: Critical bug in authentication system",
        "",
        "The current implementation has several issues:",
        "1. Password validation is too weak",
        "2. Session management is insecure", 
        "3. No rate limiting on login attempts",
        "",
        "Priority: HIGH",
        "--]]"
    }, {5, 0}, "lua")
    
    comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect complex block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 10, "Should end at line 10")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Critical bug", "Should extract main issue")
        assert.assert_contains(content, "Password validation", "Should extract specific issues")
        assert.assert_contains(content, "Priority: HIGH", "Should extract priority")
    end
    cleanup()
    
    -- Test 8: Mixed comment styles (should not be detected as single block)
    print("  Testing mixed comment styles...")
    cleanup = setup_mock_vim({
        "-- Single line comment",
        "--[[",
        "Block comment",
        "--]]",
        "-- Another single line"
    }, {1, 0}, "lua")
    
    comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect first single-line comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should only get first comment")
        assert.assert_equal(comment_info.end_line, 1, "Should only be one line")
        -- Should not include the block comment due to style difference
    end
    cleanup()
    
    -- Test 9: Comment with existing URL (should be detected)
    print("  Testing comment with existing URL...")
    cleanup = setup_mock_vim({
        "-- TODO: Implement caching mechanism",
        "-- This will improve performance significantly", 
        "-- https://app.clickup.com/t/abc123"
    }, {1, 0}, "lua")
    
    comment_info = detection.get_comment_info_regex("lua", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment with URL")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should include all related lines")
        assert.assert_equal(comment_info.end_line, 3, "Should include URL line")
        
        local has_url = detection.comment_has_url(comment_info)
        assert.assert_true(has_url, "Should detect existing URL")
        
        local extracted_url = detection.extract_task_url_from_comment(comment_info)
        assert.assert_not_nil(extracted_url, "Should extract URL")
        assert.assert_contains(extracted_url, "clickup.com", "Should extract ClickUp URL")
    end
    cleanup()
    
    -- Test 10: Edge case - cursor at different positions in block
    print("  Testing cursor position edge cases...")
    local test_lines = {
        "-- TODO: Multi-line task description",
        "-- Line 2 of the description", 
        "-- Line 3 with more details",
        "-- Final line of the comment block"
    }
    
    -- Test cursor at each line
    for line_num = 1, 4 do
        cleanup = setup_mock_vim(test_lines, {line_num, 0}, "lua")
        
        comment_info = detection.get_comment_info_regex("lua", languages_config)
        assert.assert_not_nil(comment_info, "Should detect comment at line " .. line_num)
        if comment_info then
            assert.assert_equal(comment_info.start_line, 1, "Should always start at line 1")
            assert.assert_equal(comment_info.end_line, 4, "Should always end at line 4")
        end
        cleanup()
    end
    
    print("  ✅ All Lua detection tests completed")
end

return M