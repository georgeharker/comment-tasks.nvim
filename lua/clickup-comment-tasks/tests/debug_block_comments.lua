-- Debug script to understand why block comments aren't detected from middle lines

local function debug_block_comment_detection()
    print("=== Block Comment Detection Debug ===")
    
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_row = cursor[1] - 1
    local line = vim.api.nvim_get_current_line()
    
    print("Cursor row:", cursor_row)
    print("Current line:", line)
    print("Filetype:", vim.bo.filetype)
    
    -- Try to get parser and show all comment nodes
    local ok, parser = pcall(vim.treesitter.get_parser, 0, vim.bo.filetype)
    if not ok or not parser then
        print("❌ No parser")
        return
    end
    
    local trees = parser:parse()
    local tree = trees and trees[1]
    if not tree then
        print("❌ No tree")
        return
    end
    
    local root = tree:root()
    print("✅ Got tree")
    
    -- Show all comment nodes and their ranges
    local function find_all_comments(node, depth)
        depth = depth or 0
        local indent = string.rep("  ", depth)
        
        local node_type = node:type()
        if node_type:match("comment") or node_type:match("Comment") then
            local start_row, start_col, end_row, end_col = node:range()
            local contains_cursor = cursor_row >= start_row and cursor_row <= end_row
            
            print(string.format("%s%s [%d:%d - %d:%d] %s", 
                indent, 
                node_type,
                start_row, start_col, 
                end_row, end_col,
                contains_cursor and "🎯 CONTAINS CURSOR" or ""
            ))
            
            -- Show the text content
            local text = vim.treesitter.get_node_text(node, 0)
            if text then
                local preview = text:gsub("\n", "\\n"):sub(1, 60)
                print(indent .. "  Text: " .. preview .. (text:len() > 60 and "..." or ""))
            end
            
            if contains_cursor then
                print(indent .. "  ✅ This node contains cursor!")
            end
        end
        
        for child in node:iter_children() do
            find_all_comments(child, depth + 1)
        end
    end
    
    print("\n--- All comment nodes ---")
    find_all_comments(root)
    
    -- Test our comment detection function
    print("\n--- Testing get_comment_info ---")
    
    -- Mock config (simplified)
    local config = {
        languages = {
            javascript = {
                comment_nodes = { "comment", "line_comment", "block_comment", "Comment", "multiline_comment" },
                comment_styles = {
                    single_line = { prefix = "// ", continue_with = "// " },
                    block = {
                        start_markers = { "/*" },
                        end_markers = { "*/" },
                        continue_with = " * "
                    }
                }
            }
        }
    }
    
    -- Simulate comment detection
    local lang = vim.bo.filetype
    local lang_config = config.languages[lang]
    
    if lang_config then
        local comment_nodes = {}
        
        local function collect_comment_nodes(node)
            if not node then return end
            
            local node_type = node:type()
            if vim.tbl_contains(lang_config.comment_nodes, node_type) then
                local start_row, start_col, end_row, end_col = node:range()
                
                if cursor_row >= start_row and cursor_row <= end_row then
                    table.insert(comment_nodes, {
                        node = node,
                        start_row = start_row,
                        end_row = end_row,
                        type = node_type
                    })
                    print(string.format("Found matching comment: %s [%d - %d]", node_type, start_row, end_row))
                end
            end
            
            for child in node:iter_children() do
                collect_comment_nodes(child)
            end
        end
        
        collect_comment_nodes(root)
        
        print("Total matching comment nodes:", #comment_nodes)
        
        if #comment_nodes > 0 then
            local best_node = comment_nodes[1]
            local lines = vim.api.nvim_buf_get_lines(0, best_node.start_row, best_node.end_row + 1, false)
            print("Comment lines:")
            for i, line in ipairs(lines) do
                print("  " .. i .. ": " .. line)
            end
        end
    end
    
    print("=== Debug Complete ===")
end

return {
    debug = debug_block_comment_detection
}