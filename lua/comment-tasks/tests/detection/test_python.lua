-- Comprehensive Python comment detection tests

local M = {
    language = "Python"
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
            filetype = filetype or "python"
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
    
    -- Test 1: Single-line hash comments
    print("  Testing Python single-line comments...")
    local cleanup = setup_mock_vim({
        "# TODO: Implement user authentication",
        "# This function needs proper validation",
        "# and comprehensive error handling",
        "def authenticate(username, password):",
        "    return False"
    }, {1, 0}, "python")
    
    local comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect Python single-line comments")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 3, "Should end at line 3")
        assert.assert_equal(comment_info.lang, "python", "Should detect Python language")
        assert.assert_equal(comment_info.style_type, "single_line", "Should be single_line style")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Implement user authentication", "Should extract main content")
        assert.assert_contains(content, "error handling", "Should extract all lines")
    end
    cleanup()
    
    -- Test 2: Triple-quote docstring (""")
    print("  Testing triple-quote docstring...")
    cleanup = setup_mock_vim({
        'def complex_function(data):',
        '    """',
        '    TODO: This function is getting too complex',
        '    ',
        '    It needs to be refactored into smaller pieces:',
        '    - Separate validation logic',
        '    - Extract data processing',
        '    - Add proper error handling',
        '    ',
        '    FIXME: Memory usage is too high for large datasets',
        '    """',
        '    return process_data(data)'
    }, {3, 4}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect triple-quote docstring")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should start at docstring line")
        assert.assert_equal(comment_info.end_line, 10, "Should end at closing quotes")
        assert.assert_equal(comment_info.style_type, "docstring", "Should be docstring style")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "getting too complex", "Should extract TODO content")
        assert.assert_contains(content, "Memory usage", "Should extract FIXME content")
    end
    cleanup()
    
    -- Test 3: Single-quote docstring (''')
    print("  Testing single-quote docstring...")
    cleanup = setup_mock_vim({
        "class DataProcessor:",
        "    '''",
        "    BUG: This class has thread safety issues",
        "    ",
        "    The shared state between methods can cause",
        "    race conditions in multi-threaded environments.",
        "    '''",
        "    def __init__(self):",
        "        self.data = []"
    }, {3, 0}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config) 
    assert.assert_not_nil(comment_info, "Should detect single-quote docstring")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should start at docstring")
        assert.assert_equal(comment_info.end_line, 7, "Should end at closing quotes")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "thread safety issues", "Should extract BUG content")
        assert.assert_contains(content, "race conditions", "Should extract detailed explanation")
    end
    cleanup()
    
    -- Test 4: Inline comment at end of line
    print("  Testing inline comments...")
    cleanup = setup_mock_vim({
        "import os",
        "import sys  # TODO: Remove this unused import",
        "import json",
        "",
        "def main():",
        "    data = load_data()  # FIXME: Add error handling here"
    }, {2, 15}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect inline comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should be on line 2")
        assert.assert_equal(comment_info.end_line, 2, "Should be single line")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Remove this unused import", "Should extract inline content")
    end
    cleanup()
    
    -- Test 5: Module-level docstring
    print("  Testing module-level docstring...")
    cleanup = setup_mock_vim({
        '#!/usr/bin/env python3',
        '"""',
        'TODO: Add comprehensive module documentation',
        '',
        'This module handles data processing and analysis.',
        'It needs better documentation including:',
        '- Usage examples',
        '- API reference', 
        '- Performance considerations',
        '"""',
        '',
        'import sys'
    }, {4, 0}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect module docstring")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should start at docstring")
        assert.assert_equal(comment_info.end_line, 10, "Should end at closing quotes")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "comprehensive module documentation", "Should extract TODO")
        assert.assert_contains(content, "Usage examples", "Should extract bullet points")
    end
    cleanup()
    
    -- Test 6: Comments with indentation
    print("  Testing indented comments...")
    cleanup = setup_mock_vim({
        "def process_items(items):",
        "    for item in items:",
        "        # TODO: Add validation for each item",
        "        # Check required fields and data types",
        "        # Log any validation errors",
        "        result = validate_item(item)",
        "        if not result:",
        "            # FIXME: Should raise exception instead of returning None",
        "            return None"
    }, {3, 8}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect indented comments")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 3, "Should start at first indented comment")
        assert.assert_equal(comment_info.end_line, 5, "Should include consecutive indented comments")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Add validation", "Should extract TODO content")
        assert.assert_contains(content, "validation errors", "Should extract detailed content")
    end
    cleanup()
    
    -- Test 7: Mixed comment and docstring (should detect based on cursor position)
    print("  Testing mixed comment and docstring...")
    cleanup = setup_mock_vim({
        "# TODO: Refactor this function",
        "def calculate(x, y):",
        '    """',
        '    FIXME: This calculation is incorrect for negative numbers',
        '    """',
        "    return x + y"
    }, {1, 0}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect hash comment when cursor is on it")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should detect the hash comment")
        assert.assert_equal(comment_info.end_line, 1, "Should be single line")
        assert.assert_equal(comment_info.style_type, "single_line", "Should be single_line style")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Refactor this function", "Should extract hash comment content")
        assert.assert_not_contains(content, "calculation is incorrect", "Should not include docstring")
    end
    cleanup()
    
    -- Test 8: F-string with comments
    print("  Testing modern Python syntax with comments...")
    cleanup = setup_mock_vim({
        "name = 'Alice'",
        "age = 30",
        "# TODO: Use a proper template engine instead of f-strings", 
        "# This approach doesn't scale well for complex formatting",
        "message = f'Hello {name}, you are {age} years old'",
        "print(message)"
    }, {3, 0}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comments with modern syntax")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "template engine", "Should extract modern Python context")
    end
    cleanup()
    
    -- Test 9: Comment with existing URL
    print("  Testing comment with existing URL...")
    cleanup = setup_mock_vim({
        "# TODO: Fix the authentication bug",
        "# See discussion in the GitHub issue",
        "# https://github.com/owner/repo/issues/456",
        "def authenticate(user):",
        "    pass"
    }, {1, 0}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect comment with URL")
    if comment_info then
        local has_url = detection.comment_has_url(comment_info)
        assert.assert_true(has_url, "Should detect existing URL")
        
        local extracted_url = detection.extract_task_url_from_comment(comment_info)
        assert.assert_contains(extracted_url, "github.com", "Should extract GitHub URL")
    end
    cleanup()
    
    -- Test 10: Decorator and function comments
    print("  Testing decorator patterns...")
    cleanup = setup_mock_vim({
        "@app.route('/api/users')",
        "@login_required",
        "def get_users():",
        '    """',
        '    HACK: This is a temporary implementation',
        '    TODO: Replace with proper user management system',
        '    """',
        "    return {'users': []}"
    }, {5, 4}, "python")
    
    comment_info = detection.get_comment_info_regex("python", languages_config)
    assert.assert_not_nil(comment_info, "Should detect docstring in decorated function")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "temporary implementation", "Should extract HACK content")
        assert.assert_contains(content, "user management system", "Should extract TODO content")
    end
    cleanup()
    
    print("  ✅ All Python detection tests completed")
end

return M