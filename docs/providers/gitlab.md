# GitLab Issues Integration

## Setup

### 1. Get Personal Access Token

1. Go to GitLab → User Settings → Access Tokens
2. Create a new token with these scopes:
   - `api` (full API access)
   - `read_repository` (if needed for private repos)
3. Copy the generated token

### 2. Environment Configuration

```bash
export GITLAB_TOKEN="your_gitlab_personal_access_token"
```

A self-hosted instance URL is configured via the `gitlab_url` option (below),
not an environment variable.

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        gitlab = {
            enabled = true,
            api_key_env = "GITLAB_TOKEN",
            gitlab_url = "https://gitlab.com",  -- GitLab instance URL
            project_id = "12345678",            -- Required: GitLab project ID
        }
    }
})
```

### 4. Finding Your Project ID

#### From GitLab Project Page
1. Go to your project in GitLab
2. Look at Project Information sidebar
3. Copy the "Project ID" number

#### From GitLab URL
```
https://gitlab.com/[group]/[project]/-/settings/general
```
The Project ID is shown in the General settings.

#### Using API
```bash
curl -H "PRIVATE-TOKEN: YOUR_TOKEN" \\
     "https://gitlab.com/api/v4/projects?search=PROJECT_NAME"
```

## Usage

### Commands

GitLab Issues use a simple open/closed model:

```vim
:GitLabTask new          " Create new issue
:GitLabTask close        " Close existing issue
:GitLabTask addfile      " Add current file reference to issue
```

### Example Workflow

1. **Create an issue**:
   ```ruby
   # TODO: Add input sanitization for user uploads
   # Current implementation vulnerable to path traversal
   ```
   
   Place cursor on comment → `:GitLabTask new`
   
   ```ruby
   # TODO: Add input sanitization for user uploads
   # Current implementation vulnerable to path traversal
   # https://gitlab.com/group/project/-/issues/123
   ```

2. **Add file reference**:
   ```vim
   :GitLabTask addfile      " Adds current file to issue description
   ```

3. **Close when finished**:
   ```vim
   :GitLabTask close        " Closes the issue
   ```

## Configuration Options

### Basic Configuration

```lua
gitlab = {
    enabled = true,
    api_key_env = "GITLAB_TOKEN",
    gitlab_url = "https://gitlab.com",  -- or your GitLab instance
    project_id = "12345678",            -- Your project ID
}
```

## Troubleshooting

### "Project not found" or "404 Error"

1. **Verify project ID**:
   ```bash
   curl -H "PRIVATE-TOKEN: YOUR_TOKEN" \\
        "https://gitlab.com/api/v4/projects/PROJECT_ID"
   ```

2. **Check permissions**: Ensure token has access to the project
3. **Private projects**: Verify token has appropriate scope

### "Authentication Failed" (401)

1. **Token validity**: Check if token is expired or revoked
2. **Token scopes**: Ensure token has `api` scope
3. **Instance URL**: Verify correct GitLab instance URL

### Issues Not Linking Properly

1. **URL format**: Ensure issue URLs match GitLab format
2. **Project match**: Verify issue belongs to configured project
3. **Permissions**: Ensure read access to issues

## API Reference

GitLab uses [REST API v4](https://docs.gitlab.com/ee/api/). The plugin makes requests to:

- `POST /api/v4/projects/{id}/issues` - Create issues
- `PUT /api/v4/projects/{id}/issues/{issue_iid}` - Update issues
- `GET /api/v4/projects/{id}/issues/{issue_iid}` - Get issue details
- `POST /api/v4/projects/{id}/issues/{issue_iid}/notes` - Add comments

## Self-Hosted GitLab

For self-hosted GitLab instances:

```lua
gitlab = {
    enabled = true,
    api_key_env = "GITLAB_TOKEN",
    gitlab_url = "https://gitlab.company.com",  -- Your GitLab instance
    project_id = "12345678",
}
```
