# Notion Integration
## Setup

### 1. Create Integration

1. Go to [Notion Integrations](https://www.notion.so/my-integrations)
2. Click "New integration"
3. Give it a name (e.g., "Comment Tasks")
4. Select your workspace
5. Copy the "Internal Integration Token"

### 2. Share Database

1. Open your Notion database
2. Click "Share" → "Add people"
3. Search for your integration name
4. Give it "Can edit" permissions

### 3. Environment Configuration

```bash
export NOTION_TOKEN="your_notion_integration_token_here"
```

### 4. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        notion = {
            enabled = true,
            api_key_env = "NOTION_TOKEN",
            database_id = "your_database_id",       -- Required: Notion database ID
            
            -- Custom status configuration (match your database Status property)
            statuses = {
                new = "Not started",        -- Special: used for task creation
                completed = "Done",         -- Special: used for completion
                in_progress = "In progress", -- Custom status
                review = "Review",          -- Custom status
                blocked = "Blocked",        -- Custom status
            },
            
            -- Optional: Property configuration
            title_property = "Name",        -- Property name for task title
            status_property = "Status",     -- Property name for status
            url_property = "URL",           -- Property name for storing URLs
        }
    }
})
```

### 5. Finding Your Database ID

#### From Notion URL
```
https://notion.so/[DATABASE_ID]?v=...
                  ↳ This is your database_id (32 characters)
```

#### From Share Link
1. Click "Share" on your database
2. Copy link
3. Extract the ID from the URL

## Usage

### Commands

```vim
:NotionTask new           " Create page with 'Not started' status
:NotionTask completed     " Update page to 'Done' status
:NotionTask in_progress   " Update page to 'In progress' status
:NotionTask review        " Update page to 'Review' status
:NotionTask blocked       " Update page to 'Blocked' status
:NotionTask addfile       " Add current file reference to page
```

### Example Workflow

```typescript
// TODO: Implement real-time collaboration features
// Need WebSocket connection and conflict resolution
```

Place cursor on comment → `:NotionTask new`

```typescript
// TODO: Implement real-time collaboration features
// Need WebSocket connection and conflict resolution  
// https://notion.so/abc123def456789...
```

## Configuration Options

### Database Property Mapping

```lua
notion = {
    enabled = true,
    api_key_env = "NOTION_TOKEN",
    database_id = "abc123def456789...",
    
    -- Required: Status configuration
    statuses = {
        new = "Not started",
        completed = "Done", 
        -- Add your database status options here
    },
    
    -- Property names (must match your database)
    title_property = "Task",            -- Title property name
    status_property = "Status",         -- Status property name  
    url_property = "Source URL",        -- URL property name
    description_property = "Description", -- Description property name
    
    -- Optional: Additional properties
    properties = {
        priority = "Priority",          -- Priority property
        assignee = "Assignee",          -- Person property for assignment
        tags = "Tags",                  -- Multi-select property for tags
        due_date = "Due Date",          -- Date property
        project = "Project",            -- Select property for project
    }
}
```

For more examples, see [../examples/workflows.md](../examples/workflows.md#notion-workflows).
