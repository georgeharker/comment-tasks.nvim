# Installation Guide

## Package Manager Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
    "georgeharker/comment-tasks.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim", -- Required for HTTP requests
    },
    config = function()
        require("comment-tasks").setup({
            default_provider = "clickup", -- Choose your preferred provider
            
            providers = {
                -- Configure only the providers you use
                clickup = {
                    enabled = true,
                    api_key_env = "CLICKUP_API_KEY",
                    list_id = "your_clickup_list_id",
                    team_id = "your_clickup_team_id", -- Optional
                    statuses = {
                        new = "To Do",
                        in_progress = "In Progress", 
                        review = "Code Review",
                        completed = "Complete",
                    }
                },
                
                -- Add other providers as needed
            },
        })
        
        -- Set up keybindings (optional) - see docs/api-reference.md
    end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "georgeharker/comment-tasks.nvim",
    requires = {
        "nvim-lua/plenary.nvim", -- Required for HTTP requests
    },
    config = function()
        require("comment-tasks").setup({
            -- Your configuration here
        })
    end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'georgeharker/comment-tasks.nvim'
```

Then in your `init.vim` or `init.lua`:

```lua
require("comment-tasks").setup({
    -- Your configuration here
})
```

## Dependencies

### Required
- **[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)** - Essential for HTTP requests and async operations

### Optional
- **Tree-sitter parsers** - For enhanced comment detection (automatically installed by most Neovim distributions)

## Environment Variables

Set up API keys for the task management systems you want to use:

```bash
# ClickUp
export CLICKUP_API_KEY="your_api_key_here"

# GitHub  
export GITHUB_TOKEN="your_personal_access_token"

# Asana
export ASANA_TOKEN="your_personal_access_token"

# Linear
export LINEAR_API_KEY="your_api_key_here"

# Jira
export JIRA_URL="https://your-domain.atlassian.net"
export JIRA_USERNAME="your_email@domain.com"
export JIRA_API_TOKEN="your_api_token"

# Notion
export NOTION_TOKEN="your_integration_token"

# Monday.com
export MONDAY_API_TOKEN="your_api_token"

# Trello
export TRELLO_API_KEY="your_api_key"
export TRELLO_TOKEN="your_token"

# GitLab
export GITLAB_TOKEN="your_personal_access_token"
export GITLAB_URL="https://gitlab.com" # or your GitLab instance URL

# Todoist
export TODOIST_API_TOKEN="your_api_token"
```

## Verification

After installation, verify everything works:

1. **Check plugin is loaded**:
   ```vim
   :lua print(require("comment-tasks"))
   ```

2. **Test a provider** (example with ClickUp):
   ```vim
   :ClickUpTask new
   ```

3. **Check environment variables**:
   ```vim
   :lua print(vim.env.CLICKUP_API_KEY)
   ```

## Next Steps

- **Configuration**: See [configuration.md](configuration.md) for detailed setup options
- **Provider Setup**: Visit [providers/](providers/) for specific provider configuration
- **Keybindings**: Check [api-reference.md](api-reference.md) for keybinding examples
- **Quick Start**: Return to main [README.md](../README.md#quick-start) for usage examples