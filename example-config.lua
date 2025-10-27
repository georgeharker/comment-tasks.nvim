-- Example configuration for comment-tasks.nvim
-- This shows how to configure multiple task management providers

local comment_tasks = require("comment-tasks")

comment_tasks.setup({
    -- Default provider to use when no specific provider is mentioned
    default_provider = "clickup", -- Options: "clickup", "github", "todoist"

    -- Provider configurations
    providers = {
        clickup = {
            enabled = true,
            api_key_env = "CLICKUP_API_KEY", -- Environment variable name
            list_id = "your_clickup_list_id", -- Required for ClickUp
            team_id = "your_clickup_team_id", -- Optional

            -- Configurable ClickUp statuses (optional)
            statuses = {
                -- All statuses in flat configuration
                new = "To Do",               -- Special: creates tasks (:ClickUpTask new)
                completed = "Complete",      -- Special: closes tasks (:ClickUpTask completed)
                review = "Review",           -- Regular status (:ClickUpTask review)
                in_progress = "In Progress", -- Regular status (:ClickUpTask in_progress)
                blocked = "Blocked",         -- Regular status (:ClickUpTask blocked)
                testing = "Testing",         -- Regular status (:ClickUpTask testing)
                cancelled = "Cancelled",     -- Regular status (:ClickUpTask cancelled)
                waiting = "Waiting for Approval" -- Regular status (:ClickUpTask waiting)
            },
        },

        github = {
            enabled = true,
            api_key_env = "GITHUB_TOKEN", -- GitHub Personal Access Token
            repo_owner = "your_username", -- GitHub username or organization
            repo_name = "your_repository", -- Repository name
            -- GitHub simple workflow
            statuses = {
                new = "open",        -- Special: creates issues
                completed = "closed" -- Special: closes issues
            },
        },

        todoist = {
            enabled = true,
            api_key_env = "TODOIST_API_TOKEN", -- Todoist API token
            project_id = "your_project_id", -- Optional: specific project ID
            -- Todoist task workflow
            statuses = {
                new = "incomplete",  -- Special: creates tasks
                completed = "complete" -- Special: completes tasks
            },
        },

        gitlab = {
            enabled = true,
            api_key_env = "GITLAB_TOKEN", -- GitLab Personal Access Token
            project_id = "12345", -- GitLab project ID (numeric)
            gitlab_url = "https://gitlab.com", -- Optional: for self-hosted GitLab
            -- GitLab issue workflow
            statuses = {
                new = "opened",      -- Special: creates issues
                completed = "closed" -- Special: closes issues
            },
        },

        linear = {
            enabled = true,
            api_key_env = "LINEAR_API_KEY", -- Linear API key
            team_id = "team_abc123", -- Required: Linear team ID
            project_id = "project_def456", -- Optional: specific project
            -- Linear supports both name resolution and direct state IDs
            statuses = {
                new = "Backlog",              -- Special: creates issues (name resolution)
                completed = "Done",           -- Special: closes issues (name resolution)
                review = "In Review",         -- Regular status (name resolution)
                in_progress = "In Development", -- Regular status (name resolution)
                blocked = "Blocked",          -- Regular status (name resolution)
                -- Use # prefix for direct Linear state IDs (if you know them):
                urgent = "#state_abc123",     -- Regular status (direct state ID)
                archived = "#state_def456"    -- Regular status (direct state ID)
            },
        },
    },

    -- Comment prefixes to recognize (applies to all providers)
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

    -- Language support and Tree-sitter configuration
    languages = {
        -- You can extend or override language configurations here
        -- See the main plugin file for the full language configuration
    },

    -- Fallback to regex if Tree-sitter is unavailable
    fallback_to_regex = true,
})

-- Example keybindings

vim.keymap.set("n", "<leader>tcc", function()
    require("comment-tasks").create_task_from_comment(nil, "clickup")
end, { desc = "Create ClickUp task" })

vim.keymap.set("n", "<leader>tcg", function()
    require("comment-tasks").create_task_from_comment(nil, "github")
end, { desc = "Create GitHub issue" })

-- Generic keybindings (use default_provider)
vim.keymap.set("n", "<leader>tc", function()
    require("comment-tasks").create_task_from_comment()
end, { desc = "Create task (default provider)" })

vim.keymap.set("n", "<leader>tx", function()
    require("comment-tasks").close_task_from_comment()
end, { desc = "Close task" })

vim.keymap.set("n", "<leader>tct", function()
    require("comment-tasks").create_task_from_comment(nil, "todoist")
end, { desc = "Create Todoist task" })

vim.keymap.set("n", "<leader>tcl", function()
    require("comment-tasks").create_task_from_comment(nil, "gitlab")
end, { desc = "Create GitLab issue" })

vim.keymap.set("n", "<leader>tf", function()
    require("comment-tasks").add_file_to_task_sources()
end, { desc = "Add file to task" })

--[[
Environment Variables Setup:

Features:

✓ Multi-provider support (ClickUp, GitHub, Todoist)
✓ Enhanced vim.notify integration with provider-specific titles
✓ Tree-sitter based comment detection with regex fallback
✓ Smart URL detection and task management across providers
✓ Cross-reference capabilities for ClickUp (ripgrep + fallback)
✓ Structured file reference management per provider

Notifications:

The plugin uses a unified vim.notify system with provider-specific titles:

✓ Success notifications: "GitHub Success", "Todoist Success", "ClickUp Success"
⚠ Warning notifications: "GitHub Warning", "Todoist Warning", "ClickUp Warning"
✗ Error notifications: "GitHub Error", "Todoist Error", "ClickUp Error"
ℹ Info notifications: "GitHub Tasks", "Todoist Tasks", "ClickUp Tasks"

Benefits:
- Works seamlessly with nvim-notify and other notification plugins
- Consistent visual symbols across all providers
- Proper log levels (ERROR, WARN, INFO) for filtering
- Provider context in notification titles
- No more legacy echo_message system

1. ClickUp:
   export CLICKUP_API_KEY="your_clickup_api_key"

2. GitHub:
   export GITHUB_TOKEN="your_github_personal_access_token"

   Note: The token needs the following scopes:
   - repo (for private repositories)
   - public_repo (for public repositories)

3. Todoist:
   export TODOIST_API_TOKEN="your_todoist_api_token"

   You can get this from: https://todoist.com/prefs/integrations

4. GitLab:
   export GITLAB_TOKEN="your_gitlab_personal_access_token"

   You can get this from: GitLab Settings > Access Tokens
   Required scopes: api (for full API access)
   Note: project_id should be the numeric project ID, not the project name

Usage Examples:

1. Generic commands (use default provider):
   :TaskCreate          - Create task from comment
   :TaskClose           - Close task from comment
   :TaskAddFile         - Add current file to task

2. Provider-specific commands:
   :ClickUpTask         - Create ClickUp task
   :GitHubTask          - Create GitHub issue
   :TodoistTask         - Create Todoist task
   :GitLabTask          - Create GitLab issue

3. ClickUp status commands (NEW - configurable statuses):
   :ClickUpTask new             - Create ClickUp task
   :ClickUpTask close           - Close ClickUp task (uses configured 'completed' status)
   :ClickUpTask review          - Set to review (uses configured 'review' status)
   :ClickUpTask progress        - Set to in progress (uses configured 'in_progress' status)
   :ClickUpTask blocked         - Set to blocked (uses custom 'blocked' status if configured)
   :ClickUpTask status Testing  - Set to any custom status
   :ClickUpTask cancelled       - Set to cancelled (uses custom 'cancelled' status if configured)

   Examples with language override:
   :ClickUpTask blocked python  - Set to blocked status with Python language detection
   :ClickUpTask status Testing javascript - Set to Testing status with JavaScript detection

4. ClickUp-specific commands (backward compatibility):
   :ClickupTaskXref     - Cross-reference bugs with file locations
   :ClickUpCleanupSourceFiles - Clean up SourceFiles custom fields
   :ClickUpClearResults - Clear XRef results

Supported Comment Formats:

# TODO: Fix this bug
// FIXME: Handle edge case
/* BUG: Memory leak in this function */
-- NOTE: This needs optimization

After creating a task, the URL will be added to your comment:
# TODO: Fix this bug
# https://app.clickup.com/t/task_id

Different providers will have different URL formats:
- ClickUp: https://app.clickup.com/t/task_id
- GitHub: https://github.com/owner/repo/issues/123
- Todoist: https://todoist.com/showTask?id=task_id
--]]
