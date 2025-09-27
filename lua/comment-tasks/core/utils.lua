-- Common utilities for comment-tasks plugin

local M = {}

-- Notification functions with provider-specific titles
function M.notify_info(message, provider)
    local title = provider and (provider:gsub("^%l", string.upper) .. " Tasks") or "Task Manager"
    vim.notify(message, vim.log.levels.INFO, { title = title })
end

function M.notify_success(message, provider)
    local title = provider and (provider:gsub("^%l", string.upper) .. " Success") or "Task Manager"
    vim.notify("✓ " .. message, vim.log.levels.INFO, { title = title })
end

function M.notify_error(message, provider)
    local title = provider and (provider:gsub("^%l", string.upper) .. " Error") or "Task Manager"
    vim.notify("✗ " .. message, vim.log.levels.ERROR, { title = title })
end

function M.notify_warn(message, provider)
    local title = provider and (provider:gsub("^%l", string.upper) .. " Warning") or "Task Manager"
    vim.notify("⚠ " .. message, vim.log.levels.WARN, { title = title })
end

-- URL extraction functions
function M.extract_clickup_url(line)
    return line:match("(https://app%.clickup%.com/t/[%w%-]+)")
end

function M.extract_github_url(line)
    return line:match("(https://github%.com/[%w%-_%.]+/[%w%-_%.]+/issues/[0-9]+)")
end

function M.extract_todoist_url(line)
    return line:match("(https://todoist%.com/showTask%?id=[0-9]+)")
end

function M.extract_gitlab_url(line)
    return line:match("(https://gitlab%.com/[%w%-_%.]+/[%w%-_%.]+/%-/issues/[0-9]+)")
end

-- Generic function to extract any supported task URL
function M.extract_task_url(line)
    return M.extract_clickup_url(line) or
           M.extract_github_url(line) or
           M.extract_todoist_url(line) or
           M.extract_gitlab_url(line)
end

-- Function to get provider name from URL
function M.get_provider_from_url(url)
    if not url then
        return nil
    end

    if url:match("https://app%.clickup%.com/t/") then
        return "clickup"
    elseif url:match("https://github%.com/") then
        return "github"
    elseif url:match("https://todoist%.com/showTask") then
        return "todoist"
    elseif url:match("https://gitlab%.com/") then
        return "gitlab"
    end

    return nil
end

-- Function to trim comment prefixes
function M.trim_comment_prefixes(text, comment_prefixes)
    if not text or text == "" then
        return text
    end

    comment_prefixes = comment_prefixes or {
        "TODO", "FIXME", "BUG", "HACK", "WARN", "PERF", "NOTE", "INFO",
        "TEST", "PASSED", "FAILED", "FIX", "ISSUE", "XXX", "OPTIMIZE",
        "REVIEW", "DEPRECATED", "REFACTOR", "CLEANUP"
    }

    -- Try to match and remove prefixes (case-insensitive, with optional colon and whitespace)
    for _, prefix in ipairs(comment_prefixes) do
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

-- Function to check if current buffer language is supported
function M.is_supported_language(lang_override, languages_config)
    local lang = lang_override or vim.bo.filetype
    return languages_config[lang] ~= nil
end

-- Helper function to check language support and notify if unsupported
function M.check_language_supported(lang_override, languages_config, provider)
    if not M.is_supported_language(lang_override, languages_config) then
        local lang = lang_override or vim.bo.filetype
        M.notify_warn("Language '" .. lang .. "' is not supported", provider)
        return false
    end
    return true
end

-- Function to get current buffer filename
function M.get_current_filename()
    local filename = vim.fn.expand("%:t") -- Get just the filename without path
    if filename == "" then
        filename = "[Unnamed Buffer]"
    end
    return filename
end

-- Function to normalize file paths and remove duplicates
function M.normalize_and_dedupe_files(files)
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

-- Function to create command handler
function M.create_command_handler(func)
    return function(opts)
        local lang_override = opts.args and opts.args ~= "" and opts.args or nil
        func(lang_override)
    end
end

function M.create_language_completion(languages_config)
    return function()
        local langs = {}
        for lang, _ in pairs(languages_config) do
            table.insert(langs, lang)
        end
        return langs
    end
end

function M.create_subcommand_completion(subcommands, languages_config)
    return function(arg_lead, cmd_line, _)
        -- Split the command line to see what we're completing
        local args = vim.split(vim.trim(cmd_line), "%s+")

        -- If we're completing the first argument
        if #args <= 2 then
            local matches = {}
            -- Add subcommands
            for _, subcmd in ipairs(subcommands) do
                if subcmd:match("^" .. vim.pesc(arg_lead)) then
                    table.insert(matches, subcmd)
                end
            end
            return matches
        end

        -- If completing after a subcommand, offer languages
        if #args == 3 and languages_config then
            local matches = {}
            for lang, _ in pairs(languages_config) do
                if lang:match("^" .. vim.pesc(arg_lead)) then
                    table.insert(matches, lang)
                end
            end
            return matches
        end

        return {}
    end
end

-- Function to create new-style command handler with subcommand support
function M.create_subcommand_handler(handlers)
    return function(opts)
        local args = {}
        if opts.args and opts.args ~= "" then
            args = vim.split(vim.trim(opts.args), "%s+")
        end

        -- If no arguments, default to "new" action
        if #args == 0 then
            if handlers.new then
                handlers.new(nil) -- No language override
            else
                vim.notify("No default action available", vim.log.levels.ERROR)
            end
            return
        end

        local first_arg = args[1]
        local second_arg = args[2]

        -- Check if first argument is a known subcommand
        if handlers[first_arg] then
            handlers[first_arg](second_arg) -- second_arg might be language override
        else
            vim.notify("Unknown subcommand: " .. first_arg .. ". Available: " .. table.concat(vim.tbl_keys(handlers), ", "), vim.log.levels.ERROR)
        end
    end
end

return M
