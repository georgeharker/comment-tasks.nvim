-- GitLab provider for comment-tasks plugin

local interface = require("comment-tasks.providers.interface")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local GitLabProvider = {}
GitLabProvider.__index = GitLabProvider
setmetatable(GitLabProvider, { __index = Provider })

--- Create a new GitLab provider instance
function GitLabProvider:new(provider_config)
    local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function GitLabProvider:is_enabled()
    if not self.config.enabled then
        return false, "GitLab provider is disabled"
    end

    if not self.config.project_id then
        return false, "GitLab project_id not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Get GitLab base URL (supports self-hosted GitLab)
function GitLabProvider:get_base_url()
    return self.config.gitlab_url or "https://gitlab.com"
end

--- Get GitLab API base URL
function GitLabProvider:get_api_base_url()
    return self:get_base_url() .. "/api/v4"
end

--- Create a new GitLab issue
function GitLabProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.project_id then
        callback(nil, "GitLab project_id not configured")
        return
    end

    -- Prepare issue data
    local description = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        description = description .. " in `" .. filename .. "`\n\n**Source Files:**\n- " .. filename
    end

    local issue_data = {
        title = task_name,
        description = description,
        labels = "task,from-neovim"
    }

    local json_data = vim.fn.json_encode(issue_data)
    local api_url = self:get_api_base_url() .. "/projects/" .. self.config.project_id .. "/issues"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            ["Content-Type"] = "application/json",
            ["PRIVATE-TOKEN"] = api_key,
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 201 then
                    callback(
                        nil,
                        "GitLab API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response and response.web_url then
                    callback(response.web_url, nil)
                else
                    callback(nil, "No issue URL in response")
                end
            end)
        end,
    })
end

--- Update GitLab issue status
function GitLabProvider:update_task_status(issue_iid, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.project_id then
        callback(nil, "GitLab project_id not configured")
        return
    end

    -- Map generic statuses to GitLab states
    local state_event
    if status == "complete" or status == "closed" then
        state_event = "close"
    elseif status == "open" or status == "reopen" then
        state_event = "reopen"
    else
        -- For other statuses, we can use labels or just treat as reopen
        state_event = "reopen"
    end

    local issue_data = {
        state_event = state_event
    }

    -- Add labels for specific statuses
    if status == "review" then
        issue_data.labels = "needs-review"
    elseif status == "in progress" then
        issue_data.labels = "in-progress"
    end

    local json_data = vim.fn.json_encode(issue_data)
    local api_url = self:get_api_base_url() .. "/projects/" .. self.config.project_id .. "/issues/" .. issue_iid

    curl.request({
        url = api_url,
        method = "put",
        headers = {
            ["Content-Type"] = "application/json",
            ["PRIVATE-TOKEN"] = api_key,
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "GitLab API request failed with status: "
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

--- Add file reference to GitLab issue
function GitLabProvider:add_file_to_task(issue_iid, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.project_id then
        callback(nil, "GitLab project_id not configured")
        return
    end

    -- Get current issue to append to existing description
    local get_url = self:get_api_base_url() .. "/projects/" .. self.config.project_id .. "/issues/" .. issue_iid

    curl.request({
        url = get_url,
        method = "get",
        headers = {
            ["PRIVATE-TOKEN"] = api_key,
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

                -- Append files to issue description
                local updated_description = (issue and issue.description) or ""
                local files_section = "\n\n**Source Files:**\n"
                files_section = files_section .. "- " .. filename .. "\n"

                -- Check if files section already exists and update/append accordingly
                if updated_description:match("%*%*Source Files:%*%*") then
                    -- Add to existing files section
                    updated_description = updated_description:gsub("(\n%*%*Source Files:%*%*\n)", "%1- " .. filename .. "\n")
                else
                    -- Append new files section
                    updated_description = updated_description .. files_section
                end

                local update_data = { description = updated_description }
                local json_data = vim.fn.json_encode(update_data)

                curl.request({
                    url = get_url,
                    method = "put",
                    headers = {
                        ["Content-Type"] = "application/json",
                        ["PRIVATE-TOKEN"] = api_key,
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

--- Extract GitLab issue IID from URL
function GitLabProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    -- GitLab URLs can be from different hosts, so we need to be more flexible
    -- Format: https://gitlab.com/owner/project/-/issues/123
    -- or: https://self-hosted-gitlab.com/owner/project/-/issues/123
    return url:match("/%-/issues/([0-9]+)")
end

--- Check if URL belongs to GitLab
function GitLabProvider:matches_url(url)
    if not url then
        return false
    end
    -- Check for GitLab URL pattern (more flexible for self-hosted)
    return url:match("/%-/issues/[0-9]+") ~= nil
end

--- Get GitLab URL pattern for extraction
function GitLabProvider:get_url_pattern()
    -- This pattern works for both gitlab.com and self-hosted GitLab instances
    return "(https://[%w%-_%.]+/[%w%-_%.]+/[%w%-_%.]+/%-/issues/[0-9]+)"
end

--- Create an issue note (comment)
function GitLabProvider:add_note_to_issue(issue_iid, note_body, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.project_id then
        callback(nil, "GitLab project_id not configured")
        return
    end

    local note_data = {
        body = note_body
    }

    local json_data = vim.fn.json_encode(note_data)
    local api_url = self:get_api_base_url() .. "/projects/" .. self.config.project_id .. "/issues/" .. issue_iid .. "/notes"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            ["Content-Type"] = "application/json",
            ["PRIVATE-TOKEN"] = api_key,
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 201 then
                    callback(
                        nil,
                        "GitLab API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                callback(response, nil)
            end)
        end,
    })
end

--- Get issue details
function GitLabProvider:get_issue(issue_iid, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.project_id then
        callback(nil, "GitLab project_id not configured")
        return
    end

    local api_url = self:get_api_base_url() .. "/projects/" .. self.config.project_id .. "/issues/" .. issue_iid

    curl.request({
        url = api_url,
        method = "get",
        headers = {
            ["PRIVATE-TOKEN"] = api_key,
        },
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "GitLab API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                callback(response, nil)
            end)
        end,
    })
end

-- Register the GitLab provider
interface.register_provider("gitlab", GitLabProvider)

return GitLabProvider
