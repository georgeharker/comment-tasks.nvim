# Asana Integration
## Setup

### 1. Get Personal Access Token

1. Go to [Asana Developer Console](https://app.asana.com/0/developer-console)
2. Click "Personal Access Tokens"
3. Click "Create New Personal Access Token"  
4. Give it a descriptive name
5. Copy the token

### 2. Environment Configuration

```bash
export ASANA_ACCESS_TOKEN="your_personal_access_token_here"
```

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        asana = {
            enabled = true,
            api_key_env = "ASANA_ACCESS_TOKEN",
            project_gid = "1204558436732296",    -- Required: Asana project GID
            assignee_gid = "1204558436732297",   -- Optional: default assignee GID
            
            -- Custom status configuration (match your Asana project)
            statuses = {
                new = "Not Started",        -- Special: used for task creation
                completed = "Complete",     -- Special: used for task completion  
                review = "Review",          -- Custom status
                in_progress = "In Progress", -- Custom status
                blocked = "Blocked",        -- Custom status
                waiting = "Waiting on Others", -- Custom status
            }
        }
    }
})
```

### 4. Finding Your GIDs

#### Project GID (Required)

**Method 1: From Asana URL**
```
https://app.asana.com/0/[PROJECT_GID]/list
                       ↳ This is your project_gid
```

**Method 2: Using API**
```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \\
     "https://app.asana.com/api/1.0/projects"
```

#### User GID (Optional)
```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \\
     "https://app.asana.com/api/1.0/users/me"
```

## Usage

### Commands

All commands work with your configured statuses:

```vim
:AsanaTask new           " Create task with 'Not Started' status
:AsanaTask completed     " Update task to 'Complete' status
:AsanaTask review        " Update task to 'Review' status  
:AsanaTask in_progress   " Update task to 'In Progress' status
:AsanaTask blocked       " Update task to 'Blocked' status
:AsanaTask waiting       " Update task to 'Waiting on Others' status
:AsanaTask addfile       " Add current file reference to task notes
```

### Example Workflow

1. **Create a task**:
   ```java
   // TODO: Implement caching layer for database queries
   // Need to add Redis integration for better performance
   ```
   
   Place cursor on comment → `:AsanaTask new`
   
   ```java
   // TODO: Implement caching layer for database queries
   // Need to add Redis integration for better performance  
   // https://app.asana.com/0/1204558436732296/1204558436732298
   ```

2. **Update status as you progress**:
   ```vim
   :AsanaTask in_progress  " When you start working
   :AsanaTask review       " When ready for review
   :AsanaTask completed    " When finished
   ```

3. **Add file references**:
   ```vim
   :AsanaTask addfile      " Adds current file to task notes
   ```

## Configuration Options

### Status Mapping

Configure statuses to match your Asana project workflow:

```lua
statuses = {
    -- Required statuses
    new = "New Tasks",         -- Status for new tasks
    completed = "Completed",   -- Status for completed tasks
    
    -- Optional custom statuses (must exist in your Asana project)
    planning = "Planning",
    development = "Development",
    testing = "Testing", 
    deployment = "Ready for Deploy",
    blocked = "Blocked",
    waiting = "Waiting on Others",
    review = "Code Review",
}
```

### Advanced Configuration

```lua
asana = {
    enabled = true,
    api_key_env = "ASANA_ACCESS_TOKEN", 
    project_gid = "1204558436732296",
    assignee_gid = "1204558436732297",  -- Default assignee for new tasks
    
    statuses = {
        new = "Not Started",
        completed = "Complete",
        -- Add your custom statuses here
    },
}
```

## Troubleshooting

### "Project not found" or "Invalid project_gid"

1. **Verify project_gid**:
   ```bash
   curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \\
        "https://app.asana.com/api/1.0/projects"
   ```

2. **Check permissions**: Ensure you have access to the project
3. **Project status**: Verify the project is not archived or deleted

### "Status not found" Error

1. **Check available statuses**:
   ```bash
   curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \\
        "https://app.asana.com/api/1.0/projects/PROJECT_GID"
   ```

2. **Case sensitivity**: Status names must match exactly (case-sensitive)
3. **Custom fields**: Ensure status field exists if using custom workflows

### "Forbidden" or "Authentication Failed"

1. **Token validity**: Check if Personal Access Token is still valid
2. **Permissions**: Verify token has access to the specific project  
3. **Workspace access**: Ensure you're a member of the workspace

### Tasks Not Updating

1. **Task permissions**: Verify you can edit tasks in the project
2. **Workflow restrictions**: Check if project has workflow restrictions
3. **Status transitions**: Some Asana workflows restrict status changes

## API Reference

Asana uses the [Asana API v1.0](https://developers.asana.com/docs/overview). The plugin makes requests to:

- `POST /api/1.0/tasks` - Create tasks
- `PUT /api/1.0/tasks/{task_gid}` - Update task status and details
- `GET /api/1.0/tasks/{task_gid}` - Retrieve task information
- `GET /api/1.0/projects/{project_gid}` - Get project details and statuses

## Best Practices

1. **Project organization**: Use dedicated projects for development tasks
2. **Status mapping**: Align plugin statuses with your team's workflow
3. **Assignee management**: Set `assignee_gid` so new tasks are assigned consistently
4. **File references**: Use `:addfile` to maintain code traceability

## Team Workflows

Each developer sets their own `assignee_gid` in their personal Neovim config;
the shared project can be targeted per-repository with a `.comment-tasks.json`
file (`project_gid` and `assignee_gid` are overridable there — see the
[Configuration Reference](../configuration.md#project-level-configuration-comment-tasksjson)).
