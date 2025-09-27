-- Comprehensive JavaScript comment detection tests

local M = {
    language = "JavaScript"
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
            filetype = filetype or "javascript"
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
    
    -- Test 1: Single-line comments (//)
    print("  Testing single-line JavaScript comments...")
    local cleanup = setup_mock_vim({
        "// TODO: Implement user authentication",
        "// This function needs proper validation",
        "// and error handling",
        "function authenticate(username, password) {",
        "    return false;",
        "}"
    }, {1, 0}, "javascript")
    
    local comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect JavaScript single-line comments")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 3, "Should end at line 3")
        assert.assert_equal(comment_info.lang, "javascript", "Should detect JavaScript language")
        assert.assert_equal(comment_info.style_type, "single_line", "Should be single_line style")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Implement user authentication", "Should extract main content")
        assert.assert_contains(content, "error handling", "Should extract all lines")
    end
    cleanup()
    
    -- Test 2: Block comment (/* */) multiline
    print("  Testing multiline block comment...")
    cleanup = setup_mock_vim({
        "/*",
        " * TODO: Refactor this component", 
        " * It has become too complex and needs:",
        " * - Better state management",
        " * - Proper error boundaries", 
        " * - Performance optimization",
        " */",
        "function MyComponent() {"
    }, {3, 0}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect multiline block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 7, "Should end at line 7")
        assert.assert_equal(comment_info.style_type, "block", "Should be block style")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Refactor this component", "Should extract main content")
        assert.assert_contains(content, "state management", "Should extract detailed points")
    end
    cleanup()
    
    -- Test 3: Block comment on single line
    print("  Testing single-line block comment...")
    cleanup = setup_mock_vim({
        "const API_URL = 'https://api.example.com';",
        "/* TODO: Make this configurable */",
        "const timeout = 5000;"
    }, {2, 5}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect single-line block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should be on line 2")
        assert.assert_equal(comment_info.end_line, 2, "Should end on same line")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Make this configurable", "Should extract inline block content")
    end
    cleanup()
    
    -- Test 4: JSDoc-style comment
    print("  Testing JSDoc-style comment...")
    cleanup = setup_mock_vim({
        "/**",
        " * FIXME: This function has a memory leak",
        " * @param {string} data - Input data to process",
        " * @returns {Object} Processed result",
        " * TODO: Add input validation and error handling",
        " */"
    }, {2, 0}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect JSDoc comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 6, "Should end at line 6")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "memory leak", "Should extract FIXME content")
        assert.assert_contains(content, "Add input validation", "Should extract TODO content")
    end
    cleanup()
    
    -- Test 5: Mixed single-line and block comments (should detect current block only)
    print("  Testing mixed comment styles...")
    cleanup = setup_mock_vim({
        "// Single line comment",
        "/*",
        " * TODO: Block comment task",
        " * This is separate from the single line above",
        " */",
        "// Another single line"
    }, {3, 0}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should start at block comment")
        assert.assert_equal(comment_info.end_line, 5, "Should end at block comment")
        assert.assert_equal(comment_info.style_type, "block", "Should be block style")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Block comment task", "Should only extract block content")
        assert.assert_not_contains(content, "Single line comment", "Should not include single line")
    end
    cleanup()
    
    -- Test 6: Nested comment structure (impossible in JS, but test malformed)
    print("  Testing malformed nested comment...")
    cleanup = setup_mock_vim({
        "/*",
        " * TODO: Main task",
        " * /* This would be invalid nesting */",
        " * But we should still detect the outer comment",
        " */"
    }, {2, 0}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect outer comment despite malformed nesting")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 5, "Should end at line 5")
    end
    cleanup()
    
    -- Test 7: Comment at end of function/block
    print("  Testing comment at end of code block...")
    cleanup = setup_mock_vim({
        "function processData(input) {",
        "    const result = transform(input);",
        "    return result;", 
        "    // TODO: Add caching mechanism here",
        "    // This would significantly improve performance",
        "}"
    }, {4, 4}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment at end of block")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 4, "Should start at line 4")
        assert.assert_equal(comment_info.end_line, 5, "Should end at line 5")
    end
    cleanup()
    
    -- Test 8: Multiple TODO items in same comment block
    print("  Testing multiple TODO items...")
    cleanup = setup_mock_vim({
        "/*",
        " * TODO: Task 1 - Implement validation",
        " * TODO: Task 2 - Add error handling", 
        " * TODO: Task 3 - Write unit tests",
        " * FIXME: Fix the memory leak in line 45",
        " * BUG: Handle null pointer exception",
        " */"
    }, {4, 0}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment with multiple tasks")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Task 1", "Should extract first TODO")
        assert.assert_contains(content, "Task 2", "Should extract second TODO")
        assert.assert_contains(content, "memory leak", "Should extract FIXME")
        assert.assert_contains(content, "null pointer", "Should extract BUG")
    end  
    cleanup()
    
    -- Test 9: Comment with URL (React/JSX style)
    print("  Testing comment with existing URL...")
    cleanup = setup_mock_vim({
        "// TODO: Implement responsive design",
        "// See design specs for mobile breakpoints",
        "// https://github.com/owner/repo/issues/123"
    }, {1, 0}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment with URL")
    if comment_info then
        local has_url = detection.comment_has_url(comment_info)
        assert.assert_true(has_url, "Should detect existing URL")
        
        local extracted_url = detection.extract_task_url_from_comment(comment_info)
        assert.assert_contains(extracted_url, "github.com", "Should extract GitHub URL")
    end
    cleanup()
    
    -- Test 10: Arrow function comments
    print("  Testing modern JavaScript patterns...")
    cleanup = setup_mock_vim({
        "const processAsync = async (data) => {",
        "    // TODO: Add proper async error handling",
        "    // Current implementation doesn't handle rejections",
        "    return await api.process(data);",
        "};"
    }, {2, 4}, "javascript")
    
    comment_info = detection.get_comment_info_regex("javascript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment in arrow function")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "async error handling", "Should extract async-specific content")
    end
    cleanup()
    
    print("  ✅ All JavaScript detection tests completed")
end

return M