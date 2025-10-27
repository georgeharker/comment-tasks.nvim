# Linear Integration
## Setup

### 1. Get API Key

1. Go to Linear → Settings → API
2. Click "Create new API key"
3. Give it a descriptive name (e.g., "Neovim Comment Tasks")
4. Copy the API key

### 2. Environment Configuration

```bash
export LINEAR_API_KEY="your_linear_api_key_here"
```

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        linear = {
            enabled = true,
            api_key_env = "LINEAR_API_KEY",
            team_id = "your_team_id",           -- Required: Linear team ID
            
            -- Custom status configuration (match your Linear workflow)
            statuses = {
                new = "Backlog",                -- Special: used for issue creation
                completed = "Done",             -- Special: used for completion
                in_progress = "In Progress",    -- Custom status
                review = "In Review",           -- Custom status
                blocked = "Blocked",            -- Custom status
                cancelled = "Canceled",         -- Custom status
            },
            
            -- Optional: Default labels for new issues
            default_labels = {"bug", "feature"},
            
            -- Optional: Default assignee ID
            default_assignee = "user_id",
        }
    }
})
```

### 4. Finding Your Team ID

#### Method 1: From Linear URL
```
https://linear.app/[team-name]/team/[team_id]
                                    ↳ This is your team_id
```

#### Method 2: Using API
```bash
curl -H "Authorization: YOUR_API_KEY" \\
     "https://api.linear.app/graphql" \\
     -d '{"query": "{ teams { nodes { id name } } }"}'
```

## Usage

### Commands

All commands work with your configured statuses:

```vim
:LinearTask new           " Create issue with 'Backlog' status
:LinearTask completed     " Update issue to 'Done' status
:LinearTask in_progress   " Update issue to 'In Progress' status
:LinearTask review        " Update issue to 'In Review' status
:LinearTask blocked       " Update issue to 'Blocked' status
:LinearTask cancelled     " Update issue to 'Canceled' status
:LinearTask addfile       " Add current file reference to issue
```

### Example Workflow

1. **Create an issue**:
   ```rust
   // TODO: Optimize database query performance
   // This query is taking too long and needs indexing
   ```
   
   Place cursor on comment → `:LinearTask new`
   
   ```rust
   // TODO: Optimize database query performance
   // This query is taking too long and needs indexing
   // https://linear.app/company/issue/PRJ-123
   ```

2. **Update status as you progress**:
   ```vim
   :LinearTask in_progress  " When you start working
   :LinearTask review       " When ready for review
   :LinearTask completed    " When finished
   ```

3. **Add file references**:
   ```vim
   :LinearTask addfile      " Adds current file to issue description
   ```

## Configuration Options

### Status Mapping

Configure statuses to match your Linear team workflow:

```lua
statuses = {
    -- Required statuses
    new = "Triage",          -- Status for new issues
    completed = "Done",      -- Status for completed issues
    
    -- Optional custom statuses (must exist in your Linear team)
    planning = "Planning",
    development = "In Progress",
    testing = "Testing",
    deployment = "Ready to Deploy", 
    blocked = "Blocked",
    review = "In Review",
    cancelled = "Canceled",
}
```

### Advanced Configuration

```lua
linear = {
    enabled = true,
    api_key_env = "LINEAR_API_KEY",
    team_id = "team_abc123",
    
    statuses = {
        new = "Backlog",
        completed = "Done",
        -- Add your custom statuses here
    },
    
    -- Optional: Default issue configuration
    default_labels = ["bug", "enhancement", "technical-debt"],
    default_assignee = "user_id_here",
    default_priority = 2,        -- 0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low
    
    -- Optional: Project and cycle assignment
    default_project = "project_id",
    default_cycle = "cycle_id",
    
    -- Optional: Issue template
    issue_template = {
        description_prefix = "## Problem\\n",
        description_suffix = "\\n## Solution\\n\\n## Acceptance Criteria\\n- [ ] "
    }
}
```

## Troubleshooting

### "Team not found" or "Invalid team_id"

1. **Verify team_id**:
   ```bash
   curl -H "Authorization: YOUR_API_KEY" \\
        "https://api.linear.app/graphql" \\
        -d '{"query": "{ teams { nodes { id name } } }"}'
   ```

2. **Check permissions**: Ensure API key has access to the team
3. **Team membership**: Verify you're a member of the team

### "State not found" Error

1. **Check available states**:
   ```bash
   curl -H "Authorization: YOUR_API_KEY" \\
        "https://api.linear.app/graphql" \\
        -d '{"query": "{ team(id: \"TEAM_ID\") { states { nodes { id name } } } }"}'
   ```

2. **Case sensitivity**: Status names must match Linear exactly (case-sensitive)
3. **Team-specific states**: Each team has its own workflow states

### "Authentication Failed"

1. **API key validity**: Check if API key is still valid in Linear settings
2. **Permissions**: Verify API key has necessary permissions
3. **Rate limits**: Linear has GraphQL rate limiting

### Issues Not Updating

1. **Issue permissions**: Verify you can edit issues in the team
2. **Workflow restrictions**: Check if team has workflow restrictions
3. **State transitions**: Some workflows may restrict certain state changes

## API Reference

Linear uses [GraphQL API](https://developers.linear.app/docs/graphql/working-with-the-graphql-api). The plugin makes requests to:

- `mutation IssueCreate` - Create issues
- `mutation IssueUpdate` - Update issue status and details  
- `query Issue` - Retrieve issue information
- `query Team` - Get team details and workflow states

## Best Practices

1. **Team organization**: Use dedicated teams for different projects
2. **Status mapping**: Align plugin statuses with your team's workflow
3. **Labels**: Use consistent labeling for better organization
4. **File references**: Use `:addfile` to maintain code traceability
5. **Priorities**: Set appropriate priorities for better triage

## Team Workflows

### Multi-Team Setup

Configure different teams for different projects:

```lua
linear_frontend = {
    enabled = true,
    api_key_env = "LINEAR_API_KEY",
    team_id = "frontend_team_id", 
    statuses = { /* frontend workflow */ }
}

linear_backend = {
    enabled = true,
    api_key_env = "LINEAR_API_KEY",
    team_id = "backend_team_id",
    statuses = { /* backend workflow */ }
}
```

### Label Automation

Automatically assign labels based on context:

```lua
linear = {
    auto_labels = {
        TODO = ["enhancement"],
        FIXME = ["bug", "urgent"],
        HACK = ["technical-debt"],
        PERF = ["performance", "optimization"]
    }
}
```

For more examples, see [../examples/workflows.md](../examples/workflows.md#linear-workflows).
