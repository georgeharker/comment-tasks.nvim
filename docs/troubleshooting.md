# Troubleshooting Guide

This guide covers common issues and solutions for comment-tasks.nvim.

## Configuration Issues

### "Provider is disabled" Error

**Problem**: Provider commands are not available or return "disabled" error.

**Solutions**:

1. **Check provider configuration**:
   ```lua
   -- Ensure enabled = true
   providers = {
       clickup = {
           enabled = true,  -- ← Must be true
           -- ... other config
       }
   }
   ```

2. **Verify required fields**:
   ```lua
   -- Each provider needs specific required fields
   clickup = {
       enabled = true,
       api_key_env = "CLICKUP_API_KEY",
       list_id = "123456789",  -- ← Required for ClickUp
       -- ... status configuration
   }
   ```

3. **Check debug output**:
   ```vim
   :lua print(vim.inspect(require("comment-tasks").get_config()))
   ```

### "API key not found in environment variable" Error

**Problem**: Plugin can't find your API key in environment variables.

**Solutions**:

1. **Verify environment variable is set**:
   ```bash
   echo $CLICKUP_API_KEY
   echo $GITHUB_TOKEN
   # Should output your API key, not empty
   ```

2. **Set environment variable properly**:
   ```bash
   # In your shell profile (.bashrc, .zshrc, etc.)
   export CLICKUP_API_KEY="your_api_key_here"
   
   # Reload your shell or restart Neovim
   source ~/.zshrc
   ```

3. **Check environment variable name**:
   ```lua
   -- Ensure api_key_env matches your actual env var name
   clickup = {
       api_key_env = "CLICKUP_API_KEY",  -- ← Must match exactly
   }
   ```

4. **Test in Neovim**:
   ```vim
   :lua print(vim.env.CLICKUP_API_KEY)
   ```

### "Required field not configured" Error

**Problem**: Missing required configuration fields for your provider.

**Solutions**:

**ClickUp**:
```lua
clickup = {
    enabled = true,
    api_key_env = "CLICKUP_API_KEY",
    list_id = "123456789",  -- ← Required
    -- team_id is optional but recommended
}
```

**GitHub**:
```lua
github = {
    enabled = true,
    api_key_env = "GITHUB_TOKEN", 
    repo_owner = "username",    -- ← Required
    repo_name = "repository",   -- ← Required
}
```

**Asana**:
```lua
asana = {
    enabled = true,
    api_key_env = "ASANA_ACCESS_TOKEN",
    project_gid = "1234567890",  -- ← Required
}
```

## API and Connection Issues

### "Status not found" or "Invalid transition" Error

**Problem**: Status names in your configuration don't match the provider's actual statuses.

**Solutions**:

1. **Check available statuses in your provider**:

   **ClickUp**:
   ```bash
   curl -H "Authorization: YOUR_API_KEY" \
        "https://api.clickup.com/api/v2/list/LIST_ID"
   ```

   **Asana**:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \
        "https://app.asana.com/api/1.0/projects/PROJECT_GID"
   ```

2. **Update configuration to match exactly**:
   ```lua
   -- Status names are case-sensitive and must match exactly
   statuses = {
       new = "To Do",           -- ← Must match ClickUp status exactly
       completed = "Complete",  -- ← Must match ClickUp status exactly
   }
   ```

3. **Use provider's web interface** to verify status names

### Authentication Errors (401/403)

**Problem**: API requests are being rejected due to authentication issues.

**Solutions**:

1. **Verify API key is valid**:
   - Check if key has expired
   - Regenerate key if necessary
   - Ensure key has correct permissions

2. **Check API key permissions**:
   
   **GitHub**: Needs `repo` scope for private repos, `public_repo` for public
   
   **ClickUp**: Needs access to the specific workspace and list
   
   **Asana**: Needs access to the project and workspace

3. **Test API key manually**:
   ```bash
   # GitHub
   curl -H "Authorization: token YOUR_TOKEN" \
        "https://api.github.com/user"
   
   # ClickUp  
   curl -H "Authorization: YOUR_API_KEY" \
        "https://api.clickup.com/api/v2/user"
   ```

### Rate Limit Errors (429)

**Problem**: Too many API requests in a short time period.

**Solutions**:

1. **Wait for rate limit reset** (usually 1 hour)

2. **Reduce request frequency**:
   - Avoid rapid successive task updates
   - Use bulk operations when available (ClickUp)

3. **Check rate limits**:
   - **GitHub**: 5,000/hour for authenticated requests
   - **ClickUp**: 100/minute  
   - **Asana**: 1,500/hour

## Comment Detection Issues

### "No comment found on current line" Error

**Problem**: Plugin can't detect a comment on the current line.

**Solutions**:

1. **Position cursor correctly**:
   ```python
   # TODO: Fix this issue  ← Cursor should be on this line
   def my_function():
       pass
   ```

2. **Check language detection**:
   ```vim
   :set filetype?
   " Should show correct filetype (python, javascript, etc.)
   ```

3. **Force language detection**:
   ```vim
   :ClickUpTask new python    " Force treat as Python comment
   :GitHubTask new javascript " Force treat as JavaScript comment
   ```

4. **Verify comment syntax**:
   ```python
   # This is detected ✅
   ## This is detected ✅  
   # TODO: This is detected ✅
   
   This is not a comment ❌
   ```

### Comments Not Being Detected in Specific Languages

**Problem**: Comments work in some files but not others.

**Solutions**:

1. **Check supported languages**:
   - Python: `#`
   - JavaScript/TypeScript: `//`, `/* */`
   - Lua: `--`, `--[[ ]]`
   - Rust: `//`, `/* */`
   - And 10+ more languages

2. **Override language detection**:
   ```lua
   -- In configuration
   languages = {
       custom_lang = {
           single_line = "%%",     -- Custom single line comment  
           block_start = "%{",     -- Custom block start
           block_end = "%}"        -- Custom block end
       }
   }
   ```

3. **Check Tree-sitter support**:
   ```vim
   :TSInstall python javascript lua rust
   ```

## Command Issues

### Commands Not Available

**Problem**: `:ClickUpTask`, `:GitHubTask` etc. commands don't exist.

**Solutions**:

1. **Check if plugin is loaded**:
   ```vim
   :lua print(require("comment-tasks"))
   " Should not error
   ```

2. **Verify provider is enabled and configured**:
   ```vim
   :lua print(vim.inspect(require("comment-tasks").get_providers()))
   ```

3. **Check for configuration errors**:
   ```vim
   " Look for error messages during startup
   :messages
   ```

4. **Restart Neovim** after configuration changes

### Dynamic Commands Missing

**Problem**: Custom status commands (e.g., `:ClickUpTask review`) are not available.

**Solutions**:

1. **Check status configuration**:
   ```lua
   statuses = {
       new = "To Do",
       completed = "Complete", 
       review = "Code Review",  -- ← Creates :ClickUpTask review
   }
   ```

2. **Verify status names are valid**:
   - No spaces in status keys
   - Use underscores: `in_progress` not `in progress`
   - Must be valid Vim command names

3. **Check command completion**:
   ```vim
   :ClickUpTask <Tab>
   " Should show your configured statuses
   ```

## File Reference Issues

### File References Not Being Added

**Problem**: `:addfile` command doesn't add file references to tasks.

**Solutions**:

1. **Check if provider supports file references**:
   - ✅ All providers support basic file references
   - ✅ ClickUp has advanced SourceFiles field support

2. **Verify file path**:
   ```vim
   :pwd  " Check current working directory
   :echo expand('%:p')  " Check full file path
   ```

3. **Test with full path**:
   ```vim
   :ClickUpTask addfile /full/path/to/file.py
   ```

## Provider-Specific Issues

### ClickUp Issues

**List ID Problems**:
```bash
# Get list ID from URL or API
curl -H "Authorization: YOUR_API_KEY" \
     "https://api.clickup.com/api/v2/team/TEAM_ID/space"
```

**Custom Field Issues**:
- Ensure SourceFiles field exists in your ClickUp list
- Field must be text or URL type
- Check field permissions

### GitHub Issues

**Repository Access**:
```bash
# Test repository access
curl -H "Authorization: token YOUR_TOKEN" \
     "https://api.github.com/repos/OWNER/REPO"
```

**Token Scopes**:
- Public repos: `public_repo`
- Private repos: `repo` 
- Organizations: May need additional permissions

### Asana Issues

**Project Access**:
```bash
# Verify project access
curl -H "Authorization: Bearer YOUR_TOKEN" \
     "https://app.asana.com/api/1.0/projects/PROJECT_GID"
```

**Workspace Permissions**:
- Ensure you're a member of the workspace
- Check if project is archived or deleted

## Debug Commands

### Check Configuration

```vim
" View full configuration
:lua print(vim.inspect(require("comment-tasks").get_config()))

" Check specific provider
:lua print(vim.inspect(require("comment-tasks").get_provider_config("clickup")))

" View available providers
:lua print(vim.inspect(require("comment-tasks").get_providers()))
```

### Test Provider Connections

```vim
" Test environment variables
:lua print(vim.env.CLICKUP_API_KEY)
:lua print(vim.env.GITHUB_TOKEN)

" Test provider configuration  
:lua require("comment-tasks").validate_provider("clickup")
```

### Enable Debug Logging

```lua
-- In your configuration
require("comment-tasks").setup({
    debug = true,  -- Enable debug output
    -- ... your other config
})
```

## Getting Help

### Information to Include in Bug Reports

1. **Neovim version**: `:version`
2. **Plugin version**: Latest commit or release tag
3. **Configuration**: Your setup() call (remove API keys!)
4. **Error messages**: Full error output
5. **Environment**: OS, shell, environment variables (names only)
6. **Steps to reproduce**: Exact steps that cause the issue

### Debug Information Commands

```vim
" System information
:version
:checkhealth

" Plugin information
:lua print(require("comment-tasks").version)
:lua print(vim.inspect(require("comment-tasks").get_config()))

" Environment check (safe - doesn't show values)
:lua for k,v in pairs(vim.env) do if k:match("API") or k:match("TOKEN") then print(k .. "=" .. (v and "SET" or "UNSET")) end end
```

### Common Solutions Checklist

Before asking for help, verify:

- [ ] Environment variables are set correctly
- [ ] Provider configuration includes all required fields  
- [ ] API keys have correct permissions
- [ ] Status names match provider exactly (case-sensitive)
- [ ] Plugin is loaded without errors (`:messages`)
- [ ] Commands are available (tab completion works)
- [ ] Comment detection works (cursor on comment line)

### Support Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community help  
- **Documentation**: Check [docs/](../) for detailed guides

Remember to remove API keys and sensitive information before sharing configuration!