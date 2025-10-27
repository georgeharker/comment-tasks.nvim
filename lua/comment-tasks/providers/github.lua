-- GitHub provider for comment-tasks plugin

local interface = require("comment-tasks.providers.interface")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local GitHubProvider = {}
GitHubProvider.__index = GitHubProvider
setmetatable(GitHubProvider, { __index = Provider })

--- Create a new GitHub provider instance
function GitHubProvider:new(provider_config)
    local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function GitHubProvider:is_enabled()
    if not self.config.enabled then
        return false, "GitHub provider is disabled"
    end

    if not self.config.repo_owner or not self.config.repo_name then
        return false, "GitHub repo_owner and repo_name not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Get environment variable name for API key
function GitHubProvider:get_api_key_env()
    return self.config.api_key_env or "GITHUB_TOKEN"
end

--- Create a new GitHub issue
function GitHubProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.repo_owner or not self.config.repo_name then
        callback(nil, "GitHub repo_owner and repo_name not configured")
        return
    end

    -- Prepare issue data
    local body = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        body = body .. " in " .. filename .. "\n\n**Source Files:**\n- " .. filename
    end

    local issue_data = {
        title = task_name,
        body = body,
        labels = {"task", "from-neovim"}
    }

    local json_data = vim.fn.json_encode(issue_data)
    local api_url = "https://api.github.com/repos/" ..
                   self.config.repo_owner .. "/" ..
                   self.config.repo_name .. "/issues"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            accept = "application/vnd.github+json",
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            ["X-GitHub-Api-Version"] = "2022-11-28",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 201 then
                    callback(
                        nil,
                        "GitHub API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success or not response then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response and response.html_url then
                    callback(response.html_url, nil)
                else
                    callback(nil, "No issue URL in response")
                end
            end)
        end,
    })
end

--- Update GitHub issue status (open/closed)
function GitHubProvider:update_task_status(issue_number, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.repo_owner or not self.config.repo_name then
        callback(nil, "GitHub repo_owner and repo_name not configured")
        return
    end

    -- GitHub only supports open/closed
    local is_closed = (status == "complete" or status == "closed")

    local issue_data = {
        state = is_closed and "closed" or "open"
    }

    local json_data = vim.fn.json_encode(issue_data)
    local api_url = "https://api.github.com/repos/" ..
                   self.config.repo_owner .. "/" ..
                   self.config.repo_name .. "/issues/" .. issue_number

    curl.request({
        url = api_url,
        method = "patch",
        headers = {
            accept = "application/vnd.github+json",
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            ["X-GitHub-Api-Version"] = "2022-11-28",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "GitHub API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, _response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

--- Add file reference to GitHub issue
function GitHubProvider:add_file_to_task(issue_number, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.repo_owner or not self.config.repo_name then
        callback(nil, "GitHub repo_owner and repo_name not configured")
        return
    end

    -- Get current issue to append to existing body
    local get_url = "https://api.github.com/repos/" ..
                   self.config.repo_owner .. "/" ..
                   self.config.repo_name .. "/issues/" .. issue_number

    curl.request({
        url = get_url,
        method = "get",
        headers = {
            accept = "application/vnd.github+json",
            Authorization = "Bearer " .. api_key,
            ["X-GitHub-Api-Version"] = "2022-11-28",
        },
        callback = function(get_result)
            vim.schedule(function()
                if get_result.status ~= 200 then
                    callback(nil, "Failed to get current issue")
                    return
                end

                local success, issue = pcall(vim.fn.json_decode, get_result.body)
                if not success then
                    callback(nil, "Failed to parse issue JSON")
                    return
                end

                -- Append files to issue body
                local updated_body = (issue and issue.body) or ""
                local files_section = "\n\n**Source Files:**\n"
                files_section = files_section .. "- " .. filename .. "\n"

                -- Check if files section already exists and update/append accordingly
                if updated_body:match("%*%*Source Files:%*%*") then
                    -- Add to existing files section
                    updated_body = updated_body:gsub("(\n%*%*Source Files:%*%*\n)", "%1- " .. filename .. "\n")
                else
                    -- Append new files section
                    updated_body = updated_body .. files_section
                end

                local update_data = { body = updated_body }
                local json_data = vim.fn.json_encode(update_data)

                curl.request({
                    url = get_url,
                    method = "patch",
                    headers = {
                        accept = "application/vnd.github+json",
                        Authorization = "Bearer " .. api_key,
                        ["Content-Type"] = "application/json",
                        ["X-GitHub-Api-Version"] = "2022-11-28",
                    },
                    body = json_data,
                    callback = function(update_result)
                        vim.schedule(function()
                            if update_result.status ~= 200 then
                                callback(nil, "Failed to update issue with files")
                                return
                            end
                            callback(true, nil)
                        end)
                    end,
                })
            end)
        end,
    })
end

--- Extract GitHub issue number from URL
function GitHubProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    return url:match("https://github%.com/[%w%-_%.]+/[%w%-_%.]+/issues/([0-9]+)")
end

--- Check if URL belongs to GitHub
function GitHubProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("https://github%.com/") ~= nil
end

--- Get GitHub URL pattern for extraction
function GitHubProvider:get_url_pattern()
    return "(https://github%.com/[%w%-_%.]+/[%w%-_%.]+/issues/[0-9]+)"
end

-- Register the GitHub provider
interface.register_provider("github", GitHubProvider)

return GitHubProvider
