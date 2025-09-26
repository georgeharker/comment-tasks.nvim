local M = {}

M.config = {}

local curl = require("plenary.curl")

local function create_command_handler(func)
    return function(opts)
        local lang_override = opts.args and opts.args ~= "" and opts.args or nil
        func(lang_override)
    end
end

-- Helper function to create language completion function
local function create_language_completion()
    return function()
        local langs = {}
        for lang, _ in pairs(M.config.languages) do
            table.insert(langs, lang)
        end
        return langs
    end
end

-- Provider-agnostic notification functions
local function notify_info(message, provider)
    local title = provider and (provider:gsub("^%l", string.upper) .. " Tasks") or "Task Manager"
    vim.notify(message, vim.log.levels.INFO, { title = title })
end

local function notify_success(message, provider)
    local title = provider and (provider:gsub("^%l", string.upper) .. " Success") or "Task Manager"
    vim.notify("✓ " .. message, vim.log.levels.INFO, { title = title })
end

local function notify_error(message, provider)
    local title = provider and (provider:gsub("^%l", string.upper) .. " Error") or "Task Manager"
    vim.notify("✗ " .. message, vim.log.levels.ERROR, { title = title })
end

local function notify_warn(message, provider)
    local title = provider and (provider:gsub("^%l", string.upper) .. " Warning") or "Task Manager"
    vim.notify("⚠ " .. message, vim.log.levels.WARN, { title = title })
end

-- Multi-provider configuration
local config = {
    default_provider = "clickup",

    providers = {
        clickup = {
            api_key_env = "CLICKUP_API_KEY",
            list_id = nil,
            team_id = nil,
            enabled = true,
        },
        github = {
            api_key_env = "GITHUB_TOKEN",
            repo_owner = nil,
            repo_name = nil,
            enabled = false,
        },
        todoist = {
            api_key_env = "TODOIST_API_TOKEN",
            project_id = nil,
            enabled = false,
        },
    },

    comment_prefixes = {
        "TODO",
        "FIXME",
        "BUG",
        "HACK",
        "WARN",
        "PERF",
        "NOTE",
        "INFO",
        "TEST",
        "PASSED",
        "FAILED",
        "FIX",
        "ISSUE",
        "XXX",
        "OPTIMIZE",
        "REVIEW",
        "DEPRECATED",
        "REFACTOR",
        "CLEANUP",
    },

    -- Language configurations for Tree-sitter based comment detection
    languages = {
        python = {
            comment_nodes = { "comment", "string" },
            comment_styles = {
                single_line = { prefix = "# ", continue_with = "# " },
                docstring = {
                    start_markers = { '"""', "'''" },
                    end_markers = { '"""', "'''" },
                    continue_with = "", -- No prefix needed inside docstring
                },
            },
            docstring_context_nodes = { "expression_statement" }, -- For detecting docstrings vs regular strings
        },

        javascript = {
            comment_nodes = { "comment", "line_comment", "block_comment", "Comment", "multiline_comment" },
            comment_styles = {
                single_line = { prefix = "// ", continue_with = "// " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ", -- Standard block comment continuation
                },
            },
        },

        typescript = {
            comment_nodes = { "comment", "line_comment", "block_comment", "Comment", "multiline_comment" },
            comment_styles = {
                single_line = { prefix = "// ", continue_with = "// " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },

        lua = {
            comment_nodes = { "comment", "block_comment", "Comment", "line_comment" },
            comment_styles = {
                single_line = { prefix = "-- ", continue_with = "-- " },
                block = {
                    start_markers = { "--[[" },
                    end_markers = { "--]]" },
                    continue_with = "-- ", -- Continue with single-line style inside block
                },
            },
        },

        rust = {
            comment_nodes = { "line_comment", "block_comment", "doc_comment", "comment", "Comment" },
            comment_styles = {
                single_line = { prefix = "// ", continue_with = "// " },
                doc_line = { prefix = "/// ", continue_with = "/// " },
                doc_inner = { prefix = "//! ", continue_with = "//! " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },

        c = {
            comment_nodes = { "comment", "line_comment", "block_comment", "Comment", "multiline_comment" },
            comment_styles = {
                single_line = { prefix = "// ", continue_with = "// " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },

        cpp = {
            comment_nodes = { "comment", "line_comment", "block_comment", "Comment", "multiline_comment" },
            comment_styles = {
                single_line = { prefix = "// ", continue_with = "// " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },

        go = {
            comment_nodes = { "comment", "line_comment", "block_comment", "Comment", "multiline_comment" },
            comment_styles = {
                single_line = { prefix = "// ", continue_with = "// " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },

        java = {
            comment_nodes = { "comment", "line_comment", "block_comment", "javadoc_comment", "Comment", "multiline_comment" },
            comment_styles = {
                single_line = { prefix = "// ", continue_with = "// " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
                javadoc = {
                    start_markers = { "/**" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },

        ruby = {
            comment_nodes = { "comment", "Comment", "line_comment" },
            comment_styles = {
                single_line = { prefix = "# ", continue_with = "# " },
            },
        },

        php = {
            comment_nodes = { "comment", "shell_comment", "Comment", "line_comment", "block_comment" },
            comment_styles = {
                single_line_slash = { prefix = "// ", continue_with = "// " },
                single_line_hash = { prefix = "# ", continue_with = "# " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },

        css = {
            comment_nodes = { "comment", "Comment", "block_comment" },
            comment_styles = {
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },

        html = {
            comment_nodes = { "comment", "Comment", "html_comment" },
            comment_styles = {
                block = {
                    start_markers = { "<!--" },
                    end_markers = { "-->" },
                    continue_with = "  ", -- Just indent, no special prefix
                },
            },
        },

        bash = {
            comment_nodes = { "comment", "Comment", "line_comment" },
            comment_styles = {
                single_line = { prefix = "# ", continue_with = "# " },
            },
        },

        sh = {
            comment_nodes = { "comment", "Comment", "line_comment" },
            comment_styles = {
                single_line = { prefix = "# ", continue_with = "# " },
            },
        },

        vim = {
            comment_nodes = { "comment", "Comment", "line_comment" },
            comment_styles = {
                single_line = { prefix = '" ', continue_with = '" ' },
            },
        },

        yaml = {
            comment_nodes = { "comment", "Comment", "line_comment" },
            comment_styles = {
                single_line = { prefix = "# ", continue_with = "# " },
            },
        },

        json = {
            comment_nodes = { "comment", "Comment", "line_comment", "block_comment" },
            comment_styles = {
                single_line = { prefix = "// ", continue_with = "// " },
                block = {
                    start_markers = { "/*" },
                    end_markers = { "*/" },
                    continue_with = " * ",
                },
            },
        },
    },

    -- Fallback to regex patterns if Tree-sitter is unavailable
    fallback_to_regex = true,
}

-- Language support functions

-- Function to check if current buffer language is supported
local function is_supported_language(lang_override)
    local lang = lang_override or vim.bo.filetype
    return config.languages[lang] ~= nil
end

-- Helper function to check language support and notify if unsupported
local function check_language_supported(lang_override, provider)
    if not is_supported_language(lang_override) then
        local lang = lang_override or vim.bo.filetype
        notify_warn("Language '" .. lang .. "' is not supported", provider)
        return false
    end
    return true
end

-- Tree-sitter based comment detection functions

local function determine_comment_style(lines, lang_config)
    if not lines or #lines == 0 or not lang_config then
        return nil
    end

    local first_line = lines[1]
    local last_line = lines[#lines]
    local is_multiline = #lines > 1

    -- Check each comment style to see which one matches
    for style_name, style_config in pairs(lang_config.comment_styles) do
        if style_config.start_markers and style_config.end_markers then
            -- Block comment style
            for _, start_marker in ipairs(style_config.start_markers) do
                for _, end_marker in ipairs(style_config.end_markers) do
                    local has_start = first_line:find(start_marker, 1, true)
                    local has_end = last_line:find(end_marker, 1, true)

                    if has_start and has_end then
                        -- Check if this is truly a block comment or could be single-line
                        if is_multiline or (first_line ~= last_line) then
                            return style_name
                        else
                            -- Single line with block markers - still consider it block style
                            -- but we'll handle URL insertion differently
                            return style_name
                        end
                    end
                end
            end
        elseif style_config.prefix then
            -- Single-line comment style
            if first_line:match("^%s*" .. vim.pesc(style_config.prefix)) then
                return style_name
            end
        end
    end

    -- Default fallback
    for style_name, _ in pairs(lang_config.comment_styles) do
        return style_name -- Return first available style
    end

    return nil
end
local function get_comment_info_treesitter(lang_override)
    local lang = lang_override or vim.bo.filetype
    local lang_config = config.languages[lang]


    if not lang_config then
        return nil -- Unsupported language
    end

    -- Check if Tree-sitter is available and parser exists
    local parser, tree, root
    local success = pcall(function()
        parser = vim.treesitter.get_parser(0, lang)
        if not parser then
            error("No parser")
        end

        local trees = parser:parse()
        tree = trees and trees[1]
        if not tree then
            error("No parse tree")
        end

        root = tree:root()
        if not root then
            error("No root node")
        end
    end)

    if not success or not parser or not tree or not root then
        return nil -- Fallback to regex
    end

    local cursor = vim.api.nvim_win_get_cursor(0)

    -- Simple approach: check all nodes in the tree for comment types
    -- This is more reliable than trying to find node at exact cursor position
    local cursor_row = cursor[1] - 1
    local comment_nodes = {}


    -- Traverse the entire tree looking for comment nodes
    local function collect_comment_nodes(node)
        if not node then return end

        local node_type = node:type()

        if vim.tbl_contains(lang_config.comment_nodes, node_type) then
            local start_row, _start_col, end_row, _end_col = node:range()

            -- Check if cursor is within this node's range
            if cursor_row >= start_row and cursor_row <= end_row then
                table.insert(comment_nodes, {
                    node = node,
                    start_row = start_row,
                    end_row = end_row,
                    type = node_type
                })
            end
        end

        -- Recursively check children
        for child in node:iter_children() do
            collect_comment_nodes(child)
        end
    end

    local ok, _error_msg = pcall(collect_comment_nodes, root)
    if not ok then
        return nil -- Tree traversal failed, fallback to regex
    end

    -- Find the most specific (smallest) comment node that contains the cursor
    local comment_node = nil
    local best_range = nil

    for _, node_info in ipairs(comment_nodes) do
        local range_size = node_info.end_row - node_info.start_row
        if not best_range or range_size < best_range then
            comment_node = node_info.node
            best_range = range_size
        end
    end


    if not comment_node then
        return nil
    end

    -- Special handling for Python docstrings
    if lang == "python" and comment_node:type() == "string" then
        local parent = comment_node:parent()
        if not (parent and vim.tbl_contains(lang_config.docstring_context_nodes or {}, parent:type())) then
            return nil -- This is a regular string, not a docstring
        end
    end

    -- Get comment boundaries and content
    local start_row, _start_col, end_row, _end_col = comment_node:range()
    local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)


    -- For single-line comments, extend to find consecutive comment lines
    local extended_start = start_row
    local extended_end = end_row

    -- Check if this is a single-line comment that might be part of a block
    local style_type = determine_comment_style(lines, lang_config)

    local style_config = lang_config.comment_styles[style_type]

    if style_config and style_config.prefix and not style_config.start_markers then
        -- This is a single-line comment, check for consecutive lines
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local prefix_pattern = "^%s*" .. vim.pesc(style_config.prefix)

        -- Extend backwards
        for i = start_row, 1, -1 do
            if buf_lines[i] and buf_lines[i]:match(prefix_pattern) then
                extended_start = i - 1
            else
                break
            end
        end

        -- Extend forwards
        for i = end_row + 2, #buf_lines do
            if buf_lines[i] and buf_lines[i]:match(prefix_pattern) then
                extended_end = i - 1
            else
                break
            end
        end

        -- Get extended lines if we found more
        if extended_start ~= start_row or extended_end ~= end_row then
            -- Reassign lines to include extended range
            lines = vim.api.nvim_buf_get_lines(0, extended_start, extended_end + 1, false)
            start_row = extended_start
            end_row = extended_end
        end
    end


    return {
        node = comment_node,
        start_line = start_row + 1,
        end_line = end_row + 1,
        lines = lines,
        style_type = style_type,
        lang_config = lang_config,
        is_comment = true,
        lang = lang,
    }

end

-- Fallback regex-based comment detection (enhanced version of original)
local function get_comment_info_regex(lang_override)
    local lang = lang_override or vim.bo.filetype
    local lang_config = config.languages[lang]

    if not lang_config then
        print("DEBUG: No lines extracted")
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1]
    local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    if line_num > #buf_lines then
        return nil
    end

    local current_line = buf_lines[line_num]
    local block_start = line_num
    local block_end = line_num
    local style_type = nil

    -- Check each comment style
    for style_name, style_config in pairs(lang_config.comment_styles) do
        if style_config.start_markers and style_config.end_markers then
            -- Block comment detection - check if we're inside a block comment

            for _, start_marker in ipairs(style_config.start_markers) do
                for _, end_marker in ipairs(style_config.end_markers) do

                    -- Strategy: Search backwards for start marker, forwards for end marker
                    local start_found = nil
                    local end_found = nil

                    -- Search backwards for start marker
                    for i = line_num, 1, -1 do
                        if buf_lines[i]:find(start_marker, 1, true) then
                            start_found = i
                            break
                        end
                    end

                    -- Search forwards for end marker (from current line)
                    for i = line_num, #buf_lines do
                        if buf_lines[i]:find(end_marker, 1, true) then
                            end_found = i
                            break
                        end
                    end

                    -- If we found both markers and we're between them, this is our block
                    if start_found and end_found and start_found <= line_num and line_num <= end_found then
                        style_type = style_name
                        block_start = start_found
                        block_end = end_found
                        goto found_style
                    end
                end
            end
        elseif style_config.prefix then
            -- Single-line comment detection
            local prefix_pattern = "^%s*" .. vim.pesc(style_config.prefix)
            if current_line:match(prefix_pattern) then
                style_type = style_name

                -- Find start of consecutive comments
                for i = line_num - 1, 1, -1 do
                    if buf_lines[i] and buf_lines[i]:match(prefix_pattern) then
                        block_start = i
                    else
                        break
                    end
                end

                -- Find end of consecutive comments
                for i = line_num + 1, #buf_lines do
                    if buf_lines[i] and buf_lines[i]:match(prefix_pattern) then
                        block_end = i
                    else
                        break
                    end
                end

                goto found_style
            end
        end
    end

    ::found_style::

    if not style_type then
        return nil
    end

    local lines = {}
    for i = block_start, block_end do
        table.insert(lines, buf_lines[i])
    end

    return {
        start_line = block_start,
        end_line = block_end,
        lines = lines,
        style_type = style_type,
        lang_config = lang_config,
        is_comment = true,
        lang = lang,
    }
end

local function get_comment_info(lang_override)
    local _lang = lang_override or vim.bo.filetype

    -- Try Tree-sitter first
    local ts_result = get_comment_info_treesitter(lang_override)
    if ts_result then
        -- Debug: notify which method was used (can be disabled)
        return ts_result
    end

    -- Fallback to regex if Tree-sitter fails or fallback is enabled
    if config.fallback_to_regex then
        -- Debug: notify fallback
        return get_comment_info_regex(lang_override)
    end

    -- If we get here, Tree-sitter failed and fallback is disabled
    return nil
end

local function trim_comment_prefixes(text)
    if not text or text == "" then
        return text
    end

    -- Use configurable comment prefixes
    local prefixes = config.comment_prefixes

    -- Try to match and remove prefixes (case-insensitive, with optional colon and whitespace)
    for _, prefix in ipairs(prefixes) do
        -- Create case-insensitive pattern by trying both upper and lower case
        local patterns = {
            "^%s*" .. prefix:upper() .. ":?%s*(.*)",
            "^%s*" .. prefix:lower() .. ":?%s*(.*)",
            "^%s*" .. prefix:sub(1, 1):upper() .. prefix:sub(2):lower() .. ":?%s*(.*)",
        }

        for _, pattern in ipairs(patterns) do
            local content = text:match(pattern)
            if content then
                return content:gsub("^%s+", ""):gsub("%s+$", "")
            end
        end
    end

    -- If no prefix found, return original text
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

-- Generalized comment content extraction
local function extract_comment_content_generic(comment_info)
    if not comment_info or not comment_info.is_comment then
        return ""
    end

    local content_parts = {}
    local style_config = comment_info.lang_config.comment_styles[comment_info.style_type]

    if not style_config then
        return ""
    end

    if style_config.prefix then
        -- Single-line comment style
        local prefix_pattern = "^%s*" .. vim.pesc(style_config.prefix) .. "(.*)"
        for _, line in ipairs(comment_info.lines) do
            local content = line:match(prefix_pattern)
            if content then
                content = trim_comment_prefixes(content)
                if content and content ~= "" then
                    table.insert(content_parts, content)
                end
            end
        end
    elseif style_config.start_markers and style_config.end_markers then
        -- Block comment style
        local combined_lines = table.concat(comment_info.lines, " ")

        -- Remove start and end markers
        for _, start_marker in ipairs(style_config.start_markers) do
            combined_lines = combined_lines:gsub(vim.pesc(start_marker), "")
        end
        for _, end_marker in ipairs(style_config.end_markers) do
            combined_lines = combined_lines:gsub(vim.pesc(end_marker), "")
        end

        -- Remove continuation prefixes if present
        if style_config.continue_with and style_config.continue_with ~= "" then
            local continue_pattern = vim.pesc(style_config.continue_with)
            combined_lines = combined_lines:gsub(continue_pattern, " ")
        end

        -- Clean up and trim prefixes
        local content = combined_lines:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
        content = trim_comment_prefixes(content)
        if content and content ~= "" then
            table.insert(content_parts, content)
        end
    end

    return table.concat(content_parts, " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function extend_comment_with_url(comment_info, task_url)
    if not comment_info or not comment_info.is_comment then
        return false
    end

    local style_config = comment_info.lang_config.comment_styles[comment_info.style_type]
    if not style_config then
        return false
    end

    if style_config.start_markers and style_config.end_markers then
        -- Block comment handling
        local end_line_1based = comment_info.end_line
        local end_line_0based = end_line_1based - 1

        -- Check if this is a single-line block comment
        local is_single_line = (comment_info.start_line == comment_info.end_line)

        if is_single_line then
            -- Single-line block comment: insert URL before closing marker on same line
            local line = vim.api.nvim_buf_get_lines(0, end_line_0based, end_line_0based + 1, false)[1]

            -- Find the closing marker(s) and insert URL before them
            local modified_line = line
            for _, end_marker in ipairs(style_config.end_markers) do
                local marker_pos = modified_line:find(end_marker, 1, true)
                if marker_pos then
                    -- Insert URL before the closing marker
                    local before_marker = modified_line:sub(1, marker_pos - 1)
                    local after_marker = modified_line:sub(marker_pos)
                    modified_line = before_marker .. " " .. task_url .. " " .. after_marker
                    break
                end
            end

            -- Replace the line
            vim.api.nvim_buf_set_lines(0, end_line_0based, end_line_0based + 1, false, { modified_line })
            return true
        end

        -- Get the configured continuation pattern for this language/style
        local continuation = style_config.continue_with or ""

        -- Create URL line with language-specific continuation pattern
        local url_line = continuation .. task_url

        -- Multi-line block comment: Insert URL line before the end marker line
        vim.api.nvim_buf_set_lines(0, end_line_0based, end_line_0based, false, { url_line })

        return true
    elseif style_config.continue_with then
        -- Single-line style - preserve indentation
        -- Get indentation from the last line of the comment
        local last_line_idx = comment_info.end_line - 1
        local last_line = vim.api.nvim_buf_get_lines(0, last_line_idx, last_line_idx + 1, false)[1]

        if last_line then
            local indentation = last_line:match("^(%s*)")
            local new_line = indentation .. style_config.continue_with .. task_url
            vim.api.nvim_buf_set_lines(0, comment_info.end_line, comment_info.end_line, false, { new_line })
        else
            -- Fallback to no indentation
            local new_line = style_config.continue_with .. task_url
            vim.api.nvim_buf_set_lines(0, comment_info.end_line, comment_info.end_line, false, { new_line })
        end

        return true
    end

    return false
end

-- URL extraction functions

-- Function to extract ClickUp task URL from comment
local function extract_clickup_url(line)
    local url = line:match("(https://app%.clickup%.com/t/[%w%-]+)")
    return url
end

-- Function to extract GitHub issue URL from comment
local function extract_github_url(line)
    local url = line:match("(https://github%.com/[%w%-_%.]+/[%w%-_%.]+/issues/[0-9]+)")
    return url
end

-- Function to extract Todoist task URL from comment
local function extract_todoist_url(line)
    local url = line:match("(https://todoist%.com/showTask%?id=[0-9]+)")
    return url
end

-- Generic function to extract any supported task URL
local function extract_task_url(line)
    return extract_clickup_url(line) or
           extract_github_url(line) or
           extract_todoist_url(line)
end

-- Function to check if comment already contains ClickUp URL (generalized)
local function comment_has_url(comment_info)
    if not comment_info or not comment_info.is_comment then
        return false
    end

    -- Check all lines for any task URL
    for _, line in ipairs(comment_info.lines) do
        if extract_task_url(line) then
            return true
        end
    end

    return false
end

-- Function to get task details with custom fields
local function get_task_with_custom_fields(task_id, callback)
    local api_key = vim.fn.getenv(config.providers.clickup.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "ClickUp API key not found in environment variable: " .. config.providers.clickup.api_key_env)
        return
    end

    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id .. "?include_subtasks=false"

    curl.request({
        url = api_url,
        method = "get",
        headers = {
            accept = "application/json",
            Authorization = api_key,
        },
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                callback(response, nil)
            end)
        end,
    })
end

-- GitHub API Functions

local function create_github_issue(task_name, filename, callback)
    local api_key = vim.fn.getenv(config.providers.github.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "GitHub API key not found in environment variable: " .. config.providers.github.api_key_env)
        return
    end

    if not config.providers.github.repo_owner or not config.providers.github.repo_name then
        callback(nil, "GitHub repo_owner and repo_name not configured")
        return
    end

    -- Prepare issue data
    local body = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        body = body .. " in " .. filename .. "\n\n**Source Files:**\n- " .. filename
    end

    local issue_data = {
        title = task_name,
        body = body,
        labels = {"task", "from-neovim"}
    }

    local json_data = vim.fn.json_encode(issue_data)
    local api_url = "https://api.github.com/repos/" ..
                   config.providers.github.repo_owner .. "/" ..
                   config.providers.github.repo_name .. "/issues"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            accept = "application/vnd.github+json",
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            ["X-GitHub-Api-Version"] = "2022-11-28",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 201 then
                    callback(
                        nil,
                        "GitHub API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.html_url then
                    callback(response.html_url, nil)
                else
                    callback(nil, "No issue URL in response")
                end
            end)
        end,
    })
end

local function update_github_issue_status(issue_number, is_closed, callback)
    local api_key = vim.fn.getenv(config.providers.github.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "GitHub API key not found in environment variable: " .. config.providers.github.api_key_env)
        return
    end

    if not config.providers.github.repo_owner or not config.providers.github.repo_name then
        callback(nil, "GitHub repo_owner and repo_name not configured")
        return
    end

    local issue_data = {
        state = is_closed and "closed" or "open"
    }

    local json_data = vim.fn.json_encode(issue_data)
    local api_url = "https://api.github.com/repos/" ..
                   config.providers.github.repo_owner .. "/" ..
                   config.providers.github.repo_name .. "/issues/" .. issue_number

    curl.request({
        url = api_url,
        method = "patch",
        headers = {
            accept = "application/vnd.github+json",
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            ["X-GitHub-Api-Version"] = "2022-11-28",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "GitHub API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, _response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

local function add_files_to_github_issue(issue_number, files, callback)
    local api_key = vim.fn.getenv(config.providers.github.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "GitHub API key not found in environment variable: " .. config.providers.github.api_key_env)
        return
    end

    if not config.providers.github.repo_owner or not config.providers.github.repo_name then
        callback(nil, "GitHub repo_owner and repo_name not configured")
        return
    end

    -- Get current issue to append to existing body
    local get_url = "https://api.github.com/repos/" ..
                   config.providers.github.repo_owner .. "/" ..
                   config.providers.github.repo_name .. "/issues/" .. issue_number

    curl.request({
        url = get_url,
        method = "get",
        headers = {
            accept = "application/vnd.github+json",
            Authorization = "Bearer " .. api_key,
            ["X-GitHub-Api-Version"] = "2022-11-28",
        },
        callback = function(get_result)
            vim.schedule(function()
                if get_result.status ~= 200 then
                    callback(nil, "Failed to get current issue")
                    return
                end

                local success, issue = pcall(vim.fn.json_decode, get_result.body)
                if not success then
                    callback(nil, "Failed to parse issue JSON")
                    return
                end

                -- Append files to issue body
                local updated_body = issue.body or ""
                local files_section = "\n\n**Source Files:**\n"
                for _, file in ipairs(files) do
                    files_section = files_section .. "- " .. file .. "\n"
                end

                -- Check if files section already exists and update/append accordingly
                if updated_body:match("%*%*Source Files:%*%*") then
                    -- Replace existing files section
                    updated_body = updated_body:gsub("\n%*%*Source Files:%*%*.-\n", files_section)
                else
                    -- Append new files section
                    updated_body = updated_body .. files_section
                end

                local update_data = { body = updated_body }
                local json_data = vim.fn.json_encode(update_data)

                curl.request({
                    url = get_url,
                    method = "patch",
                    headers = {
                        accept = "application/vnd.github+json",
                        Authorization = "Bearer " .. api_key,
                        ["Content-Type"] = "application/json",
                        ["X-GitHub-Api-Version"] = "2022-11-28",
                    },
                    body = json_data,
                    callback = function(update_result)
                        vim.schedule(function()
                            if update_result.status ~= 200 then
                                callback(nil, "Failed to update issue with files")
                                return
                            end
                            callback(true, nil)
                        end)
                    end,
                })
            end)
        end,
    })
end

-- Todoist API Functions

local function create_todoist_task(task_name, filename, callback)
    local api_key = vim.fn.getenv(config.providers.todoist.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "Todoist API key not found in environment variable: " .. config.providers.todoist.api_key_env)
        return
    end

    -- Prepare task data
    local content = task_name
    local description = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        description = description .. " in " .. filename .. "\n\nSource Files:\n- " .. filename
    end

    local task_data = {
        content = content,
        description = description
    }

    if config.providers.todoist.project_id then
        task_data.project_id = config.providers.todoist.project_id
    end

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.todoist.com/rest/v2/tasks"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "Todoist API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.id then
                    local task_url = "https://todoist.com/showTask?id=" .. response.id
                    callback(task_url, nil)
                else
                    callback(nil, "No task ID in response")
                end
            end)
        end,
    })
end

local function close_todoist_task(task_id, callback)
    local api_key = vim.fn.getenv(config.providers.todoist.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "Todoist API key not found in environment variable: " .. config.providers.todoist.api_key_env)
        return
    end

    local api_url = "https://api.todoist.com/rest/v2/tasks/" .. task_id .. "/close"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
        },
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 204 then
                    callback(
                        nil,
                        "Todoist API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

local function add_files_to_todoist_task(task_id, files, callback)
    local api_key = vim.fn.getenv(config.providers.todoist.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "Todoist API key not found in environment variable: " .. config.providers.todoist.api_key_env)
        return
    end

    -- Get current task to append to existing description
    local get_url = "https://api.todoist.com/rest/v2/tasks/" .. task_id

    curl.request({
        url = get_url,
        method = "get",
        headers = {
            Authorization = "Bearer " .. api_key,
        },
        callback = function(get_result)
            vim.schedule(function()
                if get_result.status ~= 200 then
                    callback(nil, "Failed to get current task")
                    return
                end

                local success, task = pcall(vim.fn.json_decode, get_result.body)
                if not success then
                    callback(nil, "Failed to parse task JSON")
                    return
                end

                -- Append files to task description
                local updated_description = task.description or ""
                local files_section = "\n\nSource Files:\n"
                for _, file in ipairs(files) do
                    files_section = files_section .. "- " .. file .. "\n"
                end

                -- Check if files section already exists and update/append accordingly
                if updated_description:match("Source Files:") then
                    -- Replace existing files section
                    updated_description = updated_description:gsub("\nSource Files:.-$", files_section)
                else
                    -- Append new files section
                    updated_description = updated_description .. files_section
                end

                local update_data = { description = updated_description }
                local json_data = vim.fn.json_encode(update_data)

                curl.request({
                    url = get_url,
                    method = "post",
                    headers = {
                        Authorization = "Bearer " .. api_key,
                        ["Content-Type"] = "application/json",
                    },
                    body = json_data,
                    callback = function(update_result)
                        vim.schedule(function()
                            if update_result.status ~= 200 then
                                callback(nil, "Failed to update task with files")
                                return
                            end
                            callback(true, nil)
                        end)
                    end,
                })
            end)
        end,
    })
end

-- ClickUp API Functions (status updates)

local function update_clickup_task_status(task_id, status, callback)
    local api_key = vim.fn.getenv(config.providers.clickup.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "ClickUp API key not found in environment variable: " .. config.providers.clickup.api_key_env)
        return
    end

    -- Prepare API request data
    local task_data = {
        status = status,
    }

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id

    -- Execute API request using plenary curl
    curl.request({
        url = api_url,
        method = "put",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

-- Generic task status update functions

local function update_task_status_generic(task_identifier, provider, status, callback)
    if provider == "clickup" then
        update_clickup_task_status(task_identifier, status, callback)
    elseif provider == "github" then
        -- GitHub only supports open/closed
        local is_closed = (status == "complete" or status == "closed")
        update_github_issue_status(task_identifier, is_closed, callback)
    elseif provider == "todoist" then
        -- Todoist only supports close operation
        if status == "complete" or status == "closed" then
            close_todoist_task(task_identifier, callback)
        else
            callback(nil, "Todoist only supports closing tasks")
        end
    else
        callback(nil, "Unsupported provider: " .. provider)
    end
end

local function add_file_to_task_generic(task_identifier, provider, filename, callback)
    if provider == "clickup" then
        -- For ClickUp, we need to get and update the SourceFiles custom field
        -- This is handled in the existing add_file_to_task_sources function
        callback(nil, "Use add_file_to_task_sources for ClickUp")
    elseif provider == "github" then
        add_files_to_github_issue(task_identifier, {filename}, callback)
    elseif provider == "todoist" then
        add_files_to_todoist_task(task_identifier, {filename}, callback)
    else
        callback(nil, "Unsupported provider: " .. provider)
    end
end

-- Alternative function to set custom field using dedicated endpoint
local function set_custom_field_value(task_id, field_id, field_value, callback)
    local api_key = vim.fn.getenv(config.providers.clickup.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "ClickUp API key not found in environment variable: " .. config.providers.clickup.api_key_env)
        return
    end

    local field_data = {
        value = field_value,
    }

    local json_data = vim.fn.json_encode(field_data)
    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id .. "/field/" .. field_id

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "Custom field API request failed with status: "
                        .. result.status
                    if result.body then
                        local success, parsed_error = pcall(vim.fn.json_decode, result.body)
                        if success and parsed_error and parsed_error.err then
                            error_msg = error_msg .. " - " .. parsed_error.err
                        else
                            error_msg = error_msg .. " - " .. result.body
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                local success, _response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse custom field response")
                    return
                end

                callback(true, nil)
            end)
        end
    })
end

-- Helper function to update custom field by ID
local function update_custom_field_by_id(task_id, field_id, field_value, callback)
    local api_key = vim.fn.getenv(config.providers.clickup.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "ClickUp API key not found in environment variable: " .. config.providers.clickup.api_key_env)
        return
    end

    -- Update custom field using field ID
    local custom_fields = {
        [field_id] = {
            value = field_value,
        },
    }

    local task_data = {
        custom_fields = custom_fields,
    }

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id

    -- Debug: Log the API request (uncomment for debugging)
    -- vim.notify("Updating field " .. field_id .. " with value: " .. field_value, vim.log.levels.DEBUG)
    -- vim.notify("API URL: " .. api_url, vim.log.levels.DEBUG)
    -- vim.notify("JSON data: " .. json_data, vim.log.levels.DEBUG)

    curl.request({
        url = api_url,
        method = "put",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "API request failed with status: " .. result.status
                    if result.body then
                        local success, parsed_error = pcall(vim.fn.json_decode, result.body)
                        if success and parsed_error and parsed_error.err then
                            error_msg = error_msg .. " - " .. parsed_error.err
                        else
                            error_msg = error_msg .. " - " .. result.body
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                -- Check if custom fields were actually updated
                if response and response.custom_fields then
                    vim.notify("Custom field updated successfully", vim.log.levels.TRACE)
                end

                callback(true, nil)
            end)
        end,
    })
end

-- Function to update custom fields (specifically SourceFiles)
local function update_task_custom_field(task_id, field_name, field_value, callback)
    -- First, get the task to find the custom field ID
    get_task_with_custom_fields(task_id, function(task_data, get_error)
        if get_error then
            callback(nil, "Failed to get task details: " .. get_error)
            return
        end

        -- Find the custom field ID for the given field name
        local field_id = nil
        if task_data.custom_fields then
            for _, field in ipairs(task_data.custom_fields) do
                if field.name == field_name then
                    field_id = field.id
                    break
                end
            end
        end

        if not field_id then
            callback(nil, "Custom field '" .. field_name .. "' not found in task")
            return
        end

        -- Now update the custom field using the field ID
        -- Try the dedicated custom field endpoint first
        set_custom_field_value(task_id, field_id, field_value, function(success, _error)
            if success then
                callback(true, nil)
            else
                -- If dedicated endpoint fails, try the general task update method
                vim.notify(
                    "Dedicated field endpoint failed, trying task update method",
                    vim.log.levels.TRACE
                )
                update_custom_field_by_id(task_id, field_id, field_value, callback)
            end
        end)
    end)
end

local function create_clickup_task(task_name, filename, callback)
    local api_key = vim.fn.getenv(config.providers.clickup.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "ClickUp API key not found in environment variable: " .. config.providers.clickup.api_key_env)
        return
    end

    if not config.providers.clickup.list_id then
        callback(nil, "ClickUp list_id not configured")
        return
    end

    -- Prepare API request data
    local description = "Created from Neovim comment"
    if filename and filename ~= "" then
        description = description .. " in " .. filename
    end

    local task_data = {
        name = task_name,
        description = description,
        status = "to do",
    }

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.clickup.com/api/v2/list/" .. config.providers.clickup.list_id .. "/task"

    -- Execute API request using plenary curl
    curl.request({
        url = api_url,
        method = "post",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                if response.id then
                    local task_url = "https://app.clickup.com/t/" .. response.id

                    -- Also set the SourceFiles custom field if filename is provided
                    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
                        update_task_custom_field(
                            response.id,
                            "SourceFiles",
                            filename,
                            function(_field_success, field_error)
                                if field_error then
                                    -- Don't fail the whole operation, just warn
                                    vim.notify(
                                        "Warning: Could not set SourceFiles field: " .. field_error,
                                        vim.log.levels.WARN
                                    )
                                end
                                callback(task_url, nil)
                            end
                        )
                    else
                        callback(task_url, nil)
                    end
                else
                    callback(nil, "No task ID in response")
                end
            end)
        end,
    })
end

-- Function to get all tasks in a team with custom fields
local function get_team_tasks_with_custom_fields(callback)
    local api_key = vim.fn.getenv(config.providers.clickup.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "ClickUp API key not found in environment variable: " .. config.providers.clickup.api_key_env)
        return
    end

    if not config.providers.clickup.list_id then
        callback(nil, "ClickUp list_id not configured")
        return
    end

    -- Use list endpoint to get tasks with custom fields
    local api_url = "https://api.clickup.com/api/v2/list/"
        .. config.providers.clickup.list_id
        .. "/task?include_closed=true"

    curl.request({
        url = api_url,
        method = "get",
        headers = {
            accept = "application/json",
            Authorization = api_key,
        },
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                callback(response.tasks or {}, nil)
            end)
        end,
    })
end

local function update_task_description(task_id, description, callback)
    local api_key = vim.fn.getenv(config.providers.clickup.api_key_env)
    if not api_key or api_key == vim.NIL then
        callback(nil, "ClickUp API key not found in environment variable: " .. config.providers.clickup.api_key_env)
        return
    end

    local task_data = {
        description = description,
    }

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id

    curl.request({
        url = api_url,
        method = "put",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

local function has_filename_reference(description)
    if not description or description == "" then
        return false
    end
    -- Check for common filename patterns: .py, .js, .ts, .lua, etc.
    return description:match("[%w_%-/]+%.[a-zA-Z0-9]+") ~= nil
end

local function has_source_files_field(task)
    if not task or not task.custom_fields then
        return false
    end

    for _, field in ipairs(task.custom_fields) do
        if
            field.name == "SourceFiles"
            and field.value
            and field.value ~= ""
            and field.value:match("%S")
        then
            return true
        end
    end

    return false
end

-- Function to get SourceFiles value from task
local function get_source_files_value(task)
    if not task or not task.custom_fields then
        return nil
    end

    for _, field in ipairs(task.custom_fields) do
        if field.name == "SourceFiles" then
            return field.value
        end
    end

    return nil
end
local function task_has_filename_reference(task)
    -- Only check SourceFiles custom field - we want to update tasks with file references
    -- in description but no SourceFiles field
    return has_source_files_field(task)
end

local function task_needs_sourcefile_update(task)
    -- Task needs update if it has filename references in description but no SourceFiles field
    return has_filename_reference(task.description) and not has_source_files_field(task)
end

local function extract_file_references(description)
    if not description or description == "" then
        return {}
    end

    local files = {}
    -- Match file patterns like: word.ext, path/file.ext, ./file.ext
    -- More specific pattern that avoids URLs but catches file paths
    for file in description:gmatch("([%w_%-/%.]+%.[a-zA-Z0-9]+)") do
        -- Skip if it looks like a URL (contains ://)
        if not file:match("://") and not file:match("%.?venv") then
            -- Clean up the match and add to results
            local clean_file = file:gsub("^[%s%.]+", ""):gsub("[%s%.]+$", "")
            if clean_file ~= "" and #clean_file > 3 then -- Basic sanity check for meaningful filenames
                table.insert(files, clean_file)
            end
        end
    end

    return files
end

local function strip_filenames_from_description(description, filenames_to_remove)
    if
        not description
        or description == ""
        or not filenames_to_remove
        or #filenames_to_remove == 0
    then
        return description
    end

    local updated_description = description

    for _, filename in ipairs(filenames_to_remove) do
        -- Escape special regex characters in filename
        local escaped_filename = filename:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")

        -- Remove the filename with optional surrounding whitespace and punctuation
        -- This handles cases like "Fix bug in database.py" -> "Fix bug in"
        -- Use gsub to replace all occurrences
        updated_description = updated_description:gsub("%f[%w]" .. escaped_filename .. "%f[%W]", "")
        updated_description = updated_description:gsub(escaped_filename, "") -- Fallback for edge cases

        -- Clean up extra whitespace and punctuation that might be left behind
        updated_description = updated_description:gsub("%s+", " ") -- Multiple spaces to single
        updated_description = updated_description:gsub("%s+%.%s*$", ".") -- Fix trailing dots
        updated_description = updated_description:gsub("%s+,%s*$", "") -- Remove trailing commas
        updated_description = updated_description:gsub("%s+in%s*$", "") -- Remove trailing "in"
        updated_description = updated_description:gsub("%s+for%s*$", "") -- Remove trailing "for"
        updated_description = updated_description:gsub("%s+and%s*$", "") -- Remove trailing "and"
        updated_description = updated_description:gsub("^%s+", ""):gsub("%s+$", "") -- Trim
    end

    return updated_description
end

-- Function to normalize file paths and remove duplicates
local function normalize_and_dedupe_files(files)
    if not files or #files == 0 then
        return {}
    end

    local normalized_set = {}
    local result = {}

    -- Function to check if path should be filtered out
    local function should_filter(path)
        -- Filter out .venv directories and related patterns
        return path:match("%.?venv")
            or path:match("__pycache__")
            or path:match("%.pyc$")
            or path:match("%.pyo$")
            or path:match("node_modules")
            or path:match("%.git/")
            or path:match("%.DS_Store")
            or path:match("%.egg%-info")
            or path:match("dist/")
            or path:match("build/")
            or path:match("%.tox/")
            or path:match("coverage/")
            or path:match("%.pytest_cache")
            or path:match("%.mypy_cache")
    end
    for _, file in ipairs(files) do
        if file and file ~= "" and not file:match("^%s*$") then
            -- Normalize the path: remove leading ./ and multiple slashes
            local normalized = file:gsub("^%s+", "")
                :gsub("%s+$", "")
                :gsub("^%./", "")
                :gsub("//+", "/")
                :gsub("/$", "")

            -- Skip empty paths, filtered paths, and duplicates
            if
                normalized ~= ""
                and not should_filter(normalized)
                and not normalized_set[normalized]
            then
                normalized_set[normalized] = true
                table.insert(result, normalized)
            end
        end
    end

    -- Sort for consistent ordering
    table.sort(result)
    return result
end

-- Function to validate and clean existing SourceFiles content
local function validate_and_clean_source_files(source_files_content)
    if not source_files_content or source_files_content == "" then
        return {}
    end

    local files = {}
    for file in source_files_content:gmatch("[^\r\n]+") do
        local trimmed = file:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then
            table.insert(files, trimmed)
        end
    end

    return normalize_and_dedupe_files(files)
end

-- Function to search for files mentioned in task description
local function search_files_in_description(task, callback)
    local file_refs = extract_file_references(task.description)

    if #file_refs == 0 then
        callback({}, nil)
        return
    end

    local found_files = {}
    local checked_files = 0
    local total_files = #file_refs

    -- Helper function to check completion
    local function check_completion()
        if checked_files >= total_files then
            callback(found_files, nil)
        end
    end

    -- Search for each file reference
    for _, file_ref in ipairs(file_refs) do
        -- Try to find the file in the current directory
        local find_cmd = string.format(
            "find . \\( -path '*/.venv' -o -path '*/venv' -o -path '*/__pycache__' -o -path '*/node_modules' -o -path '*/.git' \\) -prune -o -name '%s' -type f -print 2>/dev/null | head -10",
            file_ref:gsub("'", "'\"'\"'")
        )
        local handle = io.popen(find_cmd)

        if handle then
            local result = handle:read("*all") or ""
            handle:close()

            -- Process found files
            for file_path in result:gmatch("[^\r\n]+") do
                if file_path and file_path ~= "" then
                    local clean_path = file_path:gsub("^%./", ""):gsub("//+", "/"):gsub("/$", "")
                    -- Check if file is not already in the list
                    local already_found = false
                    for _, existing in ipairs(found_files) do
                        if existing == clean_path then
                            already_found = true
                            break
                        end
                    end
                    if not already_found then
                        table.insert(found_files, clean_path)
                    end
                end
            end
        end

        checked_files = checked_files + 1
        check_completion()
    end
end

local function ripgrep_search_task_url(task_url, callback)
    -- First check if ripgrep is available
    local rg_check = io.popen("which rg 2>/dev/null")
    if not rg_check then
        callback(nil, "Failed to check for ripgrep")
        return
    end

    local rg_path = rg_check:read("*line")
    rg_check:close()

    if not rg_path or rg_path == "" then
        callback(nil, "ripgrep (rg) not found in PATH")
        return
    end

    -- Escape the URL for shell safety
    -- For fixed-strings mode, we don't need regex escaping, just shell escaping
    local escaped_url = task_url:gsub("'", "'\"'\"'")

    -- Get current working directory for search
    local cwd = vim.fn.getcwd()

    -- Use a more robust search command with error checking
    -- Use single quotes for the URL to avoid issues with special characters
    -- Explicitly limit search to current directory only with --max-depth
    local cmd = string.format(
        "cd '%s' && rg --files-with-matches --no-heading --fixed-strings --max-depth=100 --glob '!.venv' --glob '!*venv*' --glob '!__pycache__' --glob '!node_modules' --glob '!.git' '%s' . 2>&1",
        cwd:gsub("'", "'\"'\"'"),
        escaped_url
    )

    -- Debug: print the command being executed (uncomment for debugging)
    -- vim.notify("Executing command: " .. cmd, vim.log.levels.DEBUG)

    local handle = io.popen(cmd)
    if not handle then
        callback(nil, "Failed to execute ripgrep command")
        return
    end

    local result = handle:read("*all") or ""
    local exit_code = handle:close()

    -- Handle ripgrep exit codes: 0 = matches found, 1 = no matches, 2+ = error
    if not exit_code then
        callback(nil, "Ripgrep command execution failed")
        return
    end

    -- Check if result contains error messages
    if result:match("^rg:") or result:match("error:") then
        callback(nil, "Ripgrep error: " .. result:gsub("\n", " "))
        return
    end

    local files = {}
    if result and result ~= "" then
        for file in result:gmatch("[^\r\n]+") do
            -- Only add non-empty lines that look like file paths
            if file ~= "" and not file:match("^%s*$") then
                -- Normalize the path
                local normalized_file = file:gsub("^%./", ""):gsub("//+", "/"):gsub("/$", "")
                if normalized_file ~= "" then
                    table.insert(files, normalized_file)
                end
            end
        end
    end

    callback(files, nil)
end

local function fallback_search_task_url(task_url, callback)
    -- Use vim's internal grep functionality as fallback
    -- Get current working directory for extra safety
    local cwd = vim.fn.getcwd()

    -- Get all files in current directory recursively, explicitly constraining to cwd
    local files_cmd = string.format(
        "cd '%s' && find . \\( -path '*/.venv' -o -path '*/venv' -o -path '*/__pycache__' -o -path '*/node_modules' -o -path '*/.git' \\) -prune -o -maxdepth 100 -type f \\( ",
        cwd:gsub("'", "'\"'\"'")
    ) .. "-name '*.py' -o -name '*.lua' -o -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' -o " .. "-name '*.md' -o -name '*.txt' -o -name '*.rst' -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o " .. "-name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' -o -name '*.cs' -o -name '*.php' -o " .. "-name '*.rb' -o -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.fish' -o -name '*.yaml' -o " .. "-name '*.yml' -o -name '*.json' -o -name '*.xml' -o -name '*.html' -o -name '*.css' -o -name '*.scss' -o " .. "-name '*.less' -o -name '*.vim' -o -name '*.sql' \\) -print 2>/dev/null"
    local files_handle = io.popen(files_cmd)
    if not files_handle then
        callback(nil, "Failed to get file list")
        return
    end

    local files_result = files_handle:read("*all") or ""
    files_handle:close()

    local matching_files = {}

    -- Search each file for the URL
    for file_path in files_result:gmatch("[^\r\n]+") do
        if file_path and file_path ~= "" then
            -- Additional safety check: ensure file path is relative and within cwd
            if file_path:match("^/") or file_path:match("%.%.") then
                -- Skip absolute paths or paths trying to go up directories
                goto continue
            end

            local file_handle = io.open(file_path, "r")
            if file_handle then
                local content = file_handle:read("*all") or ""
                file_handle:close()

                if content and content:find(task_url, 1, true) then
                    -- Remove leading ./ from path
                    local clean_path = file_path:gsub("^%./", ""):gsub("//+", "/"):gsub("/$", "")
                    table.insert(matching_files, clean_path)
                end
            end
        end
        ::continue::
    end

    callback(matching_files, nil)
end

-- Enhanced search function that tries ripgrep first, then falls back
local function search_task_url(task_url, callback)
    ripgrep_search_task_url(task_url, function(files, error)
        if error then
            -- If ripgrep failed, try fallback method
            notify_info("Ripgrep failed, using fallback search method", "clickup")
            fallback_search_task_url(task_url, callback)
        else
            callback(files, nil)
        end
    end)
end

function M.clear_xref_results()
    -- Find the results buffer
    for _, existing_buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(existing_buf) then
            -- Look for buffer by filetype or name pattern
            local filetype = vim.bo[existing_buf].filetype
            local name = vim.api.nvim_buf_get_name(existing_buf)
            if filetype == "clickup-xref" or name:match("ClickUp%-XRef%-Results") then
                -- Clear buffer content
                vim.bo[existing_buf].modifiable = true
                vim.api.nvim_buf_set_lines(existing_buf, 0, -1, false, {})
                vim.bo[existing_buf].modifiable = false
                notify_info("XRef results cleared", "clickup")
                return
            end
        end
    end

    notify_warn("No XRef results buffer found to clear", "clickup")
end

function M.cleanup_sourcefiles()
    notify_info(
        "Cleaning up SourceFiles across all tasks (removing duplicates, .venv references, etc.)..."
        , "clickup")

    get_team_tasks_with_custom_fields(function(tasks, error)
        if error then
            notify_error("Error fetching tasks: " .. error, "clickup")
            return
        end

        if not tasks or #tasks == 0 then
            notify_warn("No tasks found in team", "clickup")
            return
        end

        local processed = 0
        local updated_count = 0
        local failed_count = 0
        local total_tasks = #tasks

        for _, task in ipairs(tasks) do
            local existing_source_files = get_source_files_value(task)

            if existing_source_files and existing_source_files ~= "" then
                local cleaned_files = validate_and_clean_source_files(existing_source_files)
                local new_source_files_value = table.concat(cleaned_files, "\n")

                -- Only update if there are actual changes
                if new_source_files_value ~= existing_source_files then
                    notify_info(
                        "Cleaning SourceFiles for: "
                            .. task.name:sub(1, 40)
                            .. (task.name:len() > 40 and "..." or "")
                        , "clickup")

                    update_task_custom_field(
                        task.id,
                        "SourceFiles",
                        new_source_files_value,
                        function(_success, update_error)
                            processed = processed + 1

                            if update_error then
                                failed_count = failed_count + 1
                                notify_warn(
                                    "Failed to clean SourceFiles for: "
                                        .. task.name:sub(1, 30)
                                        .. " - "
                                        .. update_error
                                    , "clickup")
                            else
                                updated_count = updated_count + 1
                                notify_success(
                                    "Cleaned SourceFiles for: "
                                        .. task.name:sub(1, 30)
                                        .. (task.name:len() > 30 and "..." or "")
                                    , "clickup")
                            end

                            if processed >= total_tasks then
                                notify_success(
                                    "SourceFiles cleanup completed: "
                                        .. updated_count
                                        .. " updated, "
                                        .. failed_count
                                        .. " failed"
                                    , "clickup")
                            end
                        end
                    )
                else
                    processed = processed + 1
                    if processed >= total_tasks then
                        notify_success(
                            "SourceFiles cleanup completed: "
                                .. updated_count
                                .. " updated, "
                                .. failed_count
                                .. " failed"
                            , "clickup")
                    end
                end
            else
                processed = processed + 1
                if processed >= total_tasks then
                    notify_success(
                        "SourceFiles cleanup completed: "
                            .. updated_count
                            .. " updated, "
                            .. failed_count
                            .. " failed"
                        , "clickup")
                end
            end
        end
    end)
end

function M.clickup_task_xref()
    notify_info("Fetching ClickUp tasks...", "clickup")

    get_team_tasks_with_custom_fields(function(tasks, error)
        if error then
            notify_error("Error fetching tasks: " .. error, "clickup")
            return
        end

        if not tasks or #tasks == 0 then
            notify_warn("No tasks found in team", "clickup")
            return
        end

        -- Filter for bugs without filename references
        local bugs_without_refs = {}
        for _, task in ipairs(tasks) do
            -- Check if task name contains "bug" (case-insensitive) or has bug-related tags
            -- local is_bug = task.name and (
            --     task.name:lower():match("bug") or
            --     task.name:lower():match("issue") or
            --     task.name:lower():match("error") or
            --     task.name:lower():match("fix")
            -- )
            local is_bug = true

            -- Include tasks without SourceFiles field OR tasks that have file references in description but no SourceFiles field
            if
                is_bug
                and (not task_has_filename_reference(task) or task_needs_sourcefile_update(task))
            then
                table.insert(bugs_without_refs, task)
            end
        end

        notify_info(
            string.format(
                "Processing %d tasks (including tasks with file references in description but no SourceFiles field)...",
                #bugs_without_refs
            )
            , "clickup")

        if #bugs_without_refs == 0 then
            notify_warn("No tasks to process", "clickup")
            return
        end

        -- Process each bug and collect results
        local processed = 0
        local updated_bugs = {}
        local failed_updates = {}
        local no_refs_found = {}
        local total_tasks = #bugs_without_refs

        -- Helper function to check completion and display results
        local function check_completion()
            if processed >= total_tasks then
                M.display_xref_results(updated_bugs, failed_updates, no_refs_found)
            end
        end

        for _, task in ipairs(bugs_without_refs) do
            local task_url = "https://app.clickup.com/t/" .. task.id
            -- Show progress every 10th task or at start to reduce noise but keep user informed
            if (processed + 1) % 10 == 0 or processed == 0 then
                notify_info(
                    string.format("Progress: %d/%d tasks processed", processed + 1, total_tasks)
                    , "clickup")
            end

            -- Combined search: first search for URL, then for files mentioned in description
            local function combined_search(callback)
                search_task_url(task_url, function(url_files, url_error)
                    if url_error then
                        callback(nil, url_error)
                        return
                    end

                    -- Also search for files mentioned in task description
                    search_files_in_description(task, function(desc_files, desc_error)
                        if desc_error then
                            -- If description search fails, just use URL results
                            callback(url_files or {}, nil, {})
                            return
                        end

                        -- Combine results from both searches
                        local all_files = {}

                        -- Collect all files from both sources
                        if url_files then
                            for _, file in ipairs(url_files) do
                                table.insert(all_files, file)
                            end
                        end

                        local desc_found_files = {}
                        if desc_files then
                            for _, file in ipairs(desc_files) do
                                table.insert(all_files, file)
                                table.insert(desc_found_files, file)
                            end
                        end

                        -- Normalize and deduplicate all files
                        all_files = normalize_and_dedupe_files(all_files)
                        desc_found_files = normalize_and_dedupe_files(desc_found_files)

                        callback(all_files, nil, desc_found_files)
                    end)
                end)
            end

            combined_search(function(files, search_error, desc_files)
                processed = processed + 1

                if search_error then
                    table.insert(failed_updates, {
                        url = task_url,
                        name = task.name,
                        error = search_error,
                    })

                    -- Check if all tasks are processed and display results
                    check_completion()
                elseif files and #files > 0 then
                    -- Show file findings for significant discoveries
                    notify_info(
                        "Found "
                            .. #files
                            .. " file(s) for: "
                            .. task.name:sub(1, 50)
                            .. (task.name:len() > 50 and "..." or "")
                        , "clickup")

                    -- Get existing SourceFiles and merge with new findings
                    local existing_source_files =
                        validate_and_clean_source_files(get_source_files_value(task))

                    -- Combine existing and new files, then normalize and dedupe
                    local combined_files = {}
                    for _, file in ipairs(existing_source_files) do
                        table.insert(combined_files, file)
                    end
                    for _, file in ipairs(files) do
                        table.insert(combined_files, file)
                    end

                    -- Final normalization and deduplication
                    local final_files = normalize_and_dedupe_files(combined_files)
                    local source_files_value = table.concat(final_files, "\n")

                    -- Only update if there are actually changes
                    local existing_value = get_source_files_value(task) or ""
                    if source_files_value == existing_value then
                        notify_info(
                            "No changes needed for SourceFiles: "
                                .. task.name:sub(1, 40)
                                .. (task.name:len() > 40 and "..." or "")
                            , "clickup")

                        -- Still need to check description updates for desc_files
                        if
                            desc_files
                            and #desc_files > 0
                            and task.description
                            and task.description ~= ""
                        then
                            local updated_description =
                                strip_filenames_from_description(task.description, desc_files)

                            if updated_description ~= task.description then
                                notify_info(
                                    "Updating description for: "
                                        .. task.name:sub(1, 40)
                                        .. (task.name:len() > 40 and "..." or "")
                                    , "clickup")
                                update_task_description(
                                    task.id,
                                    updated_description,
                                    function(desc_success, desc_error)
                                        if desc_error then
                                            notify_warn(
                                                "Failed to update description for: "
                                                    .. task.name:sub(1, 30)
                                                    .. " - "
                                                    .. desc_error
                                                , "clickup")
                                        else
                                            notify_success(
                                                "Updated description for: "
                                                    .. task.name:sub(1, 30)
                                                    .. (task.name:len() > 30 and "..." or "")
                                                , "clickup")
                                        end

                                        table.insert(updated_bugs, {
                                            url = task_url,
                                            name = task.name,
                                            files = final_files,
                                            description_updated = desc_success and not desc_error,
                                        })

                                        check_completion()
                                    end
                                )
                                return
                            end
                        end

                        check_completion()
                        return
                    end

                    -- Update SourceFiles field
                    update_task_custom_field(
                        task.id,
                        "SourceFiles",
                        source_files_value,
                        function(_success, update_error)
                            if update_error then
                                table.insert(failed_updates, {
                                    url = task_url,
                                    name = task.name,
                                    error = update_error,
                                })
                                check_completion()
                                return
                            end

                            -- If files were found via description and we have a valid description, strip filenames
                            if
                                desc_files
                                and #desc_files > 0
                                and task.description
                                and task.description ~= ""
                            then
                                local updated_description =
                                    strip_filenames_from_description(task.description, desc_files)

                                -- Only update description if it actually changed
                                if updated_description ~= task.description then
                                    notify_info(
                                        "Description before: "
                                            .. task.description:sub(1, 100)
                                            .. (task.description:len() > 100 and "..." or "")
                                        , "clickup")
                                    notify_info(
                                        "Description after: "
                                            .. updated_description:sub(1, 100)
                                            .. (updated_description:len() > 100 and "..." or "")
                                        , "clickup")
                                    notify_info(
                                        "Updating description for: "
                                            .. task.name:sub(1, 40)
                                            .. (task.name:len() > 40 and "..." or "")
                                        , "clickup")
                                    update_task_description(
                                        task.id,
                                        updated_description,
                                        function(desc_success, desc_error)
                                            if desc_error then
                                                notify_warn(
                                                    "Failed to update description for: "
                                                        .. task.name:sub(1, 30)
                                                        .. " - "
                                                        .. desc_error
                                                    , "clickup")
                                            else
                                                notify_success(
                                                    "Updated description for: "
                                                        .. task.name:sub(1, 30)
                                                        .. (task.name:len() > 30 and "..." or "")
                                                    , "clickup")
                                            end

                                            -- Record success regardless of description update result
                                            notify_success(
                                                "Updated SourceFiles for: "
                                                    .. task.name:sub(1, 40)
                                                    .. (task.name:len() > 40 and "..." or "")
                                                , "clickup")
                                            table.insert(updated_bugs, {
                                                url = task_url,
                                                name = task.name,
                                                files = final_files,
                                                description_updated = desc_success
                                                    and not desc_error,
                                            })

                                            check_completion()
                                        end
                                    )
                                    return
                                end
                            end

                            -- No description update needed, just record SourceFiles success
                            notify_success(
                                "Updated SourceFiles for: "
                                    .. task.name:sub(1, 40)
                                    .. (task.name:len() > 40 and "..." or "")
                                , "clickup")
                            table.insert(updated_bugs, {
                                url = task_url,
                                name = task.name,
                                files = final_files,
                                description_updated = false,
                            })

                            check_completion()
                        end
                    )
                else
                    -- Don't notify about tasks with no files, just track them
                    table.insert(no_refs_found, {
                        url = task_url,
                        name = task.name,
                    })

                    -- Check if all tasks are processed and display results
                    check_completion()
                end
            end)
        end
    end)
end

-- Function to display cross-reference results in messages window
function M.display_xref_results(updated_bugs, failed_updates, no_refs_found)
    -- Look for existing ClickUp results buffer
    local buf = nil
    local buf_name = "ClickUp-XRef-Results"

    -- Check if buffer already exists
    for _, existing_buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(existing_buf) then
            local name = vim.api.nvim_buf_get_name(existing_buf)
            if name:match(buf_name .. "$") or vim.bo[existing_buf].filetype == "clickup-xref" then
                buf = existing_buf
                break
            end
        end
    end

    -- Create buffer if it doesn't exist
    if not buf then
        buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].swapfile = false
        -- Set buffer name safely, handling potential conflicts
        local success, _err = pcall(vim.api.nvim_buf_set_name, buf, buf_name)
        if not success then
            -- If naming fails, create unique name with timestamp
            local unique_name = buf_name .. "-" .. os.time()
            vim.api.nvim_buf_set_name(buf, unique_name)
        end
    end

    local lines = {}

    -- Add timestamp separator if buffer already has content
    local existing_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #existing_lines > 0 and existing_lines[1] ~= "" then
        table.insert(lines, "")
        table.insert(lines, string.rep("=", 70))
        table.insert(lines, "NEW RESULTS - " .. os.date("%Y-%m-%d %H:%M:%S"))
        table.insert(lines, string.rep("=", 70))
        table.insert(lines, "")
    end

    table.insert(lines, "ClickUp Cross-Reference Results")
    table.insert(lines, "=" .. string.rep("=", 35))
    table.insert(lines, "")

    -- Updated bugs section
    if #updated_bugs > 0 then
        table.insert(lines, string.format("✓ UPDATED BUGS (%d):", #updated_bugs))
        table.insert(lines, string.rep("-", 30))
        for _, bug in ipairs(updated_bugs) do
            table.insert(lines, string.format("• %s", bug.name))
            table.insert(lines, string.format("  URL: %s", bug.url))
            table.insert(lines, string.format("  Files: %s", table.concat(bug.files, ", ")))
            if bug.description_updated then
                table.insert(lines, "  ✓ Description updated (filenames removed)")
            end
            table.insert(lines, "")
        end
    end

    -- Failed updates section
    if #failed_updates > 0 then
        table.insert(lines, string.format("✗ FAILED UPDATES (%d):", #failed_updates))
        table.insert(lines, string.rep("-", 30))
        for _, bug in ipairs(failed_updates) do
            table.insert(lines, string.format("• %s", bug.name))
            table.insert(lines, string.format("  URL: %s", bug.url))
            table.insert(lines, string.format("  Error: %s", bug.error))
            table.insert(lines, "")
        end
    end

    -- No references found section
    if #no_refs_found > 0 then
        table.insert(lines, string.format("- NO REFERENCES FOUND (%d):", #no_refs_found))
        table.insert(lines, string.rep("-", 30))
        for _, bug in ipairs(no_refs_found) do
            table.insert(lines, string.format("• %s", bug.name))
            table.insert(lines, string.format("  URL: %s", bug.url))
            table.insert(lines, "")
        end
    end

    -- Summary
    table.insert(lines, string.rep("=", 50))
    table.insert(
        lines,
        string.format(
            "SUMMARY: %d updated, %d failed, %d no references",
            #updated_bugs,
            #failed_updates,
            #no_refs_found
        )
    )

    -- Append to buffer content (or set if empty)
    -- Ensure buffer is modifiable before editing
    vim.bo[buf].modifiable = true

    if #existing_lines > 0 and existing_lines[1] ~= "" then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    else
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    end

    vim.bo[buf].modifiable = false

    -- Find existing window with this buffer or create new one
    local win = nil
    for _, existing_win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(existing_win) == buf then
            win = existing_win
            break
        end
    end

    if not win then
        -- Open in a split window
        vim.cmd("split")
        vim.api.nvim_win_set_buf(0, buf)
        win = vim.api.nvim_get_current_win()

        -- Set buffer-local options for new window
        vim.wo[win].wrap = false
        vim.wo[win].number = false
        vim.wo[win].relativenumber = false
    else
        -- Focus existing window and scroll to bottom
        vim.api.nvim_set_current_win(win)
    end

    -- Scroll to bottom to show new results
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })

    -- Add syntax highlighting for the results
    vim.bo[buf].filetype = "clickup-xref"

    -- Define simple syntax highlighting
    vim.cmd([[
        if exists("b:current_syntax")
            finish
        endif

        syntax match ClickUpXRefTitle /^ClickUp Cross-Reference Results$/
        syntax match ClickUpXRefSeparator /^[=-]\+$/
        syntax match ClickUpXRefSuccess /^✓ UPDATED BUGS.*$/
        syntax match ClickUpXRefError /^✗ FAILED UPDATES.*$/
        syntax match ClickUpXRefWarning /^- NO REFERENCES FOUND.*$/
        syntax match ClickUpXRefSummary /^SUMMARY:.*$/
        syntax match ClickUpXRefURL /https:\/\/app\.clickup\.com\/t\/[a-zA-Z0-9-]\+/
        syntax match ClickUpXRefFile /\v\s+Files: .+$/

        highlight default link ClickUpXRefTitle Title
        highlight default link ClickUpXRefSeparator Comment
        highlight default link ClickUpXRefSuccess DiffAdd
        highlight default link ClickUpXRefError DiffDelete
        highlight default link ClickUpXRefWarning DiffChange
        highlight default link ClickUpXRefSummary Special
        highlight default link ClickUpXRefURL Underlined
        highlight default link ClickUpXRefFile String

        let b:current_syntax = "clickup-xref"
    ]])

    -- Notify about completion
    notify_success(
        string.format(
            "Cross-reference complete: %d updated, %d failed, %d no references",
            #updated_bugs,
            #failed_updates,
            #no_refs_found
        )
        , "clickup")
end

-- Generalized function to extract ClickUp task URL from comment
local function extract_task_url_from_comment(comment_info)
    if not comment_info or not comment_info.is_comment then
        return nil
    end

    -- Check all lines for any task URL (not just last line)
    for _, line in ipairs(comment_info.lines) do
        local url = extract_task_url(line)
        if url then
            return url
        end
    end

    return nil
end
-- Function to extract task ID from ClickUp URL
local function extract_task_id(url)
    if not url then
        return nil
    end
    local task_id = url:match("https://app%.clickup%.com/t/([%w%-]+)")
    return task_id
end

-- Function to extract GitHub issue number from URL
local function extract_github_issue_number(url)
    if not url then
        return nil
    end
    local issue_number = url:match("https://github%.com/[%w%-_%.]+/[%w%-_%.]+/issues/([0-9]+)")
    return issue_number
end

-- Function to extract Todoist task ID from URL
local function extract_todoist_task_id(url)
    if not url then
        return nil
    end
    local task_id = url:match("https://todoist%.com/showTask%?id=([0-9]+)")
    return task_id
end

-- Function to determine provider from URL
local function get_provider_from_url(url)
    if not url then
        return nil
    end

    if url:match("https://app%.clickup%.com/t/") then
        return "clickup"
    elseif url:match("https://github%.com/") then
        return "github"
    elseif url:match("https://todoist%.com/showTask") then
        return "todoist"
    end

    return nil
end

-- Generic function to extract task identifier from URL
local function extract_task_identifier(url)
    local provider = get_provider_from_url(url)
    if not provider then
        return nil, nil
    end

    if provider == "clickup" then
        return extract_task_id(url), provider
    elseif provider == "github" then
        return extract_github_issue_number(url), provider
    elseif provider == "todoist" then
        return extract_todoist_task_id(url), provider
    end

    return nil, provider
end

-- Generic task creation functions

local function create_task_with_provider(provider, task_name, filename, callback)
    if provider == "clickup" then
        create_clickup_task(task_name, filename, callback)
    elseif provider == "github" then
        create_github_issue(task_name, filename, callback)
    elseif provider == "todoist" then
        create_todoist_task(task_name, filename, callback)
    else
        callback(nil, "Unsupported provider: " .. provider)
    end
end

local function show_task_dialog_for_block(initial_text, comment_info, filename, provider)
    provider = provider or config.default_provider
    vim.ui.input({
        prompt = "Task name: ",
        default = initial_text,
        completion = nil,
    }, function(input)
        if not input or input == "" then
            notify_info("Task creation cancelled", provider)
            return
        end

        notify_info("Creating task...", provider)

        create_task_with_provider(provider, input, filename, function(task_url, error)
            if error then
                notify_error("Error creating task: " .. error, provider)
                return
            end

            if task_url then
                local success = extend_comment_with_url(comment_info, task_url)
                if success then
                    notify_success("Task created: " .. task_url, provider)
                else
                    notify_error("Error updating comment with task URL", provider)
                end
            end
        end)
    end)
end

function M.create_task_from_comment(lang_override, provider)
    provider = provider or config.default_provider

    if not check_language_supported(lang_override, provider) then
        return
    end

    -- Check if provider is enabled
    if not config.providers[provider] or not config.providers[provider].enabled then
        notify_error("Provider " .. provider .. " is not enabled")
        return
    end

    -- Get current buffer filename
    local filename = vim.fn.expand("%:t") -- Get just the filename without path
    if filename == "" then
        filename = "[Unnamed Buffer]"
    end

    -- Try to find a comment using generalized detection
    local comment_info = get_comment_info(lang_override)


    if not comment_info then
        local lang = lang_override or vim.bo.filetype
        notify_warn("No comment found on current line for language: " .. lang)
        return
    end

    -- Extract content from the comment
    local comment_content = extract_comment_content_generic(comment_info)

    if comment_content == "" then
        notify_warn("Comment is empty", provider)
        return
    end

    -- Check if URL already exists in comment
    if comment_has_url(comment_info) then
        notify_warn("Comment already contains a task URL", provider)
        return
    end

    show_task_dialog_for_block(comment_content, comment_info, filename, provider)
end

function M.update_task_status_from_comment(status, action_name, lang_override)
    if not check_language_supported(lang_override) then
        return
    end

    -- Try to find a comment using generalized detection
    local comment_info = get_comment_info(lang_override)

    if not comment_info then
        local lang = lang_override or vim.bo.filetype
        notify_warn("No comment found on current line for language: " .. lang)
        return
    end

    -- Extract task URL from comment
    local task_url = extract_task_url_from_comment(comment_info)
    if not task_url then
        notify_warn("No task URL found in comment")
        return
    end

    -- Extract task identifier and provider from URL
    local task_identifier, provider = extract_task_identifier(task_url)
    if not task_identifier then
        notify_error("Could not extract task identifier from URL")
        return
    end

    notify_info((action_name or "Updating") .. " task: " .. task_identifier, provider)

    -- Update task status using appropriate provider
    update_task_status_generic(task_identifier, provider, status, function(success, error)
        if error then
            notify_error("Error updating task: " .. error, provider)
            return
        end

        if success then
            notify_success("Task updated successfully (" .. status .. "): " .. task_url, provider)
        end
    end)
end

-- Provider-specific task creation functions
function M.create_clickup_task_from_comment(lang_override)
    M.create_task_from_comment(lang_override, "clickup")
end

function M.create_github_task_from_comment(lang_override)
    M.create_task_from_comment(lang_override, "github")
end

function M.create_todoist_task_from_comment(lang_override)
    M.create_task_from_comment(lang_override, "todoist")
end

function M.close_task_from_comment(lang_override)
    M.update_task_status_from_comment("complete", "Closing", lang_override)
end

function M.review_task_from_comment(lang_override)
    M.update_task_status_from_comment("review", "Setting to review", lang_override)
end

function M.in_progress_task_from_comment(lang_override)
    M.update_task_status_from_comment("in progress", "Setting to in progress", lang_override)
end

function M.add_file_to_task_sources(lang_override)
    if not check_language_supported(lang_override) then
        return
    end

    -- Get current buffer filename
    local filename = vim.fn.expand("%:t") -- Get just the filename without path
    if filename == "" or filename == "[Unnamed Buffer]" then
        notify_warn("No valid filename to add")
        return
    end

    -- Try to find a comment using generalized detection
    local comment_info = get_comment_info(lang_override)

    if not comment_info then
        local lang = lang_override or vim.bo.filetype
        notify_warn("No comment found on current line for language: " .. lang)
        return
    end

    -- Extract task URL from comment
    local task_url = extract_task_url_from_comment(comment_info)
    if not task_url then
        notify_warn("No task URL found in comment")
        return
    end

    -- Extract task identifier and provider from URL
    local task_identifier, provider = extract_task_identifier(task_url)
    if not task_identifier then
        notify_error("Could not extract task identifier from URL")
        return
    end

    notify_info("Adding " .. filename .. " to task: " .. task_identifier, provider)

    if provider == "clickup" then
        -- ClickUp-specific handling with SourceFiles custom field
        get_task_with_custom_fields(task_identifier, function(task_data, get_error)
            if get_error then
                notify_error("Error fetching task: " .. get_error, "clickup")
                return
            end

            -- Get existing SourceFiles value
            local current_source_files = get_source_files_value(task_data)
            local files_list = {}

            -- Parse existing files
            if current_source_files and current_source_files ~= "" then
                for file in current_source_files:gmatch("[^\r\n]+") do
                    table.insert(files_list, file)
                end
            end

            -- Check if filename is already in the list
            local already_exists = false
            for _, existing_file in ipairs(files_list) do
                if existing_file == filename then
                    already_exists = true
                    break
                end
            end

            if already_exists then
                notify_info("File " .. filename .. " already exists in SourceFiles", "clickup")
                return
            end

            -- Add the new filename
            table.insert(files_list, filename)
            local updated_source_files = table.concat(files_list, "\n")

            -- Update the custom field
            update_task_custom_field(
                task_identifier,
                "SourceFiles",
                updated_source_files,
                function(success, update_error)
                    if update_error then
                        notify_error("Error updating SourceFiles: " .. update_error, "clickup")
                        return
                    end

                    if success then
                        notify_success("Successfully added " .. filename .. " to SourceFiles: " .. task_url, "clickup")
                    end
                end
            )
        end)
    else
        -- For GitHub and Todoist, add to structured text
        add_file_to_task_generic(task_identifier, provider, filename, function(success, error)
            if error then
                notify_error("Error adding file to task: " .. error, provider)
                return
            end

            if success then
                notify_success("Successfully added " .. filename .. " to task: " .. task_url, provider)
            end
        end)
    end
end

-- Legacy ClickUp-specific function for backward compatibility
function M.add_file_to_clickup_task_sources(lang_override)
    -- This will only work if the comment contains a ClickUp URL
    if not check_language_supported(lang_override, "clickup") then
        return
    end

    M.add_file_to_task_sources(lang_override)
end

function M.setup(opts)
    opts = opts or {}

    -- Set default provider
    if opts.default_provider then
        config.default_provider = opts.default_provider
    end

    -- Configure providers
    if opts.providers then
        for provider_name, provider_opts in pairs(opts.providers) do
            if config.providers[provider_name] then
                -- Merge provider configuration
                for key, value in pairs(provider_opts) do
                    config.providers[provider_name][key] = value
                end
            else
                -- Add new provider
                config.providers[provider_name] = provider_opts
            end
        end
    end

    -- Legacy ClickUp configuration for backward compatibility
    if opts.list_id then
        config.providers.clickup.list_id = opts.list_id
    end

    if opts.team_id then
        config.providers.clickup.team_id = opts.team_id
    end

    if opts.api_key_env then
        config.providers.clickup.api_key_env = opts.api_key_env
    end

    -- Configure comment prefixes
    if opts.comment_prefixes then
        config.comment_prefixes = opts.comment_prefixes
    end

    -- Configure language support
    if opts.languages then
        -- Merge user language configs with defaults
        for lang, lang_config in pairs(opts.languages) do
            if config.languages[lang] then
                -- Merge with existing config
                for key, value in pairs(lang_config) do
                    config.languages[lang][key] = value
                end
            else
                -- Add new language config
                config.languages[lang] = lang_config
            end
        end
    end

    -- Configure fallback behavior
    if opts.fallback_to_regex ~= nil then
        config.fallback_to_regex = opts.fallback_to_regex
    end

    -- Validate configuration
    local enabled_providers = {}
    for provider_name, provider_config in pairs(config.providers) do
        if provider_config.enabled then
            table.insert(enabled_providers, provider_name)
        end
    end

    if #enabled_providers == 0 then
        notify_warn("No providers are enabled")
    else
        -- notify_info("Enabled providers: " .. table.concat(enabled_providers, ", "))
    end

    -- Validate specific provider configurations
    if config.providers.clickup.enabled and not config.providers.clickup.list_id then
        notify_warn("ClickUp provider enabled but list_id not configured", "clickup")
    end

    if config.providers.github.enabled and (not config.providers.github.repo_owner or not config.providers.github.repo_name) then
        notify_warn("GitHub provider enabled but repo_owner/repo_name not configured", "github")
    end

    -- Create user commands

    -- Multi-provider commands (use default provider)
    vim.api.nvim_create_user_command(
        "TaskCreate",
        create_command_handler(M.create_task_from_comment),
        {
            desc = "Create task from comment using default provider (optional language arg)",
            nargs = "?", -- Optional argument
            complete = create_language_completion()
    })

    vim.api.nvim_create_user_command("TaskClose", create_command_handler(M.close_task_from_comment), {
        desc = "Close task from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })

    vim.api.nvim_create_user_command("TaskAddFile", create_command_handler(M.add_file_to_task_sources), {
        desc = "Add current file to task from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })

    -- Provider-specific commands

    -- ClickUp commands (backward compatibility)
    vim.api.nvim_create_user_command(
        "ClickUpTask",
        create_command_handler(M.create_clickup_task_from_comment),
        {
            desc = "Create ClickUp task from comment (optional language arg)",
            nargs = "?",
            complete = create_language_completion()
    })

    vim.api.nvim_create_user_command("ClickUpClose", create_command_handler(M.close_task_from_comment), {
        desc = "Close ClickUp task from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })


    vim.api.nvim_create_user_command("ClickUpReview", create_command_handler(M.review_task_from_comment_safe), {
        desc = "Set ClickUp task to review from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })


    vim.api.nvim_create_user_command("ClickUpInProgress", create_command_handler(M.in_progress_task_from_comment_safe), {
        desc = "Set ClickUp task to in progress from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })


    vim.api.nvim_create_user_command("ClickupTaskXref", function()
        M.clickup_task_xref()
    end, { desc = "Cross-reference ClickUp bugs with file locations using ripgrep" })

    vim.api.nvim_create_user_command("ClickUpClearResults", function()
        M.clear_xref_results()
    end, { desc = "Clear the ClickUp XRef results buffer" })

    vim.api.nvim_create_user_command("ClickUpAddFile", create_command_handler(M.add_file_to_task_sources_safe), {
        desc = "Add current file to SourceFiles custom field of ClickUp task from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })


    -- GitHub commands
    vim.api.nvim_create_user_command("GitHubTask", create_command_handler(M.create_github_task_from_comment), {
        desc = "Create GitHub issue from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })

    -- Todoist commands
    vim.api.nvim_create_user_command("TodoistTask", create_command_handler(M.create_todoist_task_from_comment), {
        desc = "Create Todoist task from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })


    vim.api.nvim_create_user_command("GitHubClose", create_command_handler(M.close_task_from_comment_safe), {
        desc = "Close GitHub issue from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })


    vim.api.nvim_create_user_command("TodoistClose", create_command_handler(M.close_task_from_comment_safe), {
        desc = "Close Todoist task from comment (optional language arg)",
        nargs = "?",
        complete = create_language_completion(),
    })


    vim.api.nvim_create_user_command("ClickUpCleanupSourceFiles", function()
        M.cleanup_sourcefiles()
    end, {
        desc = "Clean up and deduplicate SourceFiles across all ClickUp tasks (removes .venv, __pycache__, build dirs, etc.)",
    })

    -- Optional keybinding
    if opts.keymap then
        vim.keymap.set("n", opts.keymap, function()
            M.create_task_from_comment_safe()
        end, {
            desc = "Create task from comment (default provider)",
        })
    end
end

return M
