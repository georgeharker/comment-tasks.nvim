
local interface = require("comment-tasks.providers.interface")
local config = require("comment-tasks.core.config")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local AsanaProvider = {}
AsanaProvider.__index = AsanaProvider
setmetatable(AsanaProvider, { __index = Provider })

--- Create a new Asana provider instance
function AsanaProvider:new(provider_config)
    local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function AsanaProvider:is_enabled()
    if not self.config.enabled then
        return false, "Asana provider is disabled"
    end

    if not self.config.project_gid then
        return false, "Asana project_gid not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Get environment variable name for API key
function AsanaProvider:get_api_key_env()
    return self.config.api_key_env or "ASANA_ACCESS_TOKEN"
end

--- Create a new Asana task
function AsanaProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.project_gid then
        callback(nil, "Asana project_gid not configured")
        return
    end

    -- Prepare task data
    local notes = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        notes = notes .. " in " .. filename .. "\n\nSource Files:\n• " .. filename
    end

    local task_data = {
        data = {
            name = task_name,
            notes = notes,
            projects = { self.config.project_gid }
        }
    }

    -- Add assignee if configured
    if self.config.assignee_gid then
        task_data.data.assignee = self.config.assignee_gid
    end

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://app.asana.com/api/1.0/tasks"

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
                if result.status ~= 201 then
                    local error_msg = "Asana API request failed with status: " .. result.status
                    if result.body then
                        local success, response = pcall(vim.fn.json_decode, result.body)
                        if success and response.errors and response.errors[1] then
                            error_msg = error_msg .. " - " .. response.errors[1].message
                        else
                            error_msg = error_msg .. " - " .. result.body
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response.data and response.data.gid then
                    local task_url = "https://app.asana.com/0/" .. self.config.project_gid .. "/" .. response.data.gid
                    callback(task_url, nil)
                else
                    callback(nil, "No task GID in response")
                end
            end)
        end,
    })
end

function AsanaProvider:update_task_status(task_gid, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Get configured status for Asana
    local asana_status = config.get_provider_status("asana", status)

    -- Handle completion status (simple completed field)
    local update_data = {}
    if asana_status == "complete" or asana_status == "Complete" or asana_status == "completed" then
        update_data.completed = true
    elseif asana_status == "incomplete" or asana_status == "open" or asana_status == "Not Started" then
        update_data.completed = false
    else
        -- Try to set custom status if project supports it
        -- First check if it's a completion state
        local completion_states = {"complete", "completed", "done", "finished", "closed"}
        local is_completion = false
        for _, completion_state in ipairs(completion_states) do
            if asana_status:lower():match(completion_state) then
                is_completion = true
                break
            end
        end

        if is_completion then
            update_data.completed = true
        else
            -- For custom statuses, try to use the status field if available
            -- Note: This requires the project to have custom status fields configured
            update_data.completed = false
            -- You could extend this to support custom fields for project-specific statuses
        end
    end

    local request_data = {
        data = update_data
    }

    local json_data = vim.fn.json_encode(update_data)
    local api_url = "https://app.asana.com/api/1.0/tasks/" .. task_gid

    curl.request({
        url = api_url,
        method = "put",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "Asana API request failed with status: " .. result.status
                    if result.body then
                        local success, response = pcall(vim.fn.json_decode, result.body)
                        if success and response.errors and response.errors[1] then
                            error_msg = error_msg .. " - " .. response.errors[1].message
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

--- Add file reference to Asana task
function AsanaProvider:add_file_to_task(task_gid, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Get current task to append to existing notes
    local get_url = "https://app.asana.com/api/1.0/tasks/" .. task_gid .. "?opt_fields=notes"

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

                -- Append files to task notes
                local updated_notes = task.data.notes or ""
                local files_section = "\n\nSource Files:\n"
                local file_entry = "• " .. filename .. "\n"

                -- Check if files section already exists and update/append accordingly
                if updated_notes:match("Source Files:") then
                    -- Add to existing files section if not already present
                    if not updated_notes:match(vim.pesc(filename)) then
                        updated_notes = updated_notes:gsub("(Source Files:\n)", "%1" .. file_entry)
                    end
                else
                    -- Append new files section
                    updated_notes = updated_notes .. files_section .. file_entry
                end

                local update_data = {
                    data = {
                        notes = updated_notes
                    }
                }
                local json_data = vim.fn.json_encode(update_data)

                curl.request({
                    url = "https://app.asana.com/api/1.0/tasks/" .. task_gid,
                    method = "put",
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

--- Extract Asana task GID from URL
function AsanaProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    -- Asana URLs: https://app.asana.com/0/PROJECT_GID/TASK_GID
    return url:match("https://app%.asana%.com/0/[0-9]+/([0-9]+)")
end

--- Check if URL belongs to Asana
function AsanaProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("https://app%.asana%.com/0/[0-9]+/[0-9]+") ~= nil
end

--- Get Asana URL pattern for extraction
function AsanaProvider:get_url_pattern()
    return "(https://app%.asana%.com/0/[0-9]+/[0-9]+)"
end

-- Register the Asana provider
interface.register_provider("asana", AsanaProvider)

return AsanaProvider