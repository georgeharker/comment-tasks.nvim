# Comment Tasks

A universal Neovim plugin that bridges **10+ task management systems** with code comments across multiple programming languages. Create, update, and manage tasks directly from your comments without leaving your editor.

## 🚀 Features

> **Manage tasks from code without losing focus. Maintain task references in code.**

Transform your TODO comments into actionable tasks across 10+ platforms while keeping task URLs embedded in your codebase for perfect traceability.

- **🔗 Universal Multi-Provider Support**: Works with 10+ task management systems
- **🎯 Custom Status System**: Configurable workflows for each provider
- **🌍 Multi-Language Support**: Works with 15+ programming languages using Tree-sitter
- **✨ Smart Comment Detection**: Handles single-line, block comments, and docstrings
- **🔄 Intelligent URL Insertion**: Context-aware URL placement
- **⚡ Unified Command Interface**: Same commands work across all providers
- **📁 File Reference Management**: Structured file associations with tasks
- **🧹 Comment Prefix Trimming**: Automatically clean TODO, FIXME, and other prefixes
- **🎨 Language Override**: Force specific language detection when needed
- **🔧 Modular Architecture**: Extensible system for easy provider addition

## 📊 Supported Providers

| Provider | Type | Custom Status | Bulk Operations | File References |
|----------|------|---------------|-----------------|-----------------|
| **🎯 [ClickUp](docs/providers/clickup.md)** | Full | ✅ | ✅ | ✅ |
| **📋 [Asana](docs/providers/asana.md)** | Full | ✅ | ❌ | ✅ |
| **⚡ [Linear](docs/providers/linear.md)** | Full | ✅ | ❌ | ✅ |
| **🏢 [Jira](docs/providers/jira.md)** | Full | ✅ | ❌ | ✅ |
| **📝 [Notion](docs/providers/notion.md)** | Full | ✅ | ❌ | ✅ |
| **📈 [Monday.com](docs/providers/monday.md)** | Full | ✅ | ❌ | ✅ |
| **🐙 [GitHub Issues](docs/providers/github.md)** | Basic | ❌ | ❌ | ✅ |
| **🦊 [GitLab Issues](docs/providers/gitlab.md)** | Basic | ❌ | ❌ | ✅ |
| **📦 [Trello](docs/providers/trello.md)** | Basic | ❌ | ❌ | ✅ |
| **✅ [Todoist](docs/providers/todoist.md)** | Basic | ❌ | ❌ | ✅ |

**Full**: Complete workflow customization with any status names  
**Basic**: Open/closed or list-based status management

## 🌍 Supported Languages

Works with 15+ programming languages including:
**Python** • **JavaScript/TypeScript** • **Lua** • **Rust** • **C/C++** • **Go** • **Java** • **Ruby** • **PHP** • **CSS** • **HTML** • **Bash** • **Vim Script** • **YAML** • **JSON**

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

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
                clickup = {
                    enabled = true,
                    api_key_env = "CLICKUP_API_KEY",
                    list_id = "your_clickup_list_id",
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
    end
}
```

**Environment Setup**:
```bash
export CLICKUP_API_KEY="your_api_key_here"
```

📖 **Detailed Installation**: [docs/installation.md](docs/installation.md)

## 🚀 Quick Start

1. **Install** the plugin with your preferred package manager
2. **Configure** your task management provider(s)
3. **Set environment variables** for API authentication
4. **Create tasks** from comments using commands

### Example Workflow

```python
# TODO: Implement user authentication system
# This needs proper validation and error handling
```

Place cursor on the comment and run `:ClickUpTask new` → 

```python
# TODO: Implement user authentication system  
# This needs proper validation and error handling
# https://app.clickup.com/t/task_id
```

Update task status as you progress:
```vim
:ClickUpTask in_progress  " When you start working  
:ClickUpTask review       " When ready for code review
:ClickUpTask close        " When finished (uses completed status)
```

## ⚡ Core Commands

### Provider-Specific Commands (Recommended)

```vim
" ClickUp (Full custom status support)
:ClickUpTask              " Create task (default)
:ClickUpTask create       " Create task (explicit)
:ClickUpTask in_progress  " Update to 'In Progress' status
:ClickUpTask close        " Complete task (uses completed status)
:ClickUpTask addfile      " Add current file to task

" GitHub Issues (Basic support)
:GitHubTask               " Create issue (default)
:GitHubTask create        " Create issue (explicit)
:GitHubTask close         " Close issue
:GitHubTask addfile       " Add file reference

" Asana (Full custom status support)  
:AsanaTask                " Create task (default)
:AsanaTask create         " Create task (explicit)
:AsanaTask blocked        " Update to 'Blocked' status
:AsanaTask close          " Complete task
:ClickUpTask review       " Update to 'Code Review' status
:ClickUpTask completed    " Complete task
:ClickUpTask addfile      " Add current file to task

" GitHub Issues (Basic support)
:GitHubTask new          " Create issue
:GitHubTask close        " Close issue  
:GitHubTask addfile      " Add file reference

" Asana (Full custom status support)  
:AsanaTask new           " Create task
:AsanaTask blocked       " Update to 'Blocked' status
:AsanaTask completed     " Complete task
```

### Generic Commands (Uses default_provider)

```vim
:CommentTask new         " Create task with default provider
:CommentTask completed   " Complete task with default provider
:CommentTask             " Create task with default provider (default)
:CommentTask create      " Create task with default provider (explicit)
:CommentTask close       " Complete task with default provider
:CommentTaskAddFile      " Add file reference with default provider
```

**Available commands are generated dynamically** from your status configuration.

## ⚙️ Configuration

### Basic Setup

```lua
require("comment-tasks").setup({
    default_provider = "clickup",  -- Provider for generic commands
    
    providers = {
        clickup = {
            enabled = true,
            api_key_env = "CLICKUP_API_KEY",
            list_id = "123456789",
            statuses = {
                new = "To Do",           -- Special: creates tasks
                completed = "Complete",  -- Special: completes tasks
                review = "Code Review",  -- Custom: creates :ClickUpTask review  
                blocked = "Blocked",     -- Custom: creates :ClickUpTask blocked
            }
        }
    }
})
```

### Status System

Commands are **automatically generated** from your status configuration:

```lua
statuses = {
    new = "Backlog",        -- → :ClickUpTask new (creates with "Backlog")
    completed = "Done",     -- → :ClickUpTask completed (updates to "Done")  
    review = "In Review",   -- → :ClickUpTask review (updates to "In Review")
    testing = "QA Testing", -- → :ClickUpTask testing (updates to "QA Testing")
}
```

📖 **Complete Configuration**: [docs/configuration.md](docs/configuration.md)

## 📚 Documentation

### Setup Guides
- 📦 **[Installation Guide](docs/installation.md)** - Complete installation instructions
- ⚙️ **[Configuration Reference](docs/configuration.md)** - All configuration options

### Provider Guides
- 🎯 **[ClickUp Setup](docs/providers/clickup.md)** 
- 📋 **[Asana Setup](docs/providers/asana.md)**
- 🐙 **[GitHub Issues Setup](docs/providers/github.md)**
- ⚡ **[Linear Setup](docs/providers/linear.md)**
- 🏢 **[Jira Setup](docs/providers/jira.md)**
- 📝 **[Notion Setup](docs/providers/notion.md)**
- 📈 **[Monday.com Setup](docs/providers/monday.md)**
- 📦 **[Trello Setup](docs/providers/trello.md)**
- 🦊 **[GitLab Issues Setup](docs/providers/gitlab.md)**
- ✅ **[Todoist Setup](docs/providers/todoist.md)**

### Examples

### Reference
- 🔧 **[API Reference](docs/api-reference.md)** - Lua API & keybinding examples

## 🔧 Keybinding Examples

```lua
vim.keymap.set("n", "<leader>tcc", function()
    require("comment-tasks").create_clickup_task_from_comment()
end, { desc = "Create ClickUp task" })

vim.keymap.set("n", "<leader>tgh", function() 
    require("comment-tasks").create_github_task_from_comment()
end, { desc = "Create GitHub issue" })

vim.keymap.set("n", "<leader>tc", function()
    require("comment-tasks").create_task_from_comment()
end, { desc = "Create task (default provider)" })

vim.keymap.set("n", "<leader>tu", function()
    require("comment-tasks").update_task_status_from_comment("completed")
end, { desc = "Complete task" })

vim.keymap.set("n", "<leader>tx", function()
    require("comment-tasks").close_task_from_comment()
end, { desc = "Close task" })
```

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for:

- 🆕 Adding new providers
- 🐛 Bug reports and fixes
- 📖 Documentation improvements
- 💡 Feature suggestions

### Development Setup

```bash
git clone https://github.com/georgeharker/comment-tasks.nvim.git
cd comment-tasks.nvim
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Support

- 📖 **Documentation**: Check [docs/](docs/) for detailed guides
- 🐛 **Issues**: Report bugs on [GitHub Issues](https://github.com/georgeharker/comment-tasks.nvim/issues)
- 💬 **Discussions**: Ask questions in [GitHub Discussions](https://github.com/georgeharker/comment-tasks.nvim/discussions)

---

**Ready to get started?** Check out the [Installation Guide](docs/installation.md) and choose your [provider setup](docs/providers/).
