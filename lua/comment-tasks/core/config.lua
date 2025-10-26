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
                new = "to do",               -- Status for new tasks
                completed = "complete",      -- Status for completed tasks
                review = "review",           -- Status for review tasks
                in_progress = "in progress", -- Status for in-progress tasks
                -- Custom status mappings can be added by users
                custom = {}
            },
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
        gitlab = {
            api_key_env = "GITLAB_TOKEN",
            project_id = nil,
            gitlab_url = "https://gitlab.com", -- Can be overridden for self-hosted
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

    -- Check predefined statuses first
    if statuses[status_name] then
        return statuses[status_name]
    end

    -- Check custom statuses
    if statuses.custom and statuses.custom[status_name] then
        return statuses.custom[status_name]
    end

    -- Return the status name as-is if not found (allows direct status names)
    return status_name
end

function M.get_clickup_available_statuses()
    local clickup_config = M.get_provider_config("clickup")
    if not clickup_config or not clickup_config.statuses then
        return {"new", "completed", "review", "in_progress"}
    end

    local available = {}
    local statuses = clickup_config.statuses

    -- Add predefined statuses
    for key, _ in pairs(statuses) do
        if key ~= "custom" then
            table.insert(available, key)
        end
    end

    -- Add custom statuses
    if statuses.custom then
        for key, _ in pairs(statuses.custom) do
            table.insert(available, key)
        end
    end

    table.sort(available)
    return available
end
return M
