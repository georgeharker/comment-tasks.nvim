# Comment Tasks

A Neovim plugin that integrates multiple task management systems (ClickUp, GitHub Issues, Todoist) with code comments across multiple programming languages. Create, update, and manage tasks directly from your comments without leaving your editor.

## Features

- **Multi-Provider Support**: Works with ClickUp, GitHub Issues, and Todoist
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
      default_provider = "clickup", -- Default: "clickup", options: "github", "todoist"
      
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

## Configuration Options

```lua
require("comment-tasks").setup({
  -- Default provider when using generic commands
  default_provider = "clickup", -- "clickup" | "github" | "todoist"
  
  providers = {
    clickup = {
      enabled = true,                    -- Enable ClickUp integration
      api_key_env = "CLICKUP_API_KEY",  -- Environment variable name
      list_id = "list_id",              -- Required: ClickUp list ID
      team_id = "team_id",              -- Optional: ClickUp team ID  
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
:ClickUpTask        " Create ClickUp task
:ClickUpClose       " Close ClickUp task  
:ClickUpReview      " Set ClickUp task to review
:ClickUpInProgress  " Set ClickUp task to in progress
:ClickUpAddFile     " Add file to ClickUp task SourceFiles

" GitHub
:GitHubTask         " Create GitHub issue
:GitHubClose        " Close GitHub issue

" Todoist  
:TodoistTask        " Create Todoist task
:TodoistClose       " Close Todoist task
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

**Single-line block comments** (C/C++/Java/CSS) get URLs inserted on the same line:

```c
/* TODO: write this function */
```

Becomes:

```c
/* TODO: write this function https://app.clickup.com/t/abc123 */
```

**Multi-line block comments** get URLs inserted as new lines:

```c
/*
 * TODO: write this function
 * Need to handle error cases
 */
```

Becomes:

```c
/*
 * TODO: write this function
 * Need to handle error cases
 * https://app.clickup.com/t/abc123
 */
```

Different providers will add their respective URL formats:
- **ClickUp**: `https://app.clickup.com/t/task_id`
- **GitHub**: `https://github.com/owner/repo/issues/123`
- **Todoist**: `https://todoist.com/showTask?id=task_id`

### Task Status Management

For existing tasks (with URLs in comments), you can update status:

```vim
:TaskClose           " Close task (all providers)
                     " Works with ClickUp, GitHub, and Todoist URLs
:ClickUpReview       " Set ClickUp task to review (ClickUp only)  
:ClickUpInProgress   " Set ClickUp task to in progress (ClickUp only)
```

**Status Support by Provider:**
- **ClickUp**: Full status management (complete, in progress, review, etc.)
- **GitHub**: Open/Close issues (maps "complete"/"closed" to "closed" state)
- **Todoist**: Close tasks (maps "complete"/"closed" to task completion)

**Example Usage:**
```python
# TODO: Fix authentication bug
# https://github.com/user/repo/issues/123
```
Running `:TaskClose` or `:GitHubClose` will close GitHub issue #123.

```python
# FIXME: Handle edge case  
# https://todoist.com/showTask?id=456789
```
Running `:TaskClose` or `:TodoistClose` will mark Todoist task as complete.

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

## Advanced Usage

### Language Override

Force specific language detection when the filetype detection is incorrect:

```vim
:TaskCreate python   " Force Python comment detection
:GitHubTask rust     " Force Rust comment detection for GitHub
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
- `create_task_from_comment_safe(lang_override, provider)` - Same with language validation
- `close_task_from_comment(lang_override)` - Close any task type
- `add_file_to_task_sources(lang_override)` - Add file to task references

### Provider-Specific Functions

- `create_clickup_task_from_comment(lang_override)` 
- `create_github_task_from_comment(lang_override)`
- `create_todoist_task_from_comment(lang_override)`

### ClickUp-Specific Functions

- `review_task_from_comment(lang_override)` - Set task to review
- `in_progress_task_from_comment(lang_override)` - Set task to in progress  
- `clickup_task_xref()` - Cross-reference tasks with files
- `cleanup_sourcefiles()` - Clean up SourceFiles custom fields

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Adding New Providers

To add support for a new task management system:

1. Add provider configuration to the `config.providers` table
2. Implement provider-specific API functions (`create_*`, `update_*`, `add_files_to_*`)
3. Add URL extraction and task ID parsing functions
4. Update the generic functions to handle the new provider
5. Add provider-specific commands and documentation

## License

MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter issues:

1. Check that your API keys are correctly set in environment variables
2. Verify provider configuration (list_id, repo_owner/repo_name, etc.)  
3. Ensure the comment is in a supported format and language
4. Try the "Force" version of commands to bypass language validation
5. Open an issue with details about your configuration and the error

## Acknowledgments

* olimorris' [CodeCompanion](https://codecompanion.olimorris.dev/)
  This plugin was developed due to a need, and a lack of time to loose focus.  I extensively used AI guided
  development to have Claude and Copilot pretty much write this - including docs - with guidance and direction from me, but little actual coding.
