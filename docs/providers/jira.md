# Jira Integration
## Setup

### 1. Get API Token

1. Go to Atlassian Account Settings → Security → API tokens
2. Click "Create API token"
3. Give it a descriptive label (e.g., "Neovim Comment Tasks")
4. Copy the token immediately

### 2. Environment Configuration

```bash
export JIRA_API_TOKEN="your_api_token_here"
```

The token is sent as a Bearer token; the instance URL is set via the
`server_url` config option below.

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        jira = {
            enabled = true,
            server_url = "https://your-domain.atlassian.net",  -- Your Jira instance URL
            api_key_env = "JIRA_API_TOKEN",             -- Environment variable for API token
            project_key = "PROJ",                       -- Required: Jira project key
            
            -- Custom status configuration (match your Jira workflow)
            statuses = {
                new = "To Do",                  -- Special: used for issue creation
                completed = "Done",             -- Special: used for completion
                in_progress = "In Progress",    -- Custom workflow status
                review = "Code Review",         -- Custom workflow status
                testing = "Testing",            -- Custom workflow status
                blocked = "Blocked",            -- Custom workflow status
                cancelled = "Cancelled",        -- Custom workflow status
            },
            
            -- Optional: Default issue configuration
            issue_type = "Task",                -- Default issue type
            assignee_id = "account_id",         -- Optional: default assignee account ID
        }
    }
})
```

### 4. Finding Your Configuration Values

#### Jira Instance URL
Your Jira URL format:
```
https://[your-domain].atlassian.net
```

#### Project Key
From any issue URL:
```
https://your-domain.atlassian.net/browse/[PROJECT_KEY]-123
                                         ↳ This is your project_key
```

Or from Project Settings → Details → Key

## Usage

### Commands

All commands work with your configured statuses:

```vim
:JiraTask new           " Create issue with 'To Do' status
:JiraTask completed     " Update issue to 'Done' status
:JiraTask in_progress   " Update issue to 'In Progress' status
:JiraTask review        " Update issue to 'Code Review' status
:JiraTask testing       " Update issue to 'Testing' status
:JiraTask blocked       " Update issue to 'Blocked' status
:JiraTask cancelled     " Update issue to 'Cancelled' status
:JiraTask addfile       " Add current file reference to issue
```

### Example Workflow

1. **Create an issue**:
   ```java
   // TODO: Implement user permission validation
   // Need to check roles and access levels for each endpoint
   ```
   
   Place cursor on comment → `:JiraTask new`
   
   ```java
   // TODO: Implement user permission validation  
   // Need to check roles and access levels for each endpoint
   // https://company.atlassian.net/browse/PROJ-456
   ```

2. **Update status through development lifecycle**:
   ```vim
   :JiraTask in_progress  " When you start development
   :JiraTask review       " When ready for code review
   :JiraTask testing      " When moved to QA testing
   :JiraTask completed    " When fully complete
   ```

3. **Add file references**:
   ```vim
   :JiraTask addfile      " Adds current file to issue description
   ```

## Configuration Options

### Status Mapping

Configure statuses to match your Jira project workflow:

```lua
statuses = {
    -- Required statuses
    new = "Open",            -- Status for new issues (must exist in workflow)
    completed = "Resolved",  -- Status for completed issues (must exist in workflow)
    
    -- Optional custom statuses (must exist in your Jira workflow)
    analysis = "Analysis",
    development = "In Progress", 
    code_review = "Code Review",
    testing = "Testing",
    deployment = "Ready for Release",
    blocked = "Blocked",
    rejected = "Rejected",
}
```

### Advanced Configuration

```lua
jira = {
    enabled = true,
    server_url = "https://company.atlassian.net",
    api_key_env = "JIRA_API_TOKEN",
    project_key = "DEVOPS",
    
    statuses = {
        new = "To Do",
        completed = "Done",
        -- Add your workflow statuses here
    },
    
    -- Optional: Issue configuration  
    issue_type = "Story",               -- Bug, Task, Story, Epic, etc.
    assignee_id = "account_id",         -- Optional: default assignee account ID
}
```

## Troubleshooting

### "Project not found" or "Invalid project key"

1. **Verify project key**:
   - Check project settings in Jira
   - Ensure key is uppercase (e.g., "PROJ", not "proj")
   - Verify you have access to the project

2. **Check permissions**: 
   - Create Issues permission
   - Browse Projects permission

### "Status not found" or "Invalid transition"

1. **Check available statuses**:
   ```bash
   curl -u "email@domain.com:api_token" \\
        "https://your-domain.atlassian.net/rest/api/2/project/PROJECT_KEY/statuses"
   ```

2. **Workflow restrictions**:
   - Some status changes may be restricted by workflow rules
   - Check Jira workflow configuration
   - Verify transition permissions

3. **Status name matching**:
   - Status names must match Jira exactly (case-sensitive)
   - Use the status name, not the transition name

### "Authentication Failed" (401/403)

1. **API token validity**:
   - Ensure API token is not expired
   - Check token permissions in Atlassian account

2. **Test authentication**:
   ```bash
   curl -u "email@domain.com:api_token" \\
        "https://your-domain.atlassian.net/rest/api/2/myself"
   ```

### "Issue Type not found"

1. **Check available issue types**:
   ```bash
   curl -u "email@domain.com:api_token" \\
        "https://your-domain.atlassian.net/rest/api/2/project/PROJECT_KEY/issuetypes"
   ```

2. **Issue type permissions**: 
   - Verify you can create issues of that type
   - Check project configuration

## API Reference

Jira uses the [REST API v2/v3](https://developer.atlassian.com/server/jira/platform/rest-apis/). The plugin makes requests to:

- `POST /rest/api/2/issue` - Create issues
- `PUT /rest/api/2/issue/{issueKey}` - Update issue details
- `POST /rest/api/2/issue/{issueKey}/transitions` - Change issue status
- `GET /rest/api/2/issue/{issueKey}` - Retrieve issue information

## Enterprise Features

### Multi-Project Setup

To target a different Jira project per repository, use a `.comment-tasks.json`
file at the project root — `project_key` and `server_url` are overridable
there (see the
[Configuration Reference](../configuration.md#project-level-configuration-comment-tasksjson)):

```json
{
    "providers": {
        "jira": { "project_key": "DEV", "server_url": "https://company.atlassian.net" }
    }
}
```

### Workflow Automation

Configure for complex approval workflows:

```lua
jira = {
    -- Workflow-specific status mapping
    statuses = {
        new = "Open",
        analysis = "Analysis", 
        development = "In Progress",
        code_review = "Code Review",
        security_review = "Security Review", 
        testing = "Testing",
        deployment = "Ready for Release",
        completed = "Resolved",
        rejected = "Won't Do"
    }
}
```
