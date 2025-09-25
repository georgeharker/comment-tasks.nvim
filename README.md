# ClickUp Comment Tasks

A Neovim plugin that integrates ClickUp task management with code comments across multiple programming languages. Create, update, and manage ClickUp tasks directly from your comments without leaving your editor.

## Features

- **Multi-Language Support**: Works with 15+ programming languages using Tree-sitter
- **Create Tasks from Comments**: Convert code comments into ClickUp tasks
- **Smart Comment Detection**: Handles single-line, block comments, and docstrings
- **Task Status Management**: Mark tasks as complete, in progress, or under review
- **Cross-Reference Tasks**: Automatically find and link source files to existing tasks
- **Custom Field Support**: Update SourceFiles custom field with relevant file references
- **Comment Prefix Trimming**: Automatically clean TODO, FIXME, and other prefixes from task names
- **Language Override**: Force specific language detection when needed
- **Automatic Fallback**: Uses regex patterns when Tree-sitter unavailable
- **Bulk Operations**: Clean up and deduplicate SourceFiles across all tasks

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
  "your-username/clickup-comment-tasks",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for HTTP requests
  },
  config = function()
    require("clickup-comment-tasks").setup({
      list_id = "your_clickup_list_id",
      team_id = "your_clickup_team_id", -- Optional
      api_key_env = "CLICKUP_API_KEY", -- Environment variable name
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/clickup-comment-tasks",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    require("clickup-comment-tasks").setup({
      list_id = "your_clickup_list_id",
      team_id = "your_clickup_team_id",
    })
  end
}
```

## Setup

### 1. Get Your ClickUp API Key

1. Go to ClickUp Settings → Apps
2. Generate a Personal API Token
3. Set it as an environment variable:

```bash
export CLICKUP_API_KEY="your_api_key_here"
```

### 2. Find Your List ID

1. Open your ClickUp list in a web browser
2. The URL will look like: `https://app.clickup.com/12345/v/li/67890`
3. The List ID is the number after `/li/` (e.g., `67890`)

### 3. Configure the Plugin

```lua
require("clickup-comment-tasks").setup({
  list_id = "your_list_id",
  team_id = "your_team_id", -- Optional
  api_key_env = "CLICKUP_API_KEY", -- Default environment variable name
  
  -- Multi-language support configuration
  languages = {
    -- Enable/disable specific languages
    python = { enabled = true },
    javascript = { enabled = true },
    typescript = { enabled = true },
    rust = { enabled = true },
    lua = { enabled = true },
    -- Add more languages as needed
  },
  
  -- Tree-sitter and fallback behavior
  fallback_to_regex = true, -- Use regex patterns if Tree-sitter unavailable
  
  comment_prefixes = { -- Optional: customize comment prefixes to trim
    "TODO",
    "FIXME",
    "BUG",
    "HACK",
    "NOTE",
    -- Add your custom prefixes here
  },
  
  keymap = "<leader>ct", -- Optional: set a keymap for creating tasks
})
```

## Usage

### Creating Tasks from Comments

Place your cursor on a comment in any supported language and use the command to create a ClickUp task:

```python
# TODO: Implement user authentication system
# This needs to handle OAuth2 and JWT tokens

# FIXME: Database connection timeout issues
# The connection pool is not properly configured
```

```javascript
// TODO: Refactor this function  
// It's getting too complex

/* TODO: Add error handling
   This function needs better validation */
```

```rust
/// TODO: Add proper error handling
/// This function needs better error types
fn my_function() -> Result<(), Error> {
    // Implementation here
}
```

**Commands:**
- `:ClickUpTask` - Create task (auto-detects language)
- `:ClickUpTask rust` - Create task (force Rust detection)
- `:ClickUpTaskForce` - Create task (skip language validation)

The plugin will:
1. Extract the comment content
2. Remove prefixes like "TODO:", "FIXME:", etc.
3. Create a ClickUp task with the cleaned content
4. Add the task URL to your comment

**Result:**
```python
# TODO: Implement user authentication system
# This needs to handle OAuth2 and JWT tokens
# https://app.clickup.com/t/abc123

# FIXME: Database connection timeout issues
# The connection pool is not properly configured
# https://app.clickup.com/t/def456
```

```javascript
/* TODO: Add error handling
   This function needs better validation
 * https://app.clickup.com/t/ghi789 */
```

### Managing Task Status

Update task status directly from comments containing ClickUp URLs:

**Commands:**
- `:ClickUpClose` - Mark task as complete (auto-detect language)
- `:ClickUpClose python` - Mark task as complete (force Python)
- `:ClickUpReview` - Set task to review status
- `:ClickUpInProgress` - Set task to in progress

### Adding Files to Tasks

Link the current file to a task's SourceFiles custom field:

**Commands:**
- `:ClickUpAddFile` - Add current file to task's SourceFiles (auto-detect)
- `:ClickUpAddFile lua` - Add current file (force Lua detection)
- `:ClickUpAddFileForce` - Add file (skip language validation)

### Cross-Reference Operations

Find and link source files to existing tasks automatically:

**Commands:**
- `:ClickupTaskXref` - Scan all tasks and link relevant source files
- `:ClickUpClearResults` - Clear the cross-reference results window
- `:ClickUpCleanupSourceFiles` - Clean up duplicate/invalid entries in SourceFiles

The cross-reference feature will:
1. Search for task URLs in your codebase using ripgrep (with fallback)
2. Extract file references from task descriptions
3. Update the SourceFiles custom field
4. Clean up task descriptions by moving file references to the custom field

## Supported Comment Formats

### Single-line Comments
```python
# TODO: Fix this bug
# FIXME: Refactor this function
# BUG: Handle edge case
```

```javascript
// TODO: Add error handling
// FIXME: Optimize performance
```

```rust
// TODO: Implement feature
/// TODO: Add documentation
//! TODO: Add module docs
```

### Multi-line Comments (Docstrings)
```python
"""
TODO: Add comprehensive error handling
This function needs better validation
"""

'''
FIXME: Optimize performance
Current implementation is O(n²)
'''
```

### Block Comments
```javascript
/* TODO: Refactor this module
   It's getting too complex
   Need to split into smaller functions */
```

```css
/* TODO: Optimize these styles
 * Remove unused properties
 * Add mobile responsiveness */
```

```html
<!-- TODO: Add proper accessibility
  Make this more semantic
  Add ARIA labels -->
```

## Comment Extension Behavior

The plugin adapts URL insertion to each language's comment style:

### Single-line Comments
For languages with single-line comments, the task URL is added as a new comment line:

**Before:**
```python
# TODO: Fix this bug
# This is broken
```

**After:**
```python
# TODO: Fix this bug
# This is broken
# https://app.clickup.com/t/task_id
```

### Block Comments
For languages with block comments, the task URL is added within the comment block:

**Before:**
```javascript
/* TODO: Fix this bug
   This needs attention */
```

**After:**
```javascript
/* TODO: Fix this bug
   This needs attention 
 * https://app.clickup.com/t/task_id */
```

## Custom Fields

The plugin supports ClickUp custom fields, particularly the "SourceFiles" field:

- **SourceFiles**: Automatically populated with relevant file paths
- Files are deduplicated and normalized
- Filters out common build/cache directories (.venv, __pycache__, node_modules, etc.)

## Configuration Options

```lua
require("clickup-comment-tasks").setup({
  -- Required
  list_id = "your_clickup_list_id",
  
  -- Optional
  team_id = "your_clickup_team_id",
  api_key_env = "CLICKUP_API_KEY", -- Environment variable for API key
  
  -- Multi-language support
  languages = {
    -- Enable/disable languages
    python = { enabled = true },
    javascript = { enabled = true },
    typescript = { enabled = true },
    rust = { enabled = true },
    lua = { enabled = true },
    go = { enabled = true },
    java = { enabled = true },
    
    -- Language-specific customization
    rust = {
      enabled = true,
      custom_prefixes = { "SAFETY", "PERF", "TODO" }
    },
    
    -- Add custom languages
    kotlin = {
      comment_nodes = { "comment", "line_comment", "block_comment" },
      comment_styles = {
        single_line = { prefix = "// ", continue_with = "// " },
        block = {
          start_markers = { "/*" },
          end_markers = { "*/" },
          continue_with = " * "
        }
      }
    }
  },
  
  -- Tree-sitter and fallback behavior
  fallback_to_regex = true, -- Use regex patterns if Tree-sitter unavailable
  
  -- Customize comment prefixes to trim from task names
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
  
  -- Optional keymap for creating tasks
  keymap = "<leader>ct",
})
```

## Commands Reference

| Command | Description | Language Support |
|---------|-------------|-------------------|
| `:ClickUpTask [lang]` | Create task from comment | Auto-detect or specify |
| `:ClickUpTaskForce [lang]` | Create task (skip validation) | Auto-detect or specify |
| `:ClickUpClose [lang]` | Mark task as complete | Auto-detect or specify |
| `:ClickUpCloseForce [lang]` | Mark task as complete (skip validation) | Auto-detect or specify |
| `:ClickUpReview [lang]` | Set task to review | Auto-detect or specify |
| `:ClickUpReviewForce [lang]` | Set task to review (skip validation) | Auto-detect or specify |
| `:ClickUpInProgress [lang]` | Set task to in progress | Auto-detect or specify |
| `:ClickUpInProgressForce [lang]` | Set task to in progress (skip validation) | Auto-detect or specify |
| `:ClickUpAddFile [lang]` | Add file to SourceFiles | Auto-detect or specify |
| `:ClickUpAddFileForce [lang]` | Add file to SourceFiles (skip validation) | Auto-detect or specify |
| `:ClickupTaskXref` | Cross-reference tasks with files | All files |
| `:ClickUpClearResults` | Clear XRef results window | N/A |
| `:ClickUpCleanupSourceFiles` | Clean up SourceFiles field | All tasks |

### Command Examples
```vim
" Auto-detect language from buffer filetype
:ClickUpTask
:ClickUpClose
:ClickUpReview

" Force specific language
:ClickUpTask rust
:ClickUpClose javascript
:ClickUpAddFile python

" Tab completion works for language names
:ClickUpTask <Tab>
```

## Requirements

- Neovim 0.7+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Tree-sitter parsers for languages you want to use (optional but recommended)
- ClickUp API access
- Supported language files (or use "Force" variants for any filetype)
- Optional: [ripgrep](https://github.com/BurntSushi/ripgrep) for faster file searching

### Installing Tree-sitter Parsers

For the best experience, install Tree-sitter parsers for your languages:

```vim
:TSInstall python
:TSInstall javascript
:TSInstall typescript
:TSInstall rust
:TSInstall lua
:TSInstall go
:TSInstall java
:TSInstall c
:TSInstall cpp
" ... and so on
```

The plugin will automatically fall back to regex patterns if Tree-sitter parsers are not available.

## Troubleshooting

### API Key Issues
- Ensure your API key is set in the environment variable
- Check that the environment variable name matches your configuration
- Verify the API key has necessary permissions in ClickUp

### List ID Problems
- Double-check your List ID from the ClickUp URL
- Ensure you have access to the specified list

### Comment Detection
- Ensure your cursor is on a line containing a comment in a supported language
- For block comments, place cursor anywhere within the comment block
- For docstrings, place cursor on any line within the docstring
- Use "Force" commands to bypass language validation

### Tree-sitter Issues

If you see "Language 'xyz' is not supported":

1. **Install the Tree-sitter parser:**
   ```vim
   :TSInstall xyz
   ```

2. **Check parser availability:**
   ```vim
   :TSInstallInfo
   ```

3. **Enable regex fallback** (if Tree-sitter fails):
   ```lua
   require('clickup-comment-tasks').setup({
       fallback_to_regex = true,
   })
   ```

### Language Detection Issues
- The plugin auto-detects language from `vim.bo.filetype`
- Use language override if auto-detection fails: `:ClickUpTask javascript`
- Check your filetype with `:set filetype?`
- Use "Force" commands to bypass all validation

### Multi-Language Configuration
- Languages are enabled by default when their parsers are available
- Disable specific languages in setup if needed:
  ```lua
  require('clickup-comment-tasks').setup({
      languages = {
          javascript = { enabled = false }
      }
  })
  ```

### Cross-Reference Issues
- Install ripgrep for better performance: `brew install ripgrep` (macOS) or `apt install ripgrep` (Ubuntu)
- The plugin will fall back to native search if ripgrep is not available
- Check that your working directory contains the files you want to search

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details