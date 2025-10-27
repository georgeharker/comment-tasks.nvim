# Todoist Integration
## Setup

### 1. Get API Token

1. Go to Todoist → Settings → Integrations
2. Find "API token" section
3. Copy your personal API token

### 2. Environment Configuration

```bash
export TODOIST_API_TOKEN="your_todoist_api_token_here"
```

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        todoist = {
            enabled = true,
            api_key_env = "TODOIST_API_TOKEN",
            
            -- Optional: Default project ID
            project_id = "project_id",          -- Specific project for code tasks
            
            -- Optional: Default labels for new tasks
            default_labels = ["coding", "bug"], -- Label names or IDs
            
            -- Optional: Default priority (1=normal, 2=high, 3=very high, 4=urgent)
            default_priority = 2,
        }
    }
})
```

### 4. Finding Your Project ID

#### Method 1: From Todoist URL
```
https://todoist.com/app/project/[PROJECT_ID]
                                ↳ This is your project_id
```

#### Method 2: Using API
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \\
     "https://api.todoist.com/rest/v2/projects"
```

## Usage

### Commands

Todoist uses a simple complete/incomplete model:

```vim
:TodoistTask new          " Create new task
:TodoistTask complete     " Mark task as complete  
:TodoistTask addfile      " Add current file reference to task
```

### Natural Language Due Dates

Todoist supports natural language for due dates:

```vim
:TodoistTask new tomorrow          " Due tomorrow
:TodoistTask new "next Monday"     " Due next Monday
:TodoistTask new "Jan 15"          " Due January 15th
```

### Example Workflow

1. **Create a task**:
   ```python
   # TODO: Refactor user authentication module
   # Current implementation has security vulnerabilities
   ```
   
   Place cursor on comment → `:TodoistTask new`
   
   ```python
   # TODO: Refactor user authentication module  
   # Current implementation has security vulnerabilities
   # https://todoist.com/showTask?id=123456789
   ```

2. **Complete when finished**:
   ```vim
   :TodoistTask complete     " Marks task as complete
   ```

3. **Add file references**:
   ```vim
   :TodoistTask addfile      " Adds current file to task description
   ```

## Configuration Options

### Basic Configuration

```lua
todoist = {
    enabled = true,
    api_key_env = "TODOIST_API_TOKEN",
}
```

### Advanced Configuration

```lua
todoist = {
    enabled = true,
    api_key_env = "TODOIST_API_TOKEN",
    
    -- Optional: Default project for code-related tasks
    project_id = "2203306141",          -- Your coding project ID
    
    -- Optional: Default labels for categorization
    default_labels = [
        "coding",           -- For general coding tasks
        "bug",              -- For bug fixes
        "feature",          -- For new features
        "refactor",         -- For refactoring tasks
        "documentation"     -- For documentation tasks
    ],
    
    -- Optional: Default priority (1=normal, 2=high, 3=very high, 4=urgent)
    default_priority = 2,
    
    -- Optional: Default due date (natural language)
    default_due_string = "today",       -- "today", "tomorrow", "next week", etc.
    
    -- Optional: Task template
    task_template = {
        content_prefix = "🔧 ",         -- Prefix for task names
        description_template = "File: {filename}\\nLine: {line_number}\\n\\nDescription:\\n{comment_text}"
    }
}
```

### Project-Based Organization

Organize tasks by different projects:

```lua
todoist = {
    -- Map different file types to different projects
    project_mapping = {
        lua = "neovim_project_id",      -- Neovim/Lua development
        python = "backend_project_id",   -- Backend development  
        javascript = "frontend_project_id", -- Frontend development
        default = "general_coding_project_id" -- Fallback project
    }
}
```

## Troubleshooting

### "Project not found" Error

1. **Verify project ID**:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \\
        "https://api.todoist.com/rest/v2/projects"
   ```

2. **Check project access**: Ensure you own or have access to the project

### "Invalid token" or Authentication Failed

1. **Token validity**: Check if API token is still valid in Todoist settings
2. **Token format**: Ensure no extra spaces or characters
3. **Test token**:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \\
        "https://api.todoist.com/rest/v2/projects"
   ```

### Tasks Not Creating

1. **Rate limits**: Todoist has API rate limits
2. **Project permissions**: Ensure you can add tasks to the project
3. **Token scope**: Verify token has task creation permissions

### Labels Not Working

1. **Label names**: Use exact label names (case-sensitive)
2. **Label IDs**: You can use label IDs instead of names
3. **Check available labels**:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \\
        "https://api.todoist.com/rest/v2/labels"
   ```

## API Reference

Todoist uses the [REST API v2](https://developer.todoist.com/rest/v2/). The plugin makes requests to:

- `POST /rest/v2/tasks` - Create tasks
- `POST /rest/v2/tasks/{id}/close` - Complete tasks
- `GET /rest/v2/tasks/{id}` - Retrieve task details
- `POST /rest/v2/comments` - Add comments (for file references)

## Personal Productivity Tips

### GTD (Getting Things Done) Workflow

```lua
todoist = {
    project_mapping = {
        -- Organize by GTD methodology
        inbox = "inbox_project_id",         -- Quick capture
        coding = "projects_coding_id",      -- Active coding projects
        research = "projects_research_id",  -- Research and learning
        someday = "someday_maybe_id"        -- Future ideas
    },
    
    default_labels = ["code", "context_computer"],
    default_priority = 2
}
```

### Priority-Based Organization

```lua
todoist = {
    -- Map comment types to priorities
    priority_mapping = {
        FIXME = 4,      -- Urgent (red)
        BUG = 4,        -- Urgent (red)  
        TODO = 2,       -- High (orange)
        NOTE = 1,       -- Normal (no color)
        IDEA = 1        -- Normal (no color)
    }
}
```

### Context-Based Labels

```lua
todoist = {
    default_labels = [
        "context_computer",     -- When at computer
        "project_work",         -- Work-related
        "energy_high",          -- Requires high energy/focus
        "time_30min"            -- Estimated time requirement
    ]
}
```

## Integration Patterns

### Code Review Workflow

```lua
todoist = {
    default_labels = ["code_review", "follow_up"],
    task_template = {
        content_prefix = "📝 Review: ",
        description_template = "Code review feedback for {filename}\\n\\nAction needed: {comment_text}"
    }
}
```

### Learning and Documentation

```lua
todoist = {
    project_id = "learning_project_id",
    default_labels = ["learning", "documentation", "research"],
    default_priority = 2
}
```

For more examples, see [../examples/workflows.md](../examples/workflows.md#todoist-workflows).
