
local interface = require("comment-tasks.providers.interface")
local config = require("comment-tasks.core.config")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local LinearProvider = {}
LinearProvider.__index = LinearProvider
setmetatable(LinearProvider, { __index = Provider })

 function LinearProvider:new(provider_config)
     local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function LinearProvider:is_enabled()
    if not self.config.enabled then
        return false, "Linear provider is disabled"
    end

    if not self.config.team_id then
        return false, "Linear team_id not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Get environment variable name for API key
function LinearProvider:get_api_key_env()
    return self.config.api_key_env or "LINEAR_API_KEY"
end

--- Create a new Linear issue
function LinearProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.team_id then
        callback(nil, "Linear team_id not configured")
        return
    end

    -- Prepare GraphQL mutation for creating issue
    local description = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        description = description .. " in " .. filename .. "\n\n**Source Files:**\n- " .. filename
    end

    local mutation = [[
        mutation IssueCreate($input: IssueCreateInput!) {
            issueCreate(input: $input) {
                success
                issue {
                    id
                    identifier
                    url
                }
            }
        }
    ]]

    local variables = {
        input = {
            teamId = self.config.team_id,
            title = task_name,
            description = description,
            priority = self.config.priority or 0, -- 0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low
        }
    }

    -- Add assignee if configured
    if self.config.assignee_id then
        variables.input.assigneeId = self.config.assignee_id
    end

    -- Add project if configured
    if self.config.project_id then
        variables.input.projectId = self.config.project_id
    end

    local request_data = {
        query = mutation,
        variables = variables
    }

    local json_data = vim.fn.json_encode(request_data)
    local api_url = "https://api.linear.app/graphql"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "Linear API request failed with status: " .. result.status
                    if result.body then
                        error_msg = error_msg .. " - " .. result.body
                    end
                    callback(nil, error_msg)
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response and response.errors then
                    local error_msg = "GraphQL errors: "
                    for _, err in ipairs(response.errors) do
                        if err and err.message then
                            error_msg = error_msg .. err.message .. "; "
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                if response and response.data and response.data.issueCreate and response.data.issueCreate.issue then
                    local issue = response.data.issueCreate.issue
                    if issue and issue.url then
                        callback(issue.url, nil)
                    else
                        callback(nil, "Issue created but no URL returned")
                    end
                else
                    callback(nil, "No issue data in response")
                end
            end)
        end,
    })
end

--- Update Linear issue status
function LinearProvider:update_task_status(issue_id, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Map generic status to Linear workflow states
    local linear_state = self:map_status_to_linear(status)
    if not linear_state then
        callback(nil, "Unsupported status for Linear: " .. status)
        return
    end

    local mutation = [[
        mutation IssueUpdate($id: String!, $input: IssueUpdateInput!) {
            issueUpdate(id: $id, input: $input) {
                success
                issue {
                    id
                    state {
                        name
                    }
                }
            }
        }
    ]]

    local variables = {
        id = issue_id,
        input = {
            stateId = linear_state
        }
    }

    local request_data = {
        query = mutation,
        variables = variables
    }

    local json_data = vim.fn.json_encode(request_data)

    curl.request({
        url = "https://api.linear.app/graphql",
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(nil, "Linear API request failed with status: " .. result.status)
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response and response.errors then
                    local error_msg = "GraphQL errors: "
                    for _, err in ipairs(response.errors) do
                        if err and err.message then
                            error_msg = error_msg .. err.message .. "; "
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                if response and response.data and response.data.issueUpdate and response.data.issueUpdate.success then
                    callback(true, nil)
                else
                    callback(nil, "Failed to update issue status")
                end
            end)
        end,
    })
end

function LinearProvider:map_status_to_linear(status)
    -- Get configured status for Linear
    local linear_status = config.get_provider_status("linear", status)

    -- Check if status starts with # (indicates direct state ID)
    if linear_status:sub(1, 1) == "#" then
        -- Remove # prefix and return the state ID directly
        return linear_status:sub(2)
    else
        -- Return the status name (Linear will resolve by name)
        return linear_status
    end
end

--- Add file reference to Linear issue
function LinearProvider:add_file_to_task(issue_id, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- First, get the current issue to append to existing description
    local query = [[
        query Issue($id: String!) {
            issue(id: $id) {
                id
                description
            }
        }
    ]]

    local variables = { id = issue_id }
    local request_data = {
        query = query,
        variables = variables
    }

    curl.request({
        url = "https://api.linear.app/graphql",
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
        },
        body = vim.fn.json_encode(request_data),
        callback = function(get_result)
            vim.schedule(function()
                if get_result.status ~= 200 then
                    callback(nil, "Failed to get current issue")
                    return
                end

                local success, response = pcall(vim.fn.json_decode, get_result.body)
                if not success or not response or not response.data or not response.data.issue then
                    callback(nil, "Failed to parse issue data")
                    return
                end

                -- Update description with file reference
                local issue = response.data.issue
                local current_description = (issue and issue.description) or ""
                local updated_description = current_description

                -- Add files section if it doesn't exist
                if not updated_description:match("Source Files:") then
                    updated_description = updated_description .. "\n\n**Source Files:**\n"
                end

                -- Add file if not already present
                if not updated_description:match(vim.pesc(filename)) then
                    updated_description = updated_description .. "- " .. filename .. "\n"
                end

                -- Update the issue
                local update_mutation = [[
                    mutation IssueUpdate($id: String!, $input: IssueUpdateInput!) {
                        issueUpdate(id: $id, input: $input) {
                            success
                        }
                    }
                ]]

                local update_variables = {
                    id = issue_id,
                    input = {
                        description = updated_description
                    }
                }

                local update_request = {
                    query = update_mutation,
                    variables = update_variables
                }

                curl.request({
                    url = "https://api.linear.app/graphql",
                    method = "post",
                    headers = {
                        Authorization = "Bearer " .. api_key,
                        ["Content-Type"] = "application/json",
                    },
                    body = vim.fn.json_encode(update_request),
                    callback = function(update_result)
                        vim.schedule(function()
                            if update_result.status ~= 200 then
                                callback(nil, "Failed to update issue with file")
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

--- Extract Linear issue ID from URL
function LinearProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    -- Linear URLs: https://linear.app/team/issue/TEAM-123/issue-title
    return url:match("https://linear%.app/[^/]+/issue/([^/]+)")
end

--- Check if URL belongs to Linear
function LinearProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("https://linear%.app/[^/]+/issue/") ~= nil
end

--- Get Linear URL pattern for extraction
function LinearProvider:get_url_pattern()
    return "(https://linear%.app/[^/]+/issue/[^/]+/[^%s]*)"
end

-- Register the Linear provider
interface.register_provider("linear", LinearProvider)

return LinearProvider
