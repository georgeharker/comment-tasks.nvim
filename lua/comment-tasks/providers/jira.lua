-- Jira provider for comment-tasks plugin

local interface = require("comment-tasks.providers.interface")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local JiraProvider = {}
JiraProvider.__index = JiraProvider
setmetatable(JiraProvider, { __index = Provider })

--- Create a new Jira provider instance
function JiraProvider:new(provider_config)
    local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function JiraProvider:is_enabled()
    if not self.config.enabled then
        return false, "Jira provider is disabled"
    end

    if not self.config.server_url then
        return false, "Jira server_url not configured"
    end

    if not self.config.project_key then
        return false, "Jira project_key not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Get environment variable name for API key
function JiraProvider:get_api_key_env()
    return self.config.api_key_env or "JIRA_API_TOKEN"
end

--- Get base URL for Jira API
function JiraProvider:get_base_url()
    local server_url = self.config.server_url
    -- Remove trailing slash if present
    server_url = server_url:gsub("/$", "")
    return server_url .. "/rest/api/3"
end

--- Create a new Jira issue
function JiraProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.project_key then
        callback(nil, "Jira project_key not configured")
        return
    end

    -- Prepare issue description
    local description = {
        type = "doc",
        version = 1,
        content = {
            {
                type = "paragraph",
                content = {
                    {
                        type = "text",
                        text = "Created from Neovim comment"
                    }
                }
            }
        }
    }

    -- Add file reference if provided
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        table.insert(description.content, {
            type = "paragraph",
            content = {
                {
                    type = "text",
                    text = "Source file: " .. filename,
                    marks = {
                        {
                            type = "strong"
                        }
                    }
                }
            }
        })
        table.insert(description.content, {
            type = "bulletList",
            content = {
                {
                    type = "listItem",
                    content = {
                        {
                            type = "paragraph",
                            content = {
                                {
                                    type = "text",
                                    text = filename
                                }
                            }
                        }
                    }
                }
            }
        })
    end

    -- Prepare issue data
    local issue_data = {
        fields = {
            project = {
                key = self.config.project_key
            },
            summary = task_name,
            description = description,
            issuetype = {
                name = self.config.issue_type or "Task"
            }
        }
    }

    -- Add assignee if configured
    if self.config.assignee_id then
        issue_data.fields.assignee = {
            id = self.config.assignee_id
        }
    end

    local json_data = vim.fn.json_encode(issue_data)
    local api_url = self:get_base_url() .. "/issue"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            Accept = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 201 then
                    local error_msg = "Jira API request failed with status: " .. result.status
                    if result.body then
                        local success, response = pcall(vim.fn.json_decode, result.body)
                        if success and response and response.errors then
                            for field, messages in pairs(response.errors) do
                                if messages then
                                    error_msg = error_msg .. "\n" .. field .. ": " .. table.concat(messages, ", ")
                                end
                            end
                        elseif success and response and response.errorMessages then
                            error_msg = error_msg .. "\n" .. table.concat(response.errorMessages, "\n")
                        else
                            error_msg = error_msg .. " - " .. result.body
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success or not response then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response and response.key then
                    local issue_url = self.config.server_url .. "/browse/" .. response.key
                    callback(issue_url, nil)
                else
                    callback(nil, "No issue key in response")
                end
            end)
        end,
    })
end

--- Update Jira issue status
function JiraProvider:update_task_status(issue_key, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Map status to Jira status name
    local jira_status = self:map_status_to_jira(status)

    -- Get available transitions for the issue
    local transitions_url = self:get_base_url() .. "/issue/" .. issue_key .. "/transitions"

    curl.request({
        url = transitions_url,
        method = "get",
        headers = {
            Authorization = "Bearer " .. api_key,
            Accept = "application/json",
        },
        callback = function(transitions_result)
            vim.schedule(function()
                if transitions_result.status ~= 200 then
                    callback(nil, "Failed to get issue transitions")
                    return
                end

                local success, transitions_data = pcall(vim.fn.json_decode, transitions_result.body)
                if not success then
                    callback(nil, "Failed to parse transitions response")
                    return
                end

                -- Find the transition that matches our desired status
                local transition_id = nil
                if transitions_data and transitions_data.transitions then
                    for _, transition in ipairs(transitions_data.transitions) do
                        if transition and transition.to and transition.to.name then
                            if transition.to.name:lower() == jira_status:lower() then
                                transition_id = transition.id
                                break
                            end
                        end
                    end
                end

                if not transition_id then
                    callback(nil, "No valid transition found for status: " .. jira_status)
                    return
                end

                -- Execute the transition
                local transition_data = {
                    transition = {
                        id = transition_id
                    }
                }

                curl.request({
                    url = transitions_url,
                    method = "post",
                    headers = {
                        Authorization = "Bearer " .. api_key,
                        ["Content-Type"] = "application/json",
                        Accept = "application/json",
                    },
                    body = vim.fn.json_encode(transition_data),
                    callback = function(transition_result)
                        vim.schedule(function()
                            if transition_result.status ~= 204 then
                                callback(nil, "Failed to transition issue: " .. (transition_result.body or "Unknown error"))
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

--- Add file reference to Jira issue
function JiraProvider:add_file_to_task(issue_key, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Get current issue to append to existing description
    local get_url = self:get_base_url() .. "/issue/" .. issue_key .. "?fields=description"

    curl.request({
        url = get_url,
        method = "get",
        headers = {
            Authorization = "Bearer " .. api_key,
            Accept = "application/json",
        },
        callback = function(get_result)
            vim.schedule(function()
                if get_result.status ~= 200 then
                    callback(nil, "Failed to get current issue")
                    return
                end

                local success, issue_data = pcall(vim.fn.json_decode, get_result.body)
                if not success or not issue_data then
                    callback(nil, "Failed to parse issue data")
                    return
                end

                -- Update description with file reference
                local current_description = (issue_data and issue_data.fields and issue_data.fields.description) or {
                    type = "doc",
                    version = 1,
                    content = {}
                }

                -- Check if we already have a source files section
                local has_source_files = false
                for _, content_block in ipairs(current_description.content) do
                    if content_block.type == "paragraph" and content_block.content then
                        for _, text_node in ipairs(content_block.content) do
                            if text_node.text and text_node.text:match("Source file") then
                                has_source_files = true
                                break
                            end
                        end
                    end
                    if has_source_files then break end
                end

                -- Add source files section if it doesn't exist
                if not has_source_files then
                    table.insert(current_description.content, {
                        type = "paragraph",
                        content = {
                            {
                                type = "text",
                                text = "Source Files:",
                                marks = {
                                    {
                                        type = "strong"
                                    }
                                }
                            }
                        }
                    })
                end

                -- Add the new file as a bullet point
                table.insert(current_description.content, {
                    type = "bulletList",
                    content = {
                        {
                            type = "listItem",
                            content = {
                                {
                                    type = "paragraph",
                                    content = {
                                        {
                                            type = "text",
                                            text = filename
                                        }
                                    }
                                }
                            }
                        }
                    }
                })

                -- Update the issue
                local update_data = {
                    fields = {
                        description = current_description
                    }
                }

                curl.request({
                    url = self:get_base_url() .. "/issue/" .. issue_key,
                    method = "put",
                    headers = {
                        Authorization = "Bearer " .. api_key,
                        ["Content-Type"] = "application/json",
                        Accept = "application/json",
                    },
                    body = vim.fn.json_encode(update_data),
                    callback = function(update_result)
                        vim.schedule(function()
                            if update_result.status ~= 204 then
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

--- Extract Jira issue key from URL
function JiraProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    -- Jira URLs: https://domain.atlassian.net/browse/PROJECT-123
    return url:match("/browse/([A-Z]+-[0-9]+)")
end

--- Check if URL belongs to Jira
function JiraProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("/browse/[A-Z]+-[0-9]+") ~= nil
end

--- Get Jira URL pattern for extraction
function JiraProvider:get_url_pattern()
    return "(https://[^/]+%.atlassian%.net/browse/[A-Z]+-[0-9]+)"
end

-- Register the Jira provider
interface.register_provider("jira", JiraProvider)

return JiraProvider