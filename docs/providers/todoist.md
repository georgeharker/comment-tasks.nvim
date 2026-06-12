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
}
```

### Project-Based Organization

To send tasks to a different Todoist project per repository, use a
`.comment-tasks.json` file at the project root — `project_id` is overridable
there (see the
[Configuration Reference](../configuration.md#project-level-configuration-comment-tasksjson)).

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

## API Reference

Todoist uses the [REST API v2](https://developer.todoist.com/rest/v2/). The plugin makes requests to:

- `POST /rest/v2/tasks` - Create tasks
- `POST /rest/v2/tasks/{id}/close` - Complete tasks
- `GET /rest/v2/tasks/{id}` - Retrieve task details
- `POST /rest/v2/comments` - Add comments (for file references)

## Personal Productivity Tips

Dedicate a Todoist project to code tasks (set `project_id`), and use
per-repository `.comment-tasks.json` overrides to route tasks from different
codebases into different projects.
