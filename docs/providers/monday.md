# Monday.com Integration
## Setup

### 1. Get API Token

1. Go to Monday.com → Profile picture → Admin → API
2. Click "Generate" to create a new API token
3. Copy the generated token

### 2. Environment Configuration

```bash
export MONDAY_API_TOKEN="your_monday_api_token_here"
```

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        monday = {
            enabled = true,
            api_key_env = "MONDAY_API_TOKEN",
            board_id = "your_board_id",         -- Required: Monday.com board ID
            
            -- Custom status configuration (match your board's status column)
            statuses = {
                new = "Stuck",              -- Special: used for item creation
                completed = "Done",         -- Special: used for completion
                in_progress = "Working on it", -- Custom status
                review = "Review",          -- Custom status
                blocked = "Blocked",        -- Custom status
            },
            
            -- Optional: Default group for new items
            group_id = "topics",            -- Group/section ID
            
            -- Optional: Default assignee
            default_assignee = "user_id",   -- User ID for assignment
        }
    }
})
```

### 4. Finding Your IDs

#### Board ID

**From Monday.com URL:**
```
https://[workspace].monday.com/boards/[BOARD_ID]
                                     ↳ This is your board_id
```

**Using API:**
```bash
curl -H "Authorization: YOUR_API_TOKEN" \\
     -H "Content-Type: application/json" \\
     -d '{"query": "{ boards { id name } }"}' \\
     "https://api.monday.com/v2"
```

#### Group ID (Optional)
```bash
curl -H "Authorization: YOUR_API_TOKEN" \\
     -H "Content-Type: application/json" \\
     -d '{"query": "{ boards(ids: [BOARD_ID]) { groups { id title } } }"}' \\
     "https://api.monday.com/v2"
```

## Usage

### Commands

```vim
:MondayTask new           " Create item with configured status
:MondayTask completed     " Update item to 'Done' status
:MondayTask in_progress   " Update item to 'Working on it' status
:MondayTask review        " Update item to 'Review' status
:MondayTask blocked       " Update item to 'Blocked' status
:MondayTask addfile       " Add current file reference to item
```

### Example Workflow

```go
// TODO: Optimize database connection pooling
// Current implementation creates too many connections
```

Place cursor on comment → `:MondayTask new`

```go
// TODO: Optimize database connection pooling
// Current implementation creates too many connections
// https://workspace.monday.com/boards/123456789/pulses/987654321
```

## Configuration Options

### Advanced Configuration

```lua
monday = {
    enabled = true,
    api_key_env = "MONDAY_API_TOKEN", 
    board_id = "123456789",
    
    statuses = {
        new = "Stuck",
        completed = "Done",
        -- Add your board's status options here
    },
    
    -- Optional: Board organization
    group_id = "new_group",             -- Default group for new items
    default_assignee = "user_id",       -- Default person column value
    
    -- Optional: Column mapping
    columns = {
        status = "status",              -- Status column ID
        person = "person",              -- Person column ID
        date = "date4",                 -- Date column ID
        text = "text",                  -- Text column ID
    },
    
    -- Optional: Item template
    item_template = {
        name_prefix = "🔧 ",           -- Prefix for item names
        updates_template = "Source: {filename}\\nDescription: {comment_text}"
    }
}
```

For more examples, see [../examples/workflows.md](../examples/workflows.md#monday-workflows).
