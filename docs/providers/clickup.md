# ClickUp Integration
## Setup
# ClickUp Integration

## Setup
# ClickUp Integration

## Setup

### 1. Get API Key

1. Go to ClickUp Settings → Apps → API
2. Generate a new API key
3. Copy the key for configuration

### 2. Environment Configuration

```bash
export CLICKUP_API_KEY="your_clickup_api_key_here"
```

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        clickup = {
            enabled = true,
            api_key_env = "CLICKUP_API_KEY",
            list_id = "your_clickup_list_id", -- Required
            team_id = "your_clickup_team_id", -- Optional
            
            -- Custom status configuration (match your ClickUp workspace)
            statuses = {
                new = "To Do",              -- Special: used for task creation
                completed = "Complete",     -- Special: used for task completion
                review = "Code Review",     -- Custom status
                in_progress = "In Progress", -- Custom status
                blocked = "Blocked",        -- Custom status
                testing = "QA Testing",     -- Custom status
            }
        }
    }
})
```

### 4. Finding Your IDs

#### List ID (Required)

**Method 1: From ClickUp URL**
```
https://app.clickup.com/[team_id]/v/li/[list_id]
                                    ↳ This is your list_id
```

**Method 2: Using API**
```bash
curl -H "Authorization: YOUR_API_KEY" "https://api.clickup.com/api/v2/team"
```

#### Team ID (Optional but Recommended)
```
https://app.clickup.com/[team_id]/home
                        ↳ This is your team_id
```

## Usage

### Commands

All commands work with your configured statuses:

```vim
:ClickUpTask new          " Create task with 'To Do' status
:ClickUpTask completed    " Update task to 'Complete' status  
:ClickUpTask review       " Update task to 'Code Review' status
:ClickUpTask in_progress  " Update task to 'In Progress' status
:ClickUpTask blocked      " Update task to 'Blocked' status
:ClickUpTask testing      " Update task to 'QA Testing' status
:ClickUpTask addfile      " Add current file to task's SourceFiles field
```


### Cross-Reference Operations

```vim
:ClickUpTaskCrossRef      " Cross-reference tasks in current file
:ClickUpTaskLinkFiles     " Link related files to existing tasks
:ClickUpTask addfile      " Add current file to task's SourceFiles field
```

### Example Workflow

1. **Create a task**:

   ```python
   # TODO: Add user authentication validation
   ```
   
   Place cursor on comment → `:ClickUpTask new`
   
   ```python
   # TODO: Add user authentication validation
   # https://app.clickup.com/t/abc123def
   ```

2. **Update status as you progress**:
   ```vim
   :ClickUpTask in_progress  " When you start working
   :ClickUpTask review       " When ready for code review  
   :ClickUpTask completed    " When finished
   ```

3. **Add file references**:
   ```vim
   :ClickUpTask addfile      " Adds current file to SourceFiles field
   ```

## Configuration Options

### Status Mapping

Configure statuses to match your ClickUp workspace:

```lua
statuses = {
    -- Required statuses
    new = "Backlog",           -- Status for new tasks
    completed = "Done",        -- Status for completed tasks
    
    -- Optional custom statuses (add as many as needed)
    planning = "Planning",
    development = "Development",  
    testing = "Testing",
    deployment = "Deployment",
    blocked = "Blocked - External",
    review = "Code Review",
}
```

### Advanced Configuration

```lua
clickup = {
    enabled = true,
    api_key_env = "CLICKUP_API_KEY",
    list_id = "123456789",
    team_id = "987654321",  -- Recommended for better performance
    
    statuses = {
        new = "To Do",
        completed = "Complete",
        -- Add your custom statuses here
    },
    
    -- Optional: Default assignee ID
    default_assignee = "user_id",
    
    -- Optional: Default priority (1=urgent, 2=high, 3=normal, 4=low)  
    default_priority = 3,
    
    -- Optional: Custom fields
    custom_fields = {
        source_files = "SourceFiles", -- Field name for file tracking
    }
}
```

## Troubleshooting

### "List not found" or "Invalid list_id"

1. **Verify list_id**:
   ```bash
   curl -H "Authorization: YOUR_API_KEY" \\
        "https://api.clickup.com/api/v2/team/TEAM_ID/space"
   ```

2. **Check permissions**: Ensure API key has access to the list

3. **Verify team_id**: Make sure team_id matches the list's team

### "Status not found" Error

1. **Check available statuses**:
   ```bash
   curl -H "Authorization: YOUR_API_KEY" \\
        "https://api.clickup.com/api/v2/list/LIST_ID"
   ```

2. **Update configuration**: Ensure status names in config match ClickUp exactly (case-sensitive)

### API Rate Limits

ClickUp has rate limits (100 requests/minute). For bulk operations:
- Use bulk commands when available
- Add delays between individual API calls if needed
- Consider upgrading ClickUp plan for higher limits

### File References Not Working

1. **Check custom field**: Verify "SourceFiles" field exists in your ClickUp list
2. **Field type**: Ensure it's a text or URL field type
3. **Permissions**: API key needs write access to custom fields

## API Reference

ClickUp uses the [ClickUp API v2](https://clickup.com/api/). The plugin makes requests to:

- `POST /api/v2/list/{list_id}/task` - Create tasks
- `PUT /api/v2/task/{task_id}` - Update task status
- `GET /api/v2/task/{task_id}` - Retrieve task details

## Tips

1. **Use team_id**: Improves API performance and reduces errors
3. **Status naming**: Use clear, descriptive status names in your workspace
4. **File tracking**: Use `:addfile` to maintain source code references
5. **Cross-references**: Use cross-ref commands to link related work

For more examples, see [../examples/workflows.md](../examples/workflows.md#clickup-workflows).
- `PUT /api/v2/task/{task_id}/field/{field_id}` - Update custom fields
