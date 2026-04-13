-- lua/comment-tasks/core/project.lua
-- Locate a project root and load the optional per-project config file
-- (.comment-tasks.json) that allows teams to override provider project IDs
-- without touching their personal Neovim configuration.
--
-- Root detection walks upward from the current file's directory:
--   1. At each ancestor, check for .comment-tasks.json — if found, stop.
--   2. Otherwise check for any root marker (configurable via setup()).
--      If a marker is found, that directory is the root.
--   3. If we reach the filesystem root without a match, return nil.
--
-- This means .comment-tasks.json always wins (closest to the file), and
-- root markers (.git, pyproject.toml, etc.) act as a ceiling.

local M = {}

local CONFIG_FILE = ".comment-tasks.json"

--- Return the root_markers list from the plugin config.
--- Falls back to a minimal default when the config module has not yet been
--- loaded (e.g. during early require or testing).
---@return string[]
local function get_configured_markers()
    local ok, config = pcall(require, "comment-tasks.core.config")
    if ok and config and config.config and config.config.root_markers then
        return config.config.root_markers
    end
    -- Minimal fallback — should only be hit during isolated testing
    return { ".git" }
end

--- Check whether a marker exists in a directory.
--- Handles plain names and simple glob patterns (e.g. "*.sln").
---@param dir string
---@param marker string
---@return boolean
local function marker_exists(dir, marker)
    if marker:find("%*") then
        -- Glob pattern — use vim.fn.glob
        local matches = vim.fn.glob(dir .. "/" .. marker, false, true)
        return #matches > 0
    end
    return vim.fn.isdirectory(dir .. "/" .. marker) == 1
        or vim.fn.filereadable(dir .. "/" .. marker) == 1
end

-- ---------------------------------------------------------------------------
-- Root detection
-- ---------------------------------------------------------------------------

--- Walk upward from start_path looking for the project root.
---
--- At each directory the search checks (in order):
---   1. .comment-tasks.json — immediately returns this directory.
---   2. Any entry in `markers` — returns this directory.
---
--- The first directory that satisfies either condition wins.
--- Returns nil if the filesystem root is reached without a match.
---
---@param start_path string?  Starting directory (defaults to current buffer dir)
---@param markers    string[]? Optional override for the marker list
---@return string|nil root       Directory that is the project root
---@return boolean    has_config  Whether root contains .comment-tasks.json
function M.find_project_root(start_path, markers)
    markers = markers or get_configured_markers()
    start_path = start_path or vim.fn.expand("%:p:h")

    local path = start_path
    local prev = nil
    while path ~= prev do
        -- Priority 1: the config file itself is the strongest signal.
        if vim.fn.filereadable(path .. "/" .. CONFIG_FILE) == 1 then
            return path, true
        end

        -- Priority 2: any configured root marker.
        for _, marker in ipairs(markers) do
            if marker_exists(path, marker) then
                return path, false
            end
        end

        prev = path
        path = vim.fn.fnamemodify(path, ":h")
    end
    return nil, false
end

--- Backwards-compatible alias.  Searches only for .git markers using the
--- manual walk-up strategy (supports git worktrees where .git is a file).
---
---@param start_path string
---@return string|nil
function M.find_git_root(start_path)
    local path = start_path or vim.fn.expand("%:p:h")
    local prev = nil
    while path ~= prev do
        if vim.fn.isdirectory(path .. "/.git") == 1
                or vim.fn.filereadable(path .. "/.git") == 1 then
            return path
        end
        prev = path
        path = vim.fn.fnamemodify(path, ":h")
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Config file loading
-- ---------------------------------------------------------------------------

--- Read and parse the .comment-tasks.json file at root.
---
--- Returns (nil, nil)        when the file simply does not exist.
--- Returns (nil, err_string) when the file exists but is not valid JSON.
--- Returns (table, nil)      on success.
---
---@param root string  Directory to look in
---@return table|nil, string|nil
function M.load_project_config(root)
    local path = root .. "/" .. CONFIG_FILE
    if vim.fn.filereadable(path) == 0 then
        return nil, nil
    end
    local lines = vim.fn.readfile(path)
    if not lines or #lines == 0 then
        return nil, "empty file: " .. path
    end
    local ok, parsed = pcall(vim.fn.json_decode, table.concat(lines, "\n"))
    if not ok or type(parsed) ~= "table" then
        return nil, "invalid JSON in " .. path
    end
    return parsed, nil
end

--- Find the project root for the current buffer and load its
--- .comment-tasks.json if one exists.
---
--- Walks upward from the current file's directory.  .comment-tasks.json
--- is checked first at every level (so it always wins as the root anchor).
--- Root markers act as a ceiling — if one is hit before the config file,
--- that directory is taken as root and the config is loaded from there
--- (if present).
---
--- No caching — called fresh on every command invocation.
---
---@return table|nil project_config
---@return string|nil error
function M.load_for_current_buffer()
    local dir = vim.fn.expand("%:p:h")

    local root, has_config = M.find_project_root(dir)

    -- Fallback: pure git detection for worktrees where .git is a file.
    if not root then
        root = M.find_git_root(dir)
    end

    if not root then
        return nil, nil
    end

    -- If find_project_root already confirmed the config file, load it.
    -- Otherwise still try — the git-root fallback might contain one.
    if has_config then
        return M.load_project_config(root)
    end

    -- Root was found via a marker, not the config file.  Still check
    -- whether the config file happens to be there.
    return M.load_project_config(root)
end

return M
