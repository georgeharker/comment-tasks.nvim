# Lua API Reference

Complete reference for the comment-tasks.nvim Lua API.

## Core Functions

### setup(user_config)

Initialize the plugin with your configuration.

**Parameters:**
- `user_config` (table): Configuration options (see [Configuration Guide](configuration.md))

**Example:**
```lua
require("comment-tasks").setup({
    default_provider = "clickup",
    clickup = {
        api_token = vim.env.CLICKUP_API_TOKEN,
        team_id = "your_team_id",
    }
})
```

### create_task_from_comment(lang_override, provider_name)

Create a task from the comment on the current line.

**Parameters:**
- `lang_override` (string, optional): Language override (e.g., "lua", "python")  
- `provider_name` (string, optional): Provider to use. Defaults to `default_provider` from config

**Returns:** Nothing (shows UI dialog for task creation)

**Examples:**
```lua
-- Use default provider and language detection
require("comment-tasks").create_task_from_comment()

-- Use specific provider
require("comment-tasks").create_task_from_comment(nil, "clickup")
require("comment-tasks").create_task_from_comment(nil, "github")

-- Override language detection
require("comment-tasks").create_task_from_comment("lua")

-- Both language and provider override
require("comment-tasks").create_task_from_comment("python", "linear")
```

### update_task_status_from_comment(status, lang_override, provider_name)

Update the status of a task referenced in the current line's comment.

**Parameters:**
- `status` (string, required): Status to set (provider-specific values)
- `lang_override` (string, optional): Language override  
- `provider_name` (string, optional): Provider to use. Auto-detected from task URL if not specified

**Examples:**
```lua
-- Update using auto-detected provider (recommended)
require("comment-tasks").update_task_status_from_comment("completed")
require("comment-tasks").update_task_status_from_comment("in_progress") 

-- Force specific provider (rarely needed)
require("comment-tasks").update_task_status_from_comment("Done", nil, "clickup")
require("comment-tasks").update_task_status_from_comment("closed", nil, "github")

-- With language override
require("comment-tasks").update_task_status_from_comment("completed", "lua")
```

### add_file_to_task_sources(lang_override, provider_name)

Add the current file as a source/attachment to the task referenced in the current line's comment.

**Parameters:**

**Examples:**
```lua
require("comment-tasks").add_file_to_task_sources()

require("comment-tasks").add_file_to_task_sources("lua")

require("comment-tasks").add_file_to_task_sources(nil, "github")
```

### close_task_from_comment(lang_override, provider_name)

Close/complete a task referenced in the current line's comment. This is a convenient wrapper around `update_task_status_from_comment("completed", ...)`.

**Parameters:**
- `lang_override` (string, optional): Language override  
- `provider_name` (string, optional): Provider to use. Auto-detected from task URL if not specified

**Examples:**
```lua
-- Close task using auto-detected provider (recommended)
require("comment-tasks").close_task_from_comment()

-- With language override
require("comment-tasks").close_task_from_comment("lua")

-- Force specific provider (rarely needed)
require("comment-tasks").close_task_from_comment(nil, "clickup")
```

## Provider-Specific Usage

While the API functions are generic, you can target specific providers:

### ClickUp Tasks
```lua
-- Create ClickUp task
require("comment-tasks").create_task_from_comment(nil, "clickup")

-- Update with ClickUp status
require("comment-tasks").update_task_status_from_comment("in_progress", nil, "clickup")
require("comment-tasks").update_task_status_from_comment("complete", nil, "clickup")
```

### GitHub Issues  
```lua
-- Create GitHub issue
require("comment-tasks").create_task_from_comment(nil, "github")

-- Update GitHub issue
require("comment-tasks").update_task_status_from_comment("closed", nil, "github")
require("comment-tasks").update_task_status_from_comment("open", nil, "github")
```

### Other Providers
```lua
-- Asana
require("comment-tasks").create_task_from_comment(nil, "asana")
require("comment-tasks").update_task_status_from_comment("completed", nil, "asana")

-- Linear
require("comment-tasks").create_task_from_comment(nil, "linear")
require("comment-tasks").update_task_status_from_comment("Done", nil, "linear")

-- Todoist
require("comment-tasks").create_task_from_comment(nil, "todoist")
require("comment-tasks").update_task_status_from_comment("completed", nil, "todoist")
```

## Common Usage Patterns

### Default Provider Pattern (Recommended)
Set a `default_provider` in your config and use the simple API:

```lua
-- In your config
require("comment-tasks").setup({
    default_provider = "clickup"  -- or github, asana, etc.
})

-- In keybindings - uses default provider
vim.keymap.set("n", "<leader>tc", function()
    require("comment-tasks").create_task_from_comment()
end)

vim.keymap.set("n", "<leader>tu", function()
    require("comment-tasks").update_task_status_from_comment("completed")
end)

vim.keymap.set("n", "<leader>tx", function()
    require("comment-tasks").close_task_from_comment()
end)
```

### Multi-Provider Pattern
For different providers in different contexts:

```lua
-- Work project keybindings
vim.keymap.set("n", "<leader>tw", function()
    require("comment-tasks").create_task_from_comment(nil, "clickup")
end, { desc = "Work task" })

-- Open source project keybindings  
vim.keymap.set("n", "<leader>ti", function()
    require("comment-tasks").create_task_from_comment(nil, "github")
end, { desc = "Issue" })

-- Personal tasks
vim.keymap.set("n", "<leader>tp", function()
    require("comment-tasks").create_task_from_comment(nil, "todoist")  
end, { desc = "Personal task" })
```

### Auto-Detection Pattern
Let the plugin auto-detect provider from existing task URLs:

```lua
vim.keymap.set("n", "<leader>tc", function()
    require("comment-tasks").update_task_status_from_comment("completed")
end, { desc = "Complete task" })

vim.keymap.set("n", "<leader>tx", function()
    require("comment-tasks").close_task_from_comment()
end, { desc = "Close task" })

vim.keymap.set("n", "<leader>tf", function()
    require("comment-tasks").add_file_to_task_sources()
end, { desc = "Add file to task" })
```

## Provider Status Values

Each provider has different status values. See individual provider documentation for details:

### ClickUp
- Configurable in setup (see [ClickUp provider docs](providers/clickup.md))
- Common: `"new"`, `"in_progress"`, `"review"`, `"completed"`, `"blocked"`

### GitHub  
- `"open"`, `"closed"`

### Asana
- `"completed"`, `"incomplete"`

### Linear
- `"Backlog"`, `"Todo"`, `"In Progress"`, `"Done"`, `"Canceled"`

See [Provider Documentation](../README.md#providers) for complete provider-specific status lists.

## Error Handling

The API functions handle errors gracefully:
- Show notification messages for success/failure
- Return early on invalid input  
- Auto-detect providers from URLs when possible
- Fall back to configured defaults

No need for error checking in your keybinding code - the plugin handles it internally.

## Language Detection

The plugin auto-detects comment syntax for 20+ languages. You can override with `lang_override`:

```lua
-- Force Lua comment detection in any file
require("comment-tasks").create_task_from_comment("lua")

-- Force Python comment detection  
require("comment-tasks").create_task_from_comment("python", "github")
```

See [Configuration Guide](configuration.md#supported-languages) for the full language list.

## Integration Examples

### With which-key.nvim
```lua
local wk = require("which-key")

wk.register({
    t = {
        name = "Tasks",
        c = { function() require("comment-tasks").create_task_from_comment() end, "Create" },
        u = { function() require("comment-tasks").update_task_status_from_comment("completed") end, "Complete" },
        x = { function() require("comment-tasks").close_task_from_comment() end, "Close" },
        f = { function() require("comment-tasks").add_file_to_task_sources() end, "Add File" },
    }
}, { prefix = "<leader>" })
```

### With lazy.nvim
```lua
{
    "georgeharker/comment-tasks.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>tc", function() require("comment-tasks").create_task_from_comment() end, desc = "Create task" },
        { "<leader>tu", function() require("comment-tasks").update_task_status_from_comment("completed") end, desc = "Complete task" },
        { "<leader>tx", function() require("comment-tasks").close_task_from_comment() end, desc = "Close task" },
    },
    config = function()
        require("comment-tasks").setup({
            -- Your config here
        })
    end
}
```

### packer.nvim
```lua
use {
    "georgeharker/comment-tasks.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
        require("comment-tasks").setup({
            default_provider = "github",
        })
        
        -- Keybindings
        local map = vim.keymap.set
        map("n", "<leader>tc", function() require("comment-tasks").create_task_from_comment() end)
        map("n", "<leader>tu", function() require("comment-tasks").update_task_status_from_comment("completed") end)
        map("n", "<leader>tx", function() require("comment-tasks").close_task_from_comment() end)
    end
}
```

### Contextual Bindings
```lua
-- Different providers based on file type
local function create_contextual_task()
    local filetype = vim.bo.filetype
    
    if filetype == "lua" and vim.fn.expand("%"):match("%.nvim") then
        require("comment-tasks").create_task_from_comment(nil, "github")
    elseif filetype:match("python|javascript|typescript") then  
        require("comment-tasks").create_task_from_comment(nil, "clickup")
    else
        require("comment-tasks").create_task_from_comment(nil, "todoist")
    end
end

vim.keymap.set("n", "<leader>tc", create_contextual_task)
```

## Advanced Keybinding Patterns

### Contextual Task Creation
Route to different providers based on file type and project context:

```lua
local function create_smart_task()
    local filetype = vim.bo.filetype
    local filename = vim.fn.expand("%:t")
    
    -- Route based on context
    if filetype == "lua" and filename:match("%.nvim") then
        -- Neovim plugin → GitHub issue
        require("comment-tasks").create_task_from_comment(nil, "github")
    elseif filetype:match("python|javascript|typescript") then
        -- Code files → Work tracker  
        require("comment-tasks").create_task_from_comment(nil, "clickup")
    else
        -- Everything else → Personal tasks
        require("comment-tasks").create_task_from_comment(nil, "todoist")
    end
end

vim.keymap.set("n", "<leader>tc", create_smart_task, { desc = "Smart task creation" })
```

### Project-Specific Bindings
Set up different providers for different project directories:

```lua
local function setup_project_keybindings()
    local project_root = vim.fn.getcwd()
    
    if project_root:match("work%-project") then
        -- Work project uses ClickUp
        vim.keymap.set("n", "<leader>tc", function()
            require("comment-tasks").create_task_from_comment(nil, "clickup")
        end, { desc = "Work task" })
        
    elseif project_root:match("open%-source") then
        -- Open source uses GitHub
        vim.keymap.set("n", "<leader>tc", function()
            require("comment-tasks").create_task_from_comment(nil, "github")
        end, { desc = "GitHub issue" })
        
    else
        -- Default to personal tracker
        vim.keymap.set("n", "<leader>tc", function()
            require("comment-tasks").create_task_from_comment(nil, "todoist")
        end, { desc = "Personal task" })
    end
end

-- Call on startup or when switching projects
setup_project_keybindings()
```

## Debugging

Check configuration and provider status:

```lua
-- Print current configuration
print(vim.inspect(require("comment-tasks.core.config").get_config()))

-- Test provider connection (replace 'clickup' with your provider)
require("comment-tasks").create_task_from_comment(nil, "clickup")
```

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.
