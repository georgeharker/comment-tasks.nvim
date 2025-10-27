# GitHub Issues Integration

## Setup

### 1. Get Personal Access Token

1. Go to GitHub Settings → Developer Settings → Personal Access Tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name
4. Select required scopes:
   - **`repo`** - For private repositories (full access)
   - **`public_repo`** - For public repositories only
5. Click "Generate token"
6. Copy the token immediately (you won't see it again)

### 2. Environment Configuration

```bash
export GITHUB_TOKEN="your_github_personal_access_token_here"
```

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        github = {
            enabled = true,
            api_key_env = "GITHUB_TOKEN",
            repo_owner = "username",     -- Required: GitHub username or organization
            repo_name = "repository",    -- Required: Repository name
            
            -- Optional: Default labels for new issues
            default_labels = {"bug", "enhancement"},
            
            -- Optional: Default assignee (GitHub username)
            default_assignee = "username",
        }
    }
})
```

### 4. Repository Information

Get your repository details from the GitHub URL:
```
https://github.com/[owner]/[repository]
                   ↳        ↳
               repo_owner   repo_name
```

## Usage

### Commands

```vim
:GitHubTask new          " Create new issue
:GitHubTask close        " Close existing issue
:GitHubTask addfile      " Add current file reference to issue
```

### Status Management

GitHub Issues use a simple open/closed model:
- **`new`** → Creates issue in "open" state
- **`close`** → Closes the issue

### Example Workflow

1. **Create an issue**:
   ```javascript  
   // TODO: Add input validation for user registration form
   // This should check email format and password strength
   ```
   
   Place cursor on comment → `:GitHubTask new`
   
   ```javascript
   // TODO: Add input validation for user registration form  
   // This should check email format and password strength
   // https://github.com/username/repo/issues/123
   ```

2. **Add file reference**:
   ```vim
   :GitHubTask addfile      " Adds current file to issue description
   ```

3. **Close when finished**:
   ```vim
   :GitHubTask close        " Closes the issue
   ```

## Configuration Options

### Basic Configuration

```lua
github = {
    enabled = true,
    api_key_env = "GITHUB_TOKEN",
    repo_owner = "your-username",
    repo_name = "your-repository",
}
```

### Advanced Configuration

```lua
github = {
    enabled = true,
    api_key_env = "GITHUB_TOKEN",
    repo_owner = "your-organization",
    repo_name = "your-repository",
    
    -- Optional: Default labels for new issues
    default_labels = {
        "todo",           -- For TODO comments
        "bug",            -- For FIXME comments  
        "enhancement",    -- For FEATURE comments
    },
    
    -- Optional: Default assignee
    default_assignee = "developer-username",
    
    -- Optional: Default milestone ID
    default_milestone = 1,
    
    -- Optional: Issue template
    issue_template = {
        body_prefix = "## Description\\n",
        body_suffix = "\\n## Acceptance Criteria\\n- [ ] Code implemented\\n- [ ] Tests written\\n- [ ] Documentation updated"
    }
}
```

### Labels and Context

The plugin can automatically add appropriate labels based on comment context:

```lua
-- Configuration
github = {
    auto_labels = {
        TODO = {"enhancement", "todo"},
        FIXME = {"bug", "urgent"},
        HACK = {"technical-debt", "refactor"},
        NOTE = {"documentation"}
    }
}
```

## Troubleshooting

### "Authentication Failed" or "401 Unauthorized"

1. **Check token**: Verify `GITHUB_TOKEN` environment variable is set
2. **Token permissions**: Ensure token has correct scopes (`repo` or `public_repo`)
3. **Token expiry**: Check if token has expired and regenerate if needed

### "Repository Not Found" or "404 Error"

1. **Verify repository**: Ensure `repo_owner` and `repo_name` are correct
2. **Check access**: Verify token has access to the repository
3. **Private repos**: Ensure token has `repo` scope for private repositories

### "Rate Limit Exceeded"

GitHub has API rate limits:
- **Authenticated requests**: 5,000 per hour
- **Search API**: 30 per minute

Solutions:
- Wait for rate limit reset
- Use more specific operations
- Consider GitHub Apps for higher limits

### Issues Not Linking Properly

1. **Check URL format**: Ensure issue URLs are valid GitHub issue links
2. **Repository match**: Verify the issue belongs to the configured repository
3. **Permissions**: Ensure you have read access to the issues

## API Reference

GitHub Issues uses the [GitHub REST API v3](https://docs.github.com/en/rest/issues). The plugin makes requests to:

- `POST /repos/{owner}/{repo}/issues` - Create issues
- `PATCH /repos/{owner}/{repo}/issues/{number}` - Update issues  
- `GET /repos/{owner}/{repo}/issues/{number}` - Get issue details
- `POST /repos/{owner}/{repo}/issues/{number}/comments` - Add comments

## Integration Tips

1. **Use descriptive titles**: The plugin extracts meaningful titles from comments
2. **Add context**: Include relevant code context in issue descriptions
3. **Link files**: Use `:GitHubTask addfile` to reference source locations
4. **Label consistently**: Use consistent labeling for better organization
5. **Cross-reference**: Reference related issues using #123 syntax

## Multiple Repositories

To work with multiple repositories, set up separate configurations:

```lua
github_frontend = {
    enabled = true,
    api_key_env = "GITHUB_TOKEN", 
    repo_owner = "company",
    repo_name = "frontend-app",
},

github_backend = {
    enabled = true,
    api_key_env = "GITHUB_TOKEN",
    repo_owner = "company", 
    repo_name = "backend-api",
}
```

For more examples, see [../examples/workflows.md](../examples/workflows.md#github-workflows).
## Multiple Repositories

To work with multiple repositories, set up separate configurations:

```lua
-- You can configure different providers for different projects
github_frontend = {
    enabled = true,
    api_key_env = "GITHUB_TOKEN", 
    repo_owner = "company",
    repo_name = "frontend-app",
},

github_backend = {
    enabled = true,
    api_key_env = "GITHUB_TOKEN",
    repo_owner = "company", 
    repo_name = "backend-api",
}
```
