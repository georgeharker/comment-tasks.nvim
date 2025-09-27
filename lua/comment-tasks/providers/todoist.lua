-- Todoist provider for comment-tasks plugin

local interface = require("comment-tasks.providers.interface")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local TodoistProvider = {}
TodoistProvider.__index = TodoistProvider
setmetatable(TodoistProvider, { __index = Provider })

--- Create a new Todoist provider instance
function TodoistProvider:new(config)
    local provider = Provider.new(self, config)
    return provider
end

--- Check if provider is properly configured and enabled
function TodoistProvider:is_enabled()
    if not self.config.enabled then
        return false, "Todoist provider is disabled"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Create a new Todoist task
function TodoistProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Prepare task data
    local content = task_name
    local description = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        description = description .. " in " .. filename .. "\n\nSource Files:\n- " .. filename
    end

    local task_data = {
        content = content,
        description = description
    }

    if self.config.project_id then
        task_data.project_id = self.config.project_id
    end

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.todoist.com/rest/v2/tasks"

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
                    callback(
                        nil,
                        "Todoist API request failed with status: "
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

                if response.id then
                    local task_url = "https://todoist.com/showTask?id=" .. response.id
                    callback(task_url, nil)
                else
                    callback(nil, "No task ID in response")
                end
            end)
        end,
    })
end

--- Update Todoist task status (only supports closing)
function TodoistProvider:update_task_status(task_id, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Todoist only supports close operation
    if status ~= "complete" and status ~= "closed" then
        callback(nil, "Todoist only supports closing tasks")
        return
    end

    local api_url = "https://api.todoist.com/rest/v2/tasks/" .. task_id .. "/close"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
        },
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 204 then
                    callback(
                        nil,
                        "Todoist API request failed with status: "
                            .. result.status
                            .. " - "
                            .. (result.body or "Unknown error")
                    )
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

--- Add file reference to Todoist task
function TodoistProvider:add_file_to_task(task_id, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Get current task to append to existing description
    local get_url = "https://api.todoist.com/rest/v2/tasks/" .. task_id

    curl.request({
        url = get_url,
        method = "get",
        headers = {
            Authorization = "Bearer " .. api_key,
        },
        callback = function(get_result)
            vim.schedule(function()
                if get_result.status ~= 200 then
                    callback(nil, "Failed to get current task")
                    return
                end

                local success, task = pcall(vim.fn.json_decode, get_result.body)
                if not success then
                    callback(nil, "Failed to parse task JSON")
                    return
                end

                -- Append files to task description
                local updated_description = task.description or ""
                local files_section = "\n\nSource Files:\n"
                files_section = files_section .. "- " .. filename .. "\n"

                -- Check if files section already exists and update/append accordingly
                if updated_description:match("Source Files:") then
                    -- Add to existing files section
                    updated_description = updated_description:gsub("(Source Files:\n)", "%1- " .. filename .. "\n")
                else
                    -- Append new files section
                    updated_description = updated_description .. files_section
                end

                local update_data = { description = updated_description }
                local json_data = vim.fn.json_encode(update_data)

                curl.request({
                    url = get_url,
                    method = "post",
                    headers = {
                        Authorization = "Bearer " .. api_key,
                        ["Content-Type"] = "application/json",
                    },
                    body = json_data,
                    callback = function(update_result)
                        vim.schedule(function()
                            if update_result.status ~= 200 then
                                callback(nil, "Failed to update task with files")
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

--- Extract Todoist task ID from URL
function TodoistProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    return url:match("https://todoist%.com/showTask%?id=([0-9]+)")
end

--- Check if URL belongs to Todoist
function TodoistProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("https://todoist%.com/showTask") ~= nil
end

--- Get Todoist URL pattern for extraction
function TodoistProvider:get_url_pattern()
    return "(https://todoist%.com/showTask%?id=[0-9]+)"
end

-- Register the Todoist provider
interface.register_provider("todoist", TodoistProvider)

return TodoistProvider
