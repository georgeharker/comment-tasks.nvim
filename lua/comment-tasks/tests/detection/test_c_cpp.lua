-- Comprehensive C/C++ comment detection tests

local M = {
    language = "C/C++"
}

-- Mock vim API for testing
local function setup_mock_vim(lines, cursor_pos, filetype)
    local original_vim = _G.vim

    _G.vim = {
        api = {
            nvim_win_get_cursor = function() return cursor_pos or {1, 0} end,
            nvim_buf_get_lines = function(_bufnr, _start, _stop, _strict_indexing)
                return lines or {}
            end,
            nvim_buf_set_lines = function(_, _, _, _, _) end
        },
        bo = {
            filetype = filetype or "c"
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

    -- Test 1: Single-line C++ comments
    print("  Testing C++ single-line comments...")
    local cleanup = setup_mock_vim({
        "// TODO: Implement memory pool allocator",
        "// Current malloc/free approach is inefficient",
        "// for frequent small allocations",
        "#include <stdlib.h>",
        "",
        "void* allocate_memory(size_t size) {"
    }, {1, 0}, "cpp")

    local comment_info = detection.get_comment_info_regex("cpp", languages_config)
    assert.assert_not_nil(comment_info, "Should detect C++ single-line comments")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 3, "Should end at line 3")
        assert.assert_equal(comment_info.lang, "cpp", "Should detect C++ language")

        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "memory pool allocator", "Should extract C++-specific content")
        assert.assert_contains(content, "small allocations", "Should extract performance context")
    end
    cleanup()

    -- Test 2: Block comment multiline
    print("  Testing multiline block comment...")
    cleanup = setup_mock_vim({
        "/*",
        " * TODO: Refactor this function to reduce complexity",
        " * Current implementation has several issues:",
        " * - Too many nested loops",
        " * - Poor memory management",
        " * - No error handling",
        " * FIXME: Buffer overflow vulnerability on line 45",
        " */",
        "int process_data(char* buffer, int size) {"
    }, {3, 0}, "c")

    comment_info = detection.get_comment_info_regex("c", languages_config)
    assert.assert_not_nil(comment_info, "Should detect multiline block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 8, "Should end at line 8")
        assert.assert_equal(comment_info.style_type, "block", "Should be block style")

        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "reduce complexity", "Should extract TODO content")
        assert.assert_contains(content, "Buffer overflow", "Should extract FIXME content")
        assert.assert_contains(content, "nested loops", "Should extract specific issues")
    end
    cleanup()

    -- Test 3: Single-line block comment
    print("  Testing single-line block comment...")
    cleanup = setup_mock_vim({
        "#define MAX_SIZE 1024",
        "/* TODO: Make this configurable */",
        "#define BUFFER_SIZE 512"
    }, {2, 5}, "c")

    comment_info = detection.get_comment_info_regex("c", languages_config)
    assert.assert_not_nil(comment_info, "Should detect single-line block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should be on line 2")
        assert.assert_equal(comment_info.end_line, 2, "Should end on same line")

        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Make this configurable", "Should extract configuration TODO")
    end
    cleanup()

    -- Test 4: Header guard comments
    print("  Testing header guard comments...")
    cleanup = setup_mock_vim({
        "#ifndef UTILS_H",
        "#define UTILS_H",
        "",
        "/*",
        " * TODO: Add thread safety to these utility functions",
        " * Current implementation is not thread-safe and will",
        " * cause issues in multi-threaded applications",
        " */",
        "",
        "#ifdef __cplusplus",
        "extern \"C\" {"
    }, {5, 0}, "c")

    comment_info = detection.get_comment_info_regex("c", languages_config)
    assert.assert_not_nil(comment_info, "Should detect header guard comment")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "thread safety", "Should extract threading TODO")
        assert.assert_contains(content, "multi-threaded", "Should extract threading context")
    end
    cleanup()

    -- Test 5: Function documentation comment
    print("  Testing function documentation...")
    cleanup = setup_mock_vim({
        "/**",
        " * FIXME: This function has memory leaks",
        " * @brief Processes input data and returns result",
        " * @param data Input data pointer",
        " * @param size Size of input data",
        " * @return Pointer to processed data or NULL on error",
        " * TODO: Add proper error codes instead of NULL returns",
        " */",
        "void* process_input(const void* data, size_t size);"
    }, {2, 0}, "c")

    comment_info = detection.get_comment_info_regex("c", languages_config)
    assert.assert_not_nil(comment_info, "Should detect function documentation")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "memory leaks", "Should extract FIXME content")
        assert.assert_contains(content, "error codes", "Should extract TODO content")
        assert.assert_contains(content, "@brief", "Should include documentation tags")
    end
    cleanup()

    -- Test 6: Struct definition comments
    print("  Testing struct definition comments...")
    cleanup = setup_mock_vim({
        "typedef struct {",
        "    int id;              // TODO: Use uint32_t instead",
        "    char name[64];       // FIXME: Use dynamic allocation",
        "    double balance;      // OK: Adequate precision",
        "    /*",
        "     * TODO: Add timestamp fields",
        "     * - created_at",
        "     * - updated_at",
        "     */",
        "} User;"
    }, {6, 5}, "c")

    comment_info = detection.get_comment_info_regex("c", languages_config)
    assert.assert_not_nil(comment_info, "Should detect struct block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 5, "Should start at block comment")
        assert.assert_equal(comment_info.end_line, 9, "Should end at block comment")

        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "timestamp fields", "Should extract TODO content")
        assert.assert_contains(content, "created_at", "Should extract field details")
    end
    cleanup()

    -- Test 7: Preprocessor comments
    print("  Testing preprocessor comments...")
    cleanup = setup_mock_vim({
        "#ifdef DEBUG",
        "    // TODO: Replace with proper logging framework",
        "    // printf debugging is not suitable for production",
        "    #define LOG(x) printf(x)",
        "#else",
        "    #define LOG(x) do {} while(0)",
        "#endif"
    }, {2, 4}, "c")

    comment_info = detection.get_comment_info_regex("c", languages_config)
    assert.assert_not_nil(comment_info, "Should detect preprocessor comments")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "logging framework", "Should extract logging TODO")
        assert.assert_contains(content, "not suitable for production", "Should extract context")
    end
    cleanup()

    -- Test 8: Inline assembly comments
    print("  Testing inline assembly comments...")
    cleanup = setup_mock_vim({
        "void optimized_copy(void* dest, void* src, size_t n) {",
        "    // TODO: Add CPU feature detection",
        "    // Current implementation assumes SSE2 support",
        "    __asm__ volatile (",
        '        "rep movsb"',
        "        : : \"D\" (dest), \"S\" (src), \"c\" (n)",
        "        : \"memory\"",
        "    );",
        "}"
    }, {2, 4}, "c")

    comment_info = detection.get_comment_info_regex("c", languages_config)
    assert.assert_not_nil(comment_info, "Should detect assembly-related comments")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "CPU feature detection", "Should extract assembly TODO")
        assert.assert_contains(content, "SSE2 support", "Should extract CPU context")
    end
    cleanup()

    -- Test 9: Error handling comments
    print("  Testing error handling comments...")
    cleanup = setup_mock_vim({
        "int file_operation(const char* filename) {",
        "    FILE* fp = fopen(filename, \"r\");",
        "    if (!fp) {",
        "        /*",
        "         * FIXME: Improve error reporting",
        "         * Should distinguish between different error types:",
        "         * - File not found",
        "         * - Permission denied",
        "         * - Disk full",
        "         */",
        "        return -1;",
        "    }",
        "    // Process file...",
        "}"
    }, {6, 0}, "c")

    comment_info = detection.get_comment_info_regex("c", languages_config)
    assert.assert_not_nil(comment_info, "Should detect error handling comment")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Improve error reporting", "Should extract FIXME content")
        assert.assert_contains(content, "Permission denied", "Should extract specific error types")
    end
    cleanup()

    -- Test 10: Template/Generic comments (C++)
    print("  Testing C++ template comments...")
    cleanup = setup_mock_vim({
        "template<typename T>",
        "class Container {",
        "private:",
        "    T* data;",
        "    size_t capacity;",
        "    size_t size;",
        "",
        "public:",
        "    // TODO: Add move semantics support",
        "    // Current implementation only supports copy operations",
        "    Container(const Container& other) {",
        "        // Implementation...",
        "    }",
        "};"
    }, {9, 4}, "cpp")

    comment_info = detection.get_comment_info_regex("cpp", languages_config)
    assert.assert_not_nil(comment_info, "Should detect template comment")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "move semantics", "Should extract C++11+ TODO")
        assert.assert_contains(content, "copy operations", "Should extract current limitation")
    end
    cleanup()

    print("  ✅ All C/C++ detection tests completed")
end

return M
