# Comment Tasks

> **⚠️ BREAKING CHANGE**: The command structure has been updated to use explicit subcommands. `ClickUpTask python` no longer works - use `ClickUpTask new python`. See the [Migration Guide](#migration-guide) for full details.

A Neovim plugin that integrates multiple task management systems (ClickUp, GitHub Issues, Todoist, GitLab Issues) with code comments across multiple programming languages. Create, update, and manage tasks directly from your comments without leaving your editor.

## Features

- **Multi-Provider Support**: Works with ClickUp, GitHub Issues, Todoist, and GitLab Issues
- **Multi-Language Support**: Works with 15+ programming languages using Tree-sitter
- **Create Tasks from Comments**: Convert code comments into tasks across different platforms
- **Smart Comment Detection**: Handles single-line, block comments, and docstrings
- **Smart URL Insertion**: Single-line block comments get URLs on same line, multi-line get new line
- **Task Status Management**: Close tasks (ClickUp also supports in progress/review status)
- **Cross-Reference Tasks**: Automatically find and link source files to existing tasks (ClickUp)
- **File Reference Management**: Add structured file references to tasks
- **Comment Prefix Trimming**: Automatically clean TODO, FIXME, and other prefixes from task names
- **Language Override**: Force specific language detection when needed
- **Automatic Fallback**: Uses regex patterns when Tree-sitter unavailable
- **Bulk Operations**: Clean up and deduplicate SourceFiles across all tasks (ClickUp)
- **Modular Architecture**: Extensible provider system for easy addition of new task management platforms

## Supported Task Management Systems

- **ClickUp** - Full-featured with custom fields, status updates, and cross-referencing
- **GitHub Issues** - Create and manage issues with structured descriptions  
- **Todoist** - Create and complete tasks with file references
- **GitLab Issues** - Create and manage issues with labels and structured descriptions (supports both gitlab.com and self-hosted)

## Supported Languages

The plugin supports comment detection across multiple programming languages:

- **Python**: `#` comments and `"""` docstrings
- **JavaScript/TypeScript**: `//` and `/* */` comments
- **Lua**: `--` and `--[[]]` comments
- **Rust**: `//`, `///`, `//!` and `/* */` comments
- **C/C++**: `//` and `/* */` comments
- **Go**: `//` and `/* */` comments
- **Java**: `//`, `/* */` and `/** */` javadoc
- **Ruby**: `#` comments
- **PHP**: `//`, `#` and `/* */` comments
- **CSS**: `/* */` comments
- **HTML**: `<!-- -->` comments
- **Bash/Shell**: `#` comments
- **Vim Script**: `"` comments
- **YAML**: `#` comments
- **JSON**: `//` and `/* */` comments (with extensions)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "georgeharker/comment-tasks.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for HTTP requests
  },
  config = function()
    require("comment-tasks").setup({
      default_provider = "clickup", -- Default: "clickup", options: "github", "todoist", "gitlab"
      
      providers = {
        clickup = {
          enabled = true,
          api_key_env = "CLICKUP_API_KEY",
          list_id = "your_clickup_list_id",
          team_id = "your_clickup_team_id", -- Optional
        },
        
        github = {
          enabled = true,
          api_key_env = "GITHUB_TOKEN",
          repo_owner = "your_username",
          repo_name = "your_repository",
        },
        
        todoist = {
          enabled = false, -- Enable if you want to use Todoist
          api_key_env = "TODOIST_API_TOKEN",
          project_id = "your_project_id", -- Optional
        },
        
        gitlab = {
          enabled = true,
          api_key_env = "GITLAB_TOKEN",
          project_id = "12345", -- Numeric project ID
          gitlab_url = "https://gitlab.com", -- Optional: for self-hosted GitLab
        },
      },
      
      -- Optional: Custom keybinding for task creation
      keymap = "<leader>tc",
    })
  end
}
```

## Environment Variables Setup

Set up the required environment variables for the providers you want to use:

### ClickUp
```bash
export CLICKUP_API_KEY="your_clickup_api_key"
```
Get your API key from: ClickUp Settings > Apps > API

### GitHub
```bash
export GITHUB_TOKEN="your_github_personal_access_token"
```
Create a token at: GitHub Settings > Developer settings > Personal access tokens
Required scopes: `repo` (for private repos) or `public_repo` (for public repos)

### Todoist  
```bash
export TODOIST_API_TOKEN="your_todoist_api_token"
```
Get your token from: https://todoist.com/prefs/integrations

### GitLab
```bash
export GITLAB_TOKEN="your_gitlab_personal_access_token"
```
Create a token at: GitLab Settings > Access Tokens
Required scopes: `api` (for full API access)
Note: `project_id` should be the numeric project ID, not the project name

## Configuration Options

```lua
require("comment-tasks").setup({
  -- Default provider when using generic commands
  default_provider = "clickup", -- "clickup" | "github" | "todoist" | "gitlab"
  
  providers = {
    clickup = {
      enabled = true,                    -- Enable ClickUp integration
      api_key_env = "CLICKUP_API_KEY",  -- Environment variable name
      list_id = "list_id",              -- Required: ClickUp list ID
      team_id = "team_id",              -- Optional: ClickUp team ID  
          
          -- Optional: Configurable ClickUp statuses
          statuses = {
            new = "To Do",               -- Status for new tasks
            completed = "Complete",      -- Status for completed tasks  
            review = "Review",           -- Status for review tasks
            in_progress = "In Progress", -- Status for in-progress tasks
            
            -- Custom status mappings for your ClickUp workspace
            custom = {
              blocked = "Blocked",
              testing = "Testing", 
              cancelled = "Cancelled"
            }
          },
    },
    
    github = {
      enabled = true,                   -- Enable GitHub integration
      api_key_env = "GITHUB_TOKEN",     -- Environment variable name
      repo_owner = "username",          -- Required: GitHub username/org
      repo_name = "repository",         -- Required: Repository name
    },
    
    todoist = {
      enabled = true,                   -- Enable Todoist integration
      api_key_env = "TODOIST_API_TOKEN", -- Environment variable name  
      project_id = "project_id",        -- Optional: Specific project
    },
    
    gitlab = {
      enabled = true,                   -- Enable GitLab integration
      api_key_env = "GITLAB_TOKEN",     -- Environment variable name
      project_id = "12345",             -- Required: Numeric project ID
      gitlab_url = "https://gitlab.com", -- Optional: for self-hosted GitLab
    },
  },
  
  -- Comment prefixes to recognize and clean
  comment_prefixes = {
    "TODO", "FIXME", "BUG", "HACK", "WARN", "PERF", 
    "NOTE", "INFO", "TEST", "PASSED", "FAILED", 
    "FIX", "ISSUE", "XXX", "OPTIMIZE", "REVIEW", 
    "DEPRECATED", "REFACTOR", "CLEANUP"
  },
  
  -- Language configuration (can be extended)
  languages = {
    -- See example-config.lua for full language configuration options
  },
  
  -- Fallback to regex when Tree-sitter unavailable
  fallback_to_regex = true,
  
  -- Optional: Set a keybinding for default provider
  keymap = "<leader>tc",
})
```

## Usage

### Basic Commands

#### Generic Commands (use default provider)
```vim
:TaskCreate     " Create task from comment using default provider
:TaskClose      " Close task from comment
:TaskAddFile    " Add current file to task
```

#### Provider-Specific Commands
```vim
" ClickUp
:ClickUpTask         " Create ClickUp task (default: new)
:ClickUpTask new     " Create ClickUp task
:ClickUpTask close   " Close ClickUp task
:ClickUpTask review  " Set ClickUp task to review
:ClickUpTask progress " Set ClickUp task to in progress
:ClickUpTask addfile " Add file to ClickUp task SourceFiles

" ClickUp with custom statuses (if configured)
:ClickUpTask blocked     " Set to blocked status
:ClickUpTask testing     " Set to testing status  
:ClickUpTask cancelled   " Set to cancelled status
:ClickUpTask status <name> " Set to any custom status

" GitHub
:GitHubTask         " Create GitHub issue (default: new)
:GitHubTask new     " Create GitHub issue
:GitHubTask close   " Close GitHub issue
:GitHubTask addfile " Add file to GitHub issue

" Todoist  
:TodoistTask        " Create Todoist task (default: new)
:TodoistTask new    " Create Todoist task
:TodoistTask close  " Close Todoist task
:TodoistTask addfile " Add file to Todoist task

" GitLab
:GitLabTask         " Create GitLab issue (default: new)
:GitLabTask new     " Create GitLab issue
:GitLabTask close   " Close GitLab issue
:GitLabTask addfile " Add file to GitLab issue
```

#### ClickUp-Specific Bulk Operations
```vim
:ClickupTaskXref            " Cross-reference tasks with file locations
:ClickUpCleanupSourceFiles  " Clean up SourceFiles custom fields
:ClickUpClearResults        " Clear XRef results buffer
```

### Creating Tasks from Comments

Place your cursor on any comment containing TODO, FIXME, BUG, etc., then use the appropriate command:

```python
# TODO: Implement user authentication
# This function needs proper error handling
```

After running `:TaskCreate`, the URL will be added to your comment:

```python  
# TODO: Implement user authentication
# This function needs proper error handling
# https://app.clickup.com/t/abc123
```

Different providers will add their respective URL formats:
- **ClickUp**: `https://app.clickup.com/t/task_id`
- **GitHub**: `https://github.com/owner/repo/issues/123`
- **Todoist**: `https://todoist.com/showTask?id=task_id`
- **GitLab**: `https://gitlab.com/owner/project/-/issues/123`

### Task Status Management

For existing tasks (with URLs in comments), you can update status:

```vim
:TaskClose           " Close task (all providers)
                     " Works with ClickUp, GitHub, Todoist, and GitLab URLs
:ClickUpReview       " Set ClickUp task to review (ClickUp only)  
:ClickUpInProgress   " Set ClickUp task to in progress (ClickUp only)
```

**Status Support by Provider:**

**ClickUp Status Configuration:**
The ClickUp provider now supports configurable status names that match your workspace setup:
- Configure status names in your setup to match your ClickUp list statuses exactly
- Supports both predefined statuses (default, completed, review, in_progress) and custom statuses
- Status names are case-sensitive and must match your ClickUp workspace configuration
- If no status configuration is provided, falls back to legacy hardcoded names for backward compatibility

### File Reference Management

Add the current file to a task's file references:

```vim
:TaskAddFile         " Add current file to any task type
:ClickUpAddFile      " Add to ClickUp SourceFiles custom field (legacy)
```

**Provider-specific behavior:**
- **ClickUp**: Updates the SourceFiles custom field
- **GitHub**: Adds/updates a "Source Files" section in the issue body
- **Todoist**: Adds/updates a "Source Files" section in the task description
- **GitLab**: Adds/updates a "Source Files" section in the issue description

## Advanced Usage

### Language Override

Force specific language detection when the filetype detection is incorrect:

```vim
:TaskCreate python     " Force Python comment detection
:GitHubTask new rust   " Force Rust comment detection for GitHub
:GitLabTask new lua    " Force Lua comment detection for GitLab
:ClickUpTask close python " Close task with Python detection override
```

### Custom Keybindings

```lua
-- Multi-provider keybindings
vim.keymap.set("n", "<leader>tc", function()
       require("comment-tasks").create_task_from_comment()
end, { desc = "Create task (default provider)" })

-- Provider-specific keybindings  
vim.keymap.set("n", "<leader>tcc", function()
       require("comment-tasks").create_clickup_task_from_comment()
end, { desc = "Create ClickUp task" })

vim.keymap.set("n", "<leader>tcg", function()
       require("comment-tasks").create_github_task_from_comment()  
end, { desc = "Create GitHub issue" })

vim.keymap.set("n", "<leader>tct", function()
       require("comment-tasks").create_todoist_task_from_comment()
end, { desc = "Create Todoist task" })

vim.keymap.set("n", "<leader>tcl", function()
       require("comment-tasks").create_gitlab_task_from_comment()
end, { desc = "Create GitLab issue" })

vim.keymap.set("n", "<leader>tx", function()
       require("comment-tasks").close_task_from_comment()
end, { desc = "Close task" })
```

### Cross-Reference Operations (ClickUp Only)

The plugin can automatically find source files related to ClickUp tasks and update their SourceFiles custom field:

```vim
:ClickupTaskXref
```

This command will:
1. Search for task URLs in your codebase using ripgrep (with fallback to find)
2. Extract file references from task descriptions  
3. Update SourceFiles custom field with found files
4. Clean up task descriptions by removing filename references
5. Display results in a dedicated buffer

## Architecture

The plugin uses a modular architecture with:

- **Generic Provider Interface** - Standardized API for all task management systems
- **Core Modules** - Comment detection, configuration management, utilities
- **Provider Modules** - Isolated implementations for each task management system
- **Extensible Design** - Easy to add new providers following the interface

### File Structure
```
lua/comment-tasks/
├── init.lua                 # Main plugin entry point
├── providers/
│   ├── interface.lua        # Generic provider interface
│   ├── clickup.lua         # ClickUp provider
│   ├── github.lua          # GitHub provider
│   ├── todoist.lua         # Todoist provider
│   └── gitlab.lua          # GitLab provider
├── core/
│   ├── detection.lua       # Comment detection logic
│   ├── config.lua          # Configuration management
│   └── utils.lua           # Common utilities
└── tests/                  # Test suite
```

## Backward Compatibility

All existing ClickUp-focused commands and configurations continue to work. The plugin maintains full backward compatibility while adding multi-provider support.

Legacy configuration still works:
```lua
require("comment-tasks").setup({
  list_id = "your_clickup_list_id",    -- Still works
  api_key_env = "CLICKUP_API_KEY",     -- Still works  
  keymap = "<leader>tc",
})
```

## API Reference

### Main Functions

- `create_task_from_comment(lang_override, provider)` - Create task with specific provider
- `close_task_from_comment(lang_override)` - Close any task type
- `add_file_to_task_sources(lang_override)` - Add file to task references

### Provider-Specific Functions

- `create_clickup_task_from_comment(lang_override)` 
- `create_github_task_from_comment(lang_override)`
- `create_todoist_task_from_comment(lang_override)`
- `create_gitlab_task_from_comment(lang_override)`

### ClickUp-Specific Functions

- `review_task_from_comment(lang_override)` - Set task to review
- `in_progress_task_from_comment(lang_override)` - Set task to in progress  
- `clickup_task_xref()` - Cross-reference tasks with files
- `cleanup_sourcefiles()` - Clean up SourceFiles custom fields

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Adding New Providers

To add support for a new task management system:

1. Create a new provider file in `lua/comment-tasks/providers/`
2. Extend the base `Provider` class from `providers/interface.lua`
3. Implement all required methods (`create_task`, `update_task_status`, etc.)
4. Register the provider: `interface.register_provider("name", ProviderClass)`
5. Add configuration to `core/config.lua`
6. Add URL extraction patterns to `core/utils.lua`
7. Add provider-specific commands to the main plugin
8. Update documentation

The modular architecture makes it easy to add new providers while maintaining consistency across the plugin.

## Testing

The plugin includes a comprehensive test suite that covers:

- Comment detection across all supported languages
- Provider interface compliance
- Mock API interactions for all providers
- Configuration validation
- Error handling and edge cases

Run tests with:
```vim
:lua require("comment-tasks.tests").run_all()
```

## Migration Guide

### Command Structure Changes

The plugin has moved to a cleaner subcommand-based structure for better organization and intuitive usage.

### ClickUp Status Configuration (NEW)

The plugin now supports configurable ClickUp status names to match your workspace configuration.

#### Recommended: Configure Your Status Names
```lua
require("comment-tasks").setup({
  providers = {
    clickup = {
      enabled = true,
      api_key_env = "CLICKUP_API_KEY",
      list_id = "your_list_id",
      
      -- Configure to match your ClickUp workspace statuses
      statuses = {
        new = "To Do",               -- Exact name for new tasks in your ClickUp list
        completed = "Complete",      -- Exact name for completed status
        review = "Review",           -- Exact name for review status  
        in_progress = "In Progress", -- Exact name for in-progress status
        
        -- Add custom statuses used in your workspace
        custom = {
          blocked = "Blocked",
          testing = "Testing",
          cancelled = "Cancelled"
        }
      }
    }
  }
})
```

#### Backward Compatibility
If you don't configure status names, the plugin uses the original hardcoded values:
- `"to do"` for new tasks (configured via `new` status)

**Note:** If these hardcoded names don't exist in your ClickUp list, status updates may fail. Configure the correct names for your workspace.

#### Before (Deprecated)
```vim
:ClickUpTask           " Create task (optional language arg)
:ClickUpTask python    " Create task with Python language override
:ClickUpClose          " Close task
:ClickUpReview         " Set to review
:ClickUpInProgress     " Set to in progress
:ClickUpAddFile        " Add file to task

" Similar pattern for other providers
:GitHubTask
:GitHubClose
```

#### After (New Structure)
```vim
:ClickUpTask           " Create task (defaults to 'new')
:ClickUpTask new       " Create task explicitly
:ClickUpTask new python " Create task with Python language override
:ClickUpTask close     " Close task
:ClickUpTask review    " Set to review
:ClickUpTask progress  " Set to in progress (renamed from 'InProgress')
:ClickUpTask addfile   " Add file to task

" Consistent pattern for all providers
:GitHubTask new
:GitHubTask close
:TodoistTask new
:TodoistTask close
:GitLabTask new
:GitLabTask close
```

#### Backward Compatibility
- **Legacy commands removed**: `ClickUpClose`, `ClickUpReview`, etc. have been removed for a cleaner codebase
- **Language-only arguments removed**: `ClickUpTask python` no longer works - use `ClickUpTask new python`
- **Action required**: Update to new subcommand structure

#### Migration Steps
1. **Update your commands** to use the new subcommand structure (required)
2. **Update keybindings** if you prefer the new structure
3. **Update documentation** and scripts to reference new commands
4. **Replace legacy commands**: Change `ClickUpClose` to `ClickUpTask close`, etc.
5. **Replace language-only usage**: Change `ClickUpTask python` to `ClickUpTask new python`

All legacy commands have been removed for a cleaner, more maintainable codebase.

## License

MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter issues:

1. Check that your API keys are correctly set in environment variables
2. Verify provider configuration (list_id, repo_owner/repo_name, project_id, etc.)  
3. Ensure the comment is in a supported format and language
4. Try the "Force" version of commands to bypass language validation
5. Open an issue with details about your configuration and the error

## Acknowledgments

* olimorris' [CodeCompanion](https://codecompanion.olimorris.dev/)
  This plugin was developed due to a need, and a lack of time to loose focus.  I extensively used AI guided
  development to have Claude and Copilot pretty much write this - including docs - with guidance and direction from me, but little actual coding.
