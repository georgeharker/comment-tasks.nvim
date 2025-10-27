-- Configuration management for comment-tasks plugin

local M = {}

-- Default configuration
M.default_config = {
    default_provider = "clickup",

    providers = {
        clickup = {
            api_key_env = "CLICKUP_API_KEY",
            list_id = nil,
            team_id = nil,
            enabled = true,
            -- Configurable ClickUp statuses
            statuses = {
                new = "to do",               -- Special: Status for new tasks (creates tasks)
                completed = "complete",      -- Special: Status for completed tasks (closes tasks)
                review = "review",           -- Regular status update
                in_progress = "in progress", -- Regular status update
                blocked = "blocked",         -- Regular status update
                testing = "testing"          -- Regular status update
            },
        },
        github = {
            api_key_env = "GITHUB_TOKEN",
            repo_owner = nil,
            repo_name = nil,
            enabled = false,
            -- GitHub only has open/closed states
            statuses = {
                new = "open",        -- Special: Status for new issues (creates issues)
                completed = "closed" -- Special: Status for completed issues (closes issues)
            },
        },
        todoist = {
            api_key_env = "TODOIST_API_TOKEN",
            project_id = nil,
            enabled = false,
            -- Todoist uses complete/incomplete model
            statuses = {
                new = "incomplete",  -- Special: Status for new tasks (creates tasks)
                completed = "complete" -- Special: Status for completed tasks (closes tasks)
            },
        },
        gitlab = {
            api_key_env = "GITLAB_TOKEN",
            project_id = nil,
            gitlab_url = "https://gitlab.com", -- Can be overridden for self-hosted
            enabled = false,
            -- GitLab issue states
            statuses = {
                new = "opened",      -- Special: Status for new issues (creates issues)
                completed = "closed" -- Special: Status for completed issues (closes issues)
            },
        },
        asana = {
            api_key_env = "ASANA_ACCESS_TOKEN",
            project_gid = nil,
            assignee_gid = nil, -- Optional: default assignee for new tasks
            enabled = false,
            -- Configurable Asana statuses
            statuses = {
                new = "Not Started",         -- Special: Status for new tasks (creates tasks)
                completed = "Complete",      -- Special: Status for completed tasks (closes tasks)
                review = "Review",           -- Regular status update
                in_progress = "In Progress", -- Regular status update
                blocked = "Blocked"          -- Regular status update
            },
        },
        linear = {
            api_key_env = "LINEAR_API_KEY",
            team_id = nil,
            project_id = nil, -- Optional: specific project
            assignee_id = nil, -- Optional: default assignee
            priority = 0, -- 0=none, 1=urgent, 2=high, 3=medium, 4=low
            enabled = false,
            -- Configurable Linear statuses - can use names or state IDs
            statuses = {
                new = "Todo",                -- Special: Creates issues (name resolution)
                completed = "Done",          -- Special: Closes issues (name resolution)
                review = "In Review",        -- Regular status (name resolution)
                in_progress = "In Progress", -- Regular status (name resolution)
                backlog = "Backlog",         -- Regular status (name resolution)
                -- Use # prefix for direct Linear state IDs:
                -- blocked = "#state_12345", -- Regular status (direct state ID)
            },
        },
        jira = {
            api_key_env = "JIRA_API_TOKEN",
            server_url = "https://your-domain.atlassian.net",
            project_key = nil, -- Required: Jira project key (e.g., "PROJ")
            issue_type = "Task", -- Default issue type
            enabled = false,
            -- Configurable Jira statuses (must match workflow)
            statuses = {
                new = "To Do",               -- Special: Status for new issues (creates issues)
                completed = "Done",          -- Special: Status for completed issues (closes issues)
                review = "In Review",        -- Regular status update
                in_progress = "In Progress", -- Regular status update
                blocked = "Blocked"          -- Regular status update
            },
        },
        notion = {
            api_key_env = "NOTION_API_KEY",
            database_id = nil, -- Required: Notion database ID for tasks
            enabled = false,
            -- Configurable Notion statuses (must match database status property)
            statuses = {
                new = "Not started",         -- Special: Status for new tasks (creates tasks)
                completed = "Done",          -- Special: Status for completed tasks (closes tasks)
                review = "In review",        -- Regular status update
                in_progress = "In progress", -- Regular status update
                ready = "Ready for review"   -- Regular status update
            },
        },
        monday = {
            api_key_env = "MONDAY_API_TOKEN",
            board_id = nil, -- Required: Monday.com board ID
            group_id = nil, -- Optional: specific group within board
            enabled = false,
            -- Configurable Monday.com statuses (must match board status column)
            statuses = {
                new = "Not Started",         -- Special: Status for new items (creates items)
                completed = "Done",          -- Special: Status for completed items (closes items)
                review = "Review",           -- Regular status update
                in_progress = "Working on it", -- Regular status update
                stuck = "Stuck"              -- Regular status update
            },
        },
        trello = {
            api_key_env = "TRELLO_API_KEY",
            api_secret_env = "TRELLO_API_SECRET", -- Trello requires both key and secret
            board_id = nil, -- Required: Trello board ID
            -- Trello uses lists as statuses
            statuses = {
                new = "To Do",        -- Special: List for new cards (creates cards)
                completed = "Done",   -- Special: List for completed cards (closes cards)
                in_progress = "Doing", -- Regular status update (moves to list)
                review = "Review"     -- Regular status update (moves to list)
            },
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

-- Current configuration (will be merged with user config)
M.config = vim.deepcopy(M.default_config)

-- Setup configuration with user options
function M.setup(user_config)
    user_config = user_config or {}

    -- Merge user config with defaults
    M.config = vim.tbl_deep_extend("force", M.default_config, user_config)

    -- Legacy compatibility: map old ClickUp-specific options
    if user_config.list_id then
        M.config.providers.clickup.list_id = user_config.list_id
    end

    if user_config.team_id then
        M.config.providers.clickup.team_id = user_config.team_id
    end

    if user_config.api_key_env then
        M.config.providers.clickup.api_key_env = user_config.api_key_env
    end

    return M.config
end

-- Get current configuration
function M.get_config()
    return M.config
end

-- Get provider configuration
function M.get_provider_config(provider_name)
    return M.config.providers[provider_name]
end

-- Check if provider is enabled
function M.is_provider_enabled(provider_name)
    local provider_config = M.get_provider_config(provider_name)
    return provider_config and provider_config.enabled or false
end

-- Get enabled providers
function M.get_enabled_providers()
    local enabled = {}
    for name, provider_config in pairs(M.config.providers) do
        if provider_config.enabled then
            table.insert(enabled, name)
        end
    end
    table.sort(enabled)
    return enabled
end

-- Validate configuration
function M.validate_config()
    local warnings = {}
    local errors = {}

    -- Check if any providers are enabled
    local enabled_providers = M.get_enabled_providers()
    if #enabled_providers == 0 then
        table.insert(warnings, "No providers are enabled")
    end

    -- Validate specific provider configurations
    for name, provider_config in pairs(M.config.providers) do
        if provider_config.enabled then
            -- ClickUp validation
            if name == "clickup" and not provider_config.list_id then
                table.insert(warnings, "ClickUp provider enabled but list_id not configured")
            end

            -- GitHub validation
            if name == "github" and (not provider_config.repo_owner or not provider_config.repo_name) then
                table.insert(warnings, "GitHub provider enabled but repo_owner/repo_name not configured")
            end

            -- GitLab validation
            if name == "gitlab" and not provider_config.project_id then
                table.insert(warnings, "GitLab provider enabled but project_id not configured")
            end
        end
    end

    return {
        warnings = warnings,
        errors = errors,
        enabled_providers = enabled_providers
    }
end

function M.get_clickup_status(status_name)
    local clickup_config = M.get_provider_config("clickup")
    if not clickup_config or not clickup_config.statuses then
        -- Fallback to hardcoded values for backward compatibility
        local fallback_statuses = {
            new = "to do",
            completed = "complete",
            review = "review",
            in_progress = "in progress"
        }
        return fallback_statuses[status_name] or status_name
    end

    local statuses = clickup_config.statuses

    -- Check configured statuses
    if statuses[status_name] then
        return statuses[status_name]
    end

    -- Return the status name as-is if not found (allows direct status names)
    return status_name
end

function M.get_provider_available_statuses(provider_name)
    local provider_config = M.get_provider_config(provider_name)
    if not provider_config or not provider_config.statuses then
        -- Default statuses for providers without configuration
        return {"new", "completed"}
    end

    local available = {}
    local statuses = provider_config.statuses

    -- Add all configured statuses
    for key, _ in pairs(statuses) do
        table.insert(available, key)
    end

    table.sort(available)
    return available
end

function M.get_clickup_available_statuses()
    local clickup_config = M.get_provider_config("clickup")
    if not clickup_config or not clickup_config.statuses then
        return {"new", "completed", "review", "in_progress"}
    end

    local available = {}
    local statuses = clickup_config.statuses

    -- Add all configured statuses
    for key, _ in pairs(statuses) do
        table.insert(available, key)
    end

    table.sort(available)
    return available
end

return M
