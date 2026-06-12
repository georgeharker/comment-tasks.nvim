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
export NOTION_API_KEY="your_notion_integration_token_here"
```

### 4. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        notion = {
            enabled = true,
            api_key_env = "NOTION_API_KEY",
            database_id = "your_database_id",       -- Required: Notion database ID
            
            -- Custom status configuration (match your database Status property)
            statuses = {
                new = "Not started",        -- Special: used for task creation
                completed = "Done",         -- Special: used for completion
                in_progress = "In progress", -- Custom status
                review = "Review",          -- Custom status
                blocked = "Blocked",        -- Custom status
            },
            
            -- Optional: Default assignee (people property "Assignee")
            assignee_id = "user_id",
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

### Database Properties

The plugin expects fixed property names in your database:

- A **title** property named `Name` — used for the task title
- A **status** property named `Status` — used for status updates
- Optionally, a **people** property named `Assignee` — set when `assignee_id`
  is configured

```lua
notion = {
    enabled = true,
    api_key_env = "NOTION_API_KEY",
    database_id = "abc123def456789...",
    
    -- Required: Status configuration
    statuses = {
        new = "Not started",
        completed = "Done", 
        -- Add your database status options here
    },
    
    -- Optional: Default assignee
    assignee_id = "user_id",
}
```
