# Configuration Reference

Complete configuration guide for comment-tasks.nvim with all available options and examples.

## Basic Configuration Structure

```lua
require("comment-tasks").setup({
    -- Global settings
    default_provider = "clickup",  -- Which provider to use for generic commands
    
    -- Language and comment detection
    languages = {
        -- Language-specific configuration (optional)
    },
    
    -- Provider configurations
    providers = {
        -- Configure only the providers you use
        clickup = { /* ClickUp config */ },
        github = { /* GitHub config */ },
        asana = { /* Asana config */ },
        -- ... other providers
    }
})
```

## Core Concepts

### Default Provider

The `default_provider` determines which provider handles generic commands:

```lua
default_provider = "clickup"  -- Use ClickUp for :CommentTask commands
default_provider = "github"   -- Use GitHub for :CommentTask commands
```

**Generic vs Provider-Specific Commands**:
- **Generic**: `:CommentTask new` (uses default_provider)
- **Provider-Specific**: `:ClickUpTask new` (always uses ClickUp)

### Dynamic Status System

Each provider's available commands are generated from your status configuration:

```lua
providers = {
    clickup = {
        statuses = {
            new = "To Do",           -- Creates :ClickUpTask new command
            completed = "Complete",  -- Creates :ClickUpTask completed command  
            review = "Code Review",  -- Creates :ClickUpTask review command
            blocked = "Blocked",     -- Creates :ClickUpTask blocked command
        }
    }
}
```

**Special Statuses**:
- **`new`** - Always used for task creation (required)
- **`completed`** - Used for task completion (recommended)  
- **Others** - Create corresponding update commands

## Provider Configurations

### Full Custom Status Providers

These providers support complete workflow customization:

#### ClickUp

```lua
clickup = {
    enabled = true,
    api_key_env = "CLICKUP_API_KEY",        -- Environment variable name
    list_id = "123456789",                  -- Required: ClickUp list ID
    team_id = "987654321",                  -- Optional: team ID for performance
    
    statuses = {
        new = "To Do",
        completed = "Complete", 
        in_progress = "In Progress",
        review = "Code Review",
        blocked = "Blocked",
        testing = "QA Testing",
    },
    
    -- Optional advanced settings
    default_assignee = "user_id",           -- Default assignee for new tasks
    default_priority = 3,                   -- 1=urgent, 2=high, 3=normal, 4=low
    custom_fields = {
        source_files = "SourceFiles",       -- Field name for file tracking
    }
}
```

#### Asana

```lua
asana = {
    enabled = true,
    api_key_env = "ASANA_ACCESS_TOKEN",
    project_gid = "1204558436732296",       -- Required: Asana project GID
    assignee_gid = "1204558436732297",      -- Optional: default assignee GID
    
    statuses = {
        new = "Not Started",
        completed = "Complete",
        review = "Review", 
        in_progress = "In Progress",
        blocked = "Blocked",
        waiting = "Waiting on Others",
    },
    
    -- Optional settings
    task_defaults = {
        notes = "Created from code comment",
        due_on = nil,                       -- Default due date (YYYY-MM-DD)
    }
}
```

#### Linear

```lua
linear = {
    enabled = true,
    api_key_env = "LINEAR_API_KEY", 
    team_id = "team_id_here",               -- Required: Linear team ID
    
    statuses = {
        new = "Backlog",
        completed = "Done",
        in_progress = "In Progress", 
        review = "In Review",
        cancelled = "Canceled",
    },
    
    -- Optional settings
    default_labels = {"bug", "feature"},    -- Default labels for new issues
    default_assignee = "user_id",           -- Default assignee ID
}
```

#### Jira

```lua
jira = {
    enabled = true,
    url = "https://your-domain.atlassian.net",  -- Jira instance URL
    username_env = "JIRA_USERNAME",             -- Environment variable for username
    api_token_env = "JIRA_API_TOKEN",           -- Environment variable for API token  
    project_key = "PROJ",                       -- Required: Jira project key
    
    statuses = {
        new = "To Do",
        completed = "Done",
        in_progress = "In Progress",
        review = "In Review", 
        blocked = "Blocked",
    },
    
    -- Optional settings
    issue_type = "Task",                        -- Default issue type
    default_assignee = "username",              -- Default assignee username
}
```

#### Notion

```lua
notion = {
    enabled = true,
    api_key_env = "NOTION_TOKEN",
    database_id = "database_id_here",           -- Required: Notion database ID
    
    statuses = {
        new = "Not started", 
        completed = "Done",
        in_progress = "In progress",
        review = "Review",
    },
    
    -- Optional settings  
    title_property = "Name",                    -- Property name for task title
    status_property = "Status",                 -- Property name for status
    url_property = "URL",                       -- Property name for URL storage
}
```

#### Monday.com

```lua
monday = {
    enabled = true,
    api_key_env = "MONDAY_API_TOKEN",
    board_id = "123456789",                     -- Required: Monday.com board ID
    
    statuses = {
        new = "Stuck",
        completed = "Done", 
        in_progress = "Working on it",
        review = "Review",
    },
    
    -- Optional settings
    group_id = "topics",                        -- Default group for new items
    default_assignee = "user_id",               -- Default assignee ID
}
```

### Basic Status Providers

These providers have simpler status models:

#### GitHub Issues

```lua
github = {
    enabled = true,
    api_key_env = "GITHUB_TOKEN",
    repo_owner = "username",                    -- Required: GitHub username/org
    repo_name = "repository",                   -- Required: repository name
    
    -- Optional settings
    default_labels = {"bug", "enhancement"},    -- Default labels for issues
    default_assignee = "username",              -- Default assignee username
    default_milestone = 1,                      -- Default milestone ID
}
```

#### GitLab Issues

```lua
gitlab = {
    enabled = true,
    api_key_env = "GITLAB_TOKEN", 
    url = "https://gitlab.com",                 -- GitLab instance URL
    project_id = "12345678",                    -- Required: GitLab project ID
    
    -- Optional settings
    default_labels = ["bug", "feature"],        -- Default labels for issues  
    default_assignee = "username",              -- Default assignee username
}
```

#### Trello

```lua
trello = {
    enabled = true,
    api_key_env = "TRELLO_API_KEY",
    token_env = "TRELLO_TOKEN", 
    board_id = "board_id_here",                 -- Required: Trello board ID
    list_id = "list_id_here",                   -- Required: Trello list ID
}
```

#### Todoist

```lua
todoist = {
    enabled = true,
    api_key_env = "TODOIST_API_TOKEN",
    project_id = "project_id",                  -- Optional: Todoist project ID
    
    -- Optional settings
    default_labels = ["coding", "bug"],         -- Default labels for tasks
    default_priority = 2,                       -- 1=normal, 2=high, 3=very high, 4=urgent
}
```

## Language Configuration

### Supported Languages

The plugin automatically detects comments in 15+ languages using Tree-sitter:

```lua
languages = {
    -- Override default comment patterns (optional)
    python = {
        single_line = "#",
        block_start = '"""',
        block_end = '"""'
    },
    
    javascript = {
        single_line = "//", 
        block_start = "/*",
        block_end = "*/"
    },
    
    -- Add custom language support
    custom_lang = {
        single_line = "--",
        block_start = "--[[",
        block_end = "]]"
    }
}
```

### Language Override

Force specific language detection:

```vim
" Use with any provider command
:ClickUpTask new javascript    " Treat current buffer as JavaScript
:GitHubTask new python         " Treat current buffer as Python
```

## Environment Variables

### Required Environment Variables

Set these for the providers you use:

```bash
# ClickUp
export CLICKUP_API_KEY="your_api_key"

# Asana  
export ASANA_ACCESS_TOKEN="your_token"

# Linear
export LINEAR_API_KEY="your_api_key"

# Jira
export JIRA_USERNAME="your_email@domain.com"
export JIRA_API_TOKEN="your_api_token"

# Notion
export NOTION_TOKEN="your_integration_token"

# Monday.com
export MONDAY_API_TOKEN="your_api_token"

# GitHub
export GITHUB_TOKEN="your_personal_access_token"

# GitLab
export GITLAB_TOKEN="your_personal_access_token" 

# Trello
export TRELLO_API_KEY="your_api_key"
export TRELLO_TOKEN="your_token"

# Todoist
export TODOIST_API_TOKEN="your_api_token"
```

### Environment Variable Customization

Change environment variable names in configuration:

```lua
providers = {
    clickup = {
        api_key_env = "MY_CUSTOM_CLICKUP_KEY",  -- Use different env var name
    }
}
```

## Advanced Configuration

### Project-Level Configuration (`.comment-tasks.json`)

Instead of switching configs based on `getcwd()`, place a `.comment-tasks.json`
file at your project root. The plugin finds it automatically and applies
overrides for the duration of each command — your Neovim config is never
mutated.

#### How root detection works

When a command runs, the plugin walks upward from the current file's directory:

1. **`.comment-tasks.json` is checked first** at every ancestor directory. If
   found, that directory is the project root.
2. **Root markers** (`.git`, `pyproject.toml`, `package.json`, etc.) act as a
   ceiling — the first one found becomes the root.
3. Falls back to **git worktree detection** (supports `.git` files used by
   `git worktree`).

`.comment-tasks.json` always takes priority. If your repo has nested
`package.json` files in subdirectories, the config file higher up still wins.

#### Config layering

```
M.default_config           — built-in defaults, never mutated
    ↓ merged at setup()
M.config                   — your Neovim config (permanent after setup)
    ↓ deep-copied per command invocation
effective_config           — ephemeral, includes .comment-tasks.json overrides
```

`M.config` is never touched after `setup()`. A fresh deep copy is made for
each command, project overrides applied, then discarded.

#### Example `.comment-tasks.json`

```json
{
    "default_provider": "clickup",
    "providers": {
        "clickup": {
            "list_id": "9012345678",
            "team_id": "1234567"
        },
        "github": {
            "repo_owner": "acme-corp",
            "repo_name": "backend-api"
        },
        "jira": {
            "project_key": "BACKEND",
            "server_url": "https://acme.atlassian.net"
        }
    }
}
```

Only the fields you include are overridden. Absent fields fall through to your
Neovim config.

#### Override allowlist

For safety, only project-targeting fields can be overridden per-project. API
keys and the `enabled` flag are never read from the project file:

| Provider | Overridable fields |
|----------|--------------------|
| ClickUp  | `list_id`, `team_id` |
| GitHub   | `repo_owner`, `repo_name` |
| GitLab   | `project_id`, `gitlab_url` |
| Jira     | `project_key`, `server_url` |
| Linear   | `team_id`, `project_id` |
| Asana    | `project_gid`, `assignee_gid` |
| Todoist  | `project_id` |
| Notion   | `database_id` |
| Trello   | `list_id` |
| Monday   | `board_id` |

### Root Markers

Root markers define the project boundary — the ceiling for the upward search.
`.comment-tasks.json` is **not** a root marker; it is always checked
independently at every directory level during the walk-up, so it does not
need to appear in this list.

The default markers cover most ecosystems:

```
.git, pyproject.toml, setup.py, setup.cfg, Pipfile, package.json,
Cargo.toml, go.mod, Gemfile, pom.xml, build.gradle, build.gradle.kts,
CMakeLists.txt, *.sln, *.csproj, .editorconfig
```

Override or replace the list in `setup()`:

```lua
require("comment-tasks").setup({
    -- Replace the entire list
    root_markers = { ".git", "pyproject.toml", "Cargo.toml" },
    -- ...
})
```

To extend the defaults, copy them and append:

```lua
local defaults = require("comment-tasks.core.config").default_config.root_markers
local my_markers = vim.deepcopy(defaults)
table.insert(my_markers, ".my-custom-root-file")

require("comment-tasks").setup({
    root_markers = my_markers,
})
```

### Conditional Provider Loading

Enable providers based on environment:

```lua
local is_work_machine = vim.env.WORK_ENV == "1"

require("comment-tasks").setup({
    providers = {
        -- Work providers
        clickup = {
            enabled = is_work_machine,
            -- ... ClickUp config
        },
        
        -- Personal providers  
        github = {
            enabled = not is_work_machine,
            -- ... GitHub config
        }
    }
})
```

### Multi-Provider Setup

Use different providers for different types of tasks:

```lua
require("comment-tasks").setup({
    default_provider = "clickup",  -- Primary work tracking
    
    providers = {
        clickup = {
            enabled = true,
            -- ... work task configuration
        },
        
        github = {
            enabled = true, 
            -- ... code issue tracking
        },
        
        todoist = {
            enabled = true,
            -- ... personal task tracking  
        }
    }
})
```

## Validation and Debugging

### Configuration Validation

The plugin validates your configuration on startup. Common errors:

- **Missing required fields**: `list_id`, `project_id`, etc.
- **Invalid environment variables**: Undefined or empty env vars
- **Status configuration**: Missing `new` status

### Debug Commands

Check your configuration:

```vim
:lua print(vim.inspect(require("comment-tasks").get_config()))
:lua print(vim.inspect(require("comment-tasks").get_providers()))
```

Test provider connections:

```vim
:ClickUpTask test        " Test ClickUp connection (if supported)
:AsanaTask test          " Test Asana connection (if supported)
```

### Common Configuration Issues

1. **Provider not loading**: Check `enabled = true` and required fields
2. **Commands not available**: Verify status configuration includes `new`
3. **API errors**: Validate environment variables and API keys
4. **Status not found**: Ensure status names match provider exactly

## Migration and Updates

### Updating Configuration

When updating from older versions:

1. **Check changelog**: Review breaking changes
2. **Update status format**: Migrate to flat status configuration
3. **Test commands**: Verify all commands work as expected

### Configuration Backup

Save your working configuration:

```lua
-- Save in a separate file for backup
local my_config = {
    default_provider = "clickup",
    providers = {
        -- ... your working configuration
    }
}

require("comment-tasks").setup(my_config)
```

For more specific provider setup, see the individual provider documentation in [providers/](providers/).