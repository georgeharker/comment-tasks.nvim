-- Comment detection and parsing logic for comment-tasks plugin

local utils = require("comment-tasks.core.utils")

local M = {}

-- Function to determine comment style based on comment content
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

-- Tree-sitter based comment detection
function M.get_comment_info_treesitter(lang_override, languages_config)
    local lang = lang_override or vim.bo.filetype
    local lang_config = languages_config[lang]

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

-- Fallback regex-based comment detection
function M.get_comment_info_regex(lang_override, languages_config)
    local lang = lang_override or vim.bo.filetype
    local lang_config = languages_config[lang]

    if not lang_config then
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

-- Main comment detection function
function M.get_comment_info(lang_override, languages_config, fallback_to_regex)
    -- Try Tree-sitter first
    local ts_result = M.get_comment_info_treesitter(lang_override, languages_config)
    if ts_result then
        return ts_result
    end

    -- Fallback to regex if Tree-sitter fails or fallback is enabled
    if fallback_to_regex then
        return M.get_comment_info_regex(lang_override, languages_config)
    end

    -- If we get here, Tree-sitter failed and fallback is disabled
    return nil
end

-- Extract comment content from detected comment
function M.extract_comment_content(comment_info, comment_prefixes)
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
                content = utils.trim_comment_prefixes(content, comment_prefixes)
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
        content = utils.trim_comment_prefixes(content, comment_prefixes)
        if content and content ~= "" then
            table.insert(content_parts, content)
        end
    end

    return table.concat(content_parts, " "):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Extend comment with URL
function M.extend_comment_with_url(comment_info, task_url)
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

-- Check if comment already contains a task URL
function M.comment_has_url(comment_info)
    if not comment_info or not comment_info.is_comment then
        return false
    end

    -- Check all lines for any task URL
    for _, line in ipairs(comment_info.lines) do
        if utils.extract_task_url(line) then
            return true
        end
    end

    return false
end

-- Extract task URL from comment
function M.extract_task_url_from_comment(comment_info)
    if not comment_info or not comment_info.is_comment then
        return nil
    end

    -- Check all lines for any task URL (not just last line)
    for _, line in ipairs(comment_info.lines) do
        local url = utils.extract_task_url(line)
        if url then
            return url
        end
    end

    return nil
end

return M
