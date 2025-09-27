-- Comprehensive TypeScript comment detection tests

local M = {
    language = "TypeScript"
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
            filetype = filetype or "typescript"
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
    
    -- Test 1: Single-line comments with TypeScript types
    print("  Testing TypeScript single-line comments...")
    local cleanup = setup_mock_vim({
        "// TODO: Add proper type definitions",
        "// The current implementation lacks strict typing",
        "interface User {",
        "    id: number;",
        "    name: string;",
        "}"
    }, {1, 0}, "typescript")
    
    local comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect TypeScript single-line comments")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 2, "Should end at line 2")
        assert.assert_equal(comment_info.lang, "typescript", "Should detect TypeScript language")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "type definitions", "Should extract TypeScript-specific content")
        assert.assert_contains(content, "strict typing", "Should extract typing context")
    end
    cleanup()
    
    -- Test 2: TSDoc comment block
    print("  Testing TSDoc comment block...")
    cleanup = setup_mock_vim({
        "/**",
        " * TODO: Improve error handling in this service",
        " * @param userId - The unique identifier for the user",
        " * @param options - Configuration options for the request",
        " * @returns Promise<User | null> - User data or null if not found",
        " * @throws {ValidationError} When userId is invalid",
        " * FIXME: This doesn't handle network timeouts properly",
        " */",
        "async function fetchUser(userId: string, options?: RequestOptions): Promise<User | null> {"
    }, {2, 0}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect TSDoc comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at line 1")
        assert.assert_equal(comment_info.end_line, 8, "Should end at line 8")
        assert.assert_equal(comment_info.style_type, "block", "Should be block style")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Improve error handling", "Should extract TODO content")
        assert.assert_contains(content, "network timeouts", "Should extract FIXME content")
        assert.assert_contains(content, "@param userId", "Should include TSDoc annotations")
    end
    cleanup()
    
    -- Test 3: Generic type comments
    print("  Testing generic type with comments...")
    cleanup = setup_mock_vim({
        "// TODO: Make this generic more flexible",
        "// Currently only works with string keys",
        "class Repository<T extends { id: string }> {",
        "    private items: Map<string, T> = new Map();",
        "",
        "    // FIXME: Add proper error handling",
        "    findById(id: string): T | undefined {",
        "        return this.items.get(id);",
        "    }",
        "}"
    }, {6, 4}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect inline comment in generic class")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 6, "Should be the FIXME comment")
        assert.assert_equal(comment_info.end_line, 6, "Should be single line")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Add proper error handling", "Should extract FIXME content")
    end
    cleanup()
    
    -- Test 4: React/JSX TypeScript component comments
    print("  Testing React TypeScript component...")
    cleanup = setup_mock_vim({
        "interface Props {",
        "    user: User;",
        "    // TODO: Add theme support",
        "    // This component should accept a theme prop",
        "    onUpdate: (user: User) => void;",
        "}",
        "",
        "// FIXME: This component re-renders too often",
        "const UserProfile: React.FC<Props> = ({ user, onUpdate }) => {"
    }, {8, 0}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect React component comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 8, "Should be the FIXME comment")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "re-renders too often", "Should extract React-specific content")
    end
    cleanup()
    
    -- Test 5: Decorator comments
    print("  Testing TypeScript decorators with comments...")
    cleanup = setup_mock_vim({
        "// TODO: Replace with proper validation library",
        "// Current validation is too basic",
        "@Entity('users')",
        "@Index(['email'], { unique: true })",
        "export class User {",
        "    @PrimaryGeneratedColumn('uuid')",
        "    id: string;",
        "",
        "    // HACK: Temporary workaround for email validation",
        "    @Column({ unique: true })",
        "    email: string;",
        "}"
    }, {9, 4}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect decorator comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 9, "Should be the HACK comment")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Temporary workaround", "Should extract HACK content")
    end
    cleanup()
    
    -- Test 6: Enum with comments
    print("  Testing TypeScript enum comments...")
    cleanup = setup_mock_vim({
        "/*",
        " * TODO: Add more granular status types",
        " * Current enum is too simple for complex workflows",
        " * REVIEW: Consider using union types instead",
        " */",
        "enum TaskStatus {",
        "    PENDING = 'pending',",
        "    IN_PROGRESS = 'in_progress',",
        "    COMPLETED = 'completed',",
        "    // TODO: Add CANCELLED status",
        "}"
    }, {3, 0}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect enum block comment")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 1, "Should start at block comment")
        assert.assert_equal(comment_info.end_line, 5, "Should end at block comment")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "granular status types", "Should extract TODO content")
        assert.assert_contains(content, "union types", "Should extract REVIEW content")
    end
    cleanup()
    
    -- Test 7: Async/await with error handling comments
    print("  Testing async TypeScript patterns...")
    cleanup = setup_mock_vim({
        "async function processData<T>(data: T[]): Promise<ProcessedData<T>[]> {",
        "    // TODO: Add proper error handling for async operations",
        "    // Current implementation doesn't handle network failures",
        "    // or timeout scenarios properly",
        "    try {",
        "        const results = await Promise.all(",
        "            data.map(item => processItem(item))",
        "        );",
        "        return results;",
        "    } catch (error) {",
        "        // FIXME: Should use proper error types",
        "        throw new Error('Processing failed');",
        "    }",
        "}"
    }, {2, 4}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect async function comments")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should start with TODO")
        assert.assert_equal(comment_info.end_line, 4, "Should include all related lines")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "async operations", "Should extract async-specific content")
        assert.assert_contains(content, "timeout scenarios", "Should extract detailed issues")
    end
    cleanup()
    
    -- Test 8: Type assertion comments
    print("  Testing type assertion comments...")
    cleanup = setup_mock_vim({
        "const apiResponse = await fetch('/api/users');",
        "// TODO: Add proper runtime type validation",
        "// Currently assuming API response structure",  
        "const users = apiResponse.json() as User[];",
        "",
        "// WARN: This type assertion is unsafe",
        "const config = (window as any).APP_CONFIG;"
    }, {2, 0}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect type assertion comments")
    if comment_info then
        assert.assert_equal(comment_info.start_line, 2, "Should start with TODO")
        assert.assert_equal(comment_info.end_line, 3, "Should include related line")
        
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "runtime type validation", "Should extract validation content")
    end
    cleanup()
    
    -- Test 9: Namespace comments
    print("  Testing TypeScript namespace...")
    cleanup = setup_mock_vim({
        "namespace Utils {",
        "    /*",
        "     * TODO: Move these utilities to separate modules",
        "     * This namespace is getting too large and should be",
        "     * split into focused utility modules",
        "     */",
        "    export function formatDate(date: Date): string {",
        "        return date.toISOString();",
        "    }",
        "}"
    }, {3, 5}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect namespace comment")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "separate modules", "Should extract refactoring TODO")
    end
    cleanup()
    
    -- Test 10: Import/export comments
    print("  Testing import/export comments...")
    cleanup = setup_mock_vim({
        "// TODO: Organize imports better",
        "// Consider using barrel exports",
        "import { User, UserRepository } from './types';",
        "import { Logger } from '../utils/logger';",
        "",
        "// FIXME: This should be a named export",
        "export default class UserService {"
    }, {1, 0}, "typescript")
    
    comment_info = detection.get_comment_info_regex("typescript", languages_config)
    assert.assert_not_nil(comment_info, "Should detect import organization comments")
    if comment_info then
        local content = detection.extract_comment_content(comment_info, config.default_config.comment_prefixes)
        assert.assert_contains(content, "Organize imports", "Should extract organization TODO")
        assert.assert_contains(content, "barrel exports", "Should extract specific suggestion")
    end
    cleanup()
    
    print("  ✅ All TypeScript detection tests completed")
end

return M