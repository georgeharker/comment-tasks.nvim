-- ClickUp provider for comment-tasks plugin

local interface = require("comment-tasks.providers.interface")
local utils = require("comment-tasks.core.utils")
local config = require("comment-tasks.core.config")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local ClickUpProvider = {}
ClickUpProvider.__index = ClickUpProvider
setmetatable(ClickUpProvider, { __index = Provider })

--- Create a new ClickUp provider instance
function ClickUpProvider:new(provider_config)
    local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function ClickUpProvider:is_enabled()
    if not self.config.enabled then
        return false, "ClickUp provider is disabled"
    end

    if not self.config.list_id then
        return false, "ClickUp list_id not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Create a new ClickUp task
function ClickUpProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.list_id then
        callback(nil, "ClickUp list_id not configured")
        return
    end

    -- Prepare API request data
    local description = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        description = description .. " in " .. filename
    end

    local task_data = {
        name = task_name,
        description = description,
        status = config.get_provider_status("clickup", "new"),
    }

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.clickup.com/api/v2/list/" .. self.config.list_id .. "/task"

    -- Execute API request using plenary curl
    curl.request({
        url = api_url,
        method = "post",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "API request failed with status: "
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

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                if response.id then
                    local task_url = "https://app.clickup.com/t/" .. response.id

                    -- Also set the SourceFiles custom field if filename is provided
                    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
                        self:update_task_custom_field(
                            response.id,
                            "SourceFiles",
                            filename,
                            function(_field_success, field_error)
                                if field_error then
                                    -- Don't fail the whole operation, just warn
                                    utils.notify_warn(
                                        "Warning: Could not set SourceFiles field: " .. field_error,
                                        self.name
                                    )
                                end
                                callback(task_url, nil)
                            end
                        )
                    else
                        callback(task_url, nil)
                    end
                else
                    callback(nil, "No task ID in response")
                end
            end)
        end,
    })
end

function ClickUpProvider:update_task_status(task_id, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Get the configured status name
    local clickup_status = config.get_provider_status("clickup", status)

    -- Prepare API request data
    local task_data = {
        status = clickup_status,
    }

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id

    -- Execute API request using plenary curl
    curl.request({
        url = api_url,
        method = "put",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "API request failed with status: "
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

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

--- Add file reference to ClickUp task (uses SourceFiles custom field)
function ClickUpProvider:add_file_to_task(task_id, filename, callback)
    -- First, get the task to find existing SourceFiles
    self:get_task_with_custom_fields(task_id, function(task_data, get_error)
        if get_error then
            callback(nil, "Failed to get task details: " .. get_error)
            return
        end

        -- Get existing SourceFiles value
        local current_source_files = self:get_source_files_value(task_data)
        local files_list = {}

        -- Parse existing files
        if current_source_files and current_source_files ~= "" then
            for file in current_source_files:gmatch("[^\r\n]+") do
                table.insert(files_list, file)
            end
        end

        -- Check if filename is already in the list
        local already_exists = false
        for _, existing_file in ipairs(files_list) do
            if existing_file == filename then
                already_exists = true
                break
            end
        end

        if already_exists then
            utils.notify_info("File " .. filename .. " already exists in SourceFiles", self.name)
            callback(true, nil)
            return
        end

        -- Add the new filename
        table.insert(files_list, filename)
        local updated_source_files = table.concat(files_list, "\n")

        -- Update the custom field
        self:update_task_custom_field(
            task_id,
            "SourceFiles",
            updated_source_files,
            callback
        )
    end)
end

--- Extract ClickUp task ID from URL
function ClickUpProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    return url:match("https://app%.clickup%.com/t/([%w%-]+)")
end

--- Check if URL belongs to ClickUp
function ClickUpProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("https://app%.clickup%.com/t/") ~= nil
end

--- Get ClickUp URL pattern for extraction
function ClickUpProvider:get_url_pattern()
    return "(https://app%.clickup%.com/t/[%w%-]+)"
end

--- Get task details with custom fields
function ClickUpProvider:get_task_with_custom_fields(task_id, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id .. "?include_subtasks=false"

    curl.request({
        url = api_url,
        method = "get",
        headers = {
            accept = "application/json",
            Authorization = api_key,
        },
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(
                        nil,
                        "API request failed with status: "
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

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                callback(response, nil)
            end)
        end,
    })
end

--- Get SourceFiles value from task
function ClickUpProvider:get_source_files_value(task)
    if not task or not task.custom_fields then
        return nil
    end

    for _, field in ipairs(task.custom_fields) do
        if field.name == "SourceFiles" then
            return field.value
        end
    end

    return nil
end

--- Update custom field by ID
function ClickUpProvider:update_task_custom_field(task_id, field_name, field_value, callback)
    -- First, get the task to find the custom field ID
    self:get_task_with_custom_fields(task_id, function(task_data, get_error)
        if get_error then
            callback(nil, "Failed to get task details: " .. get_error)
            return
        end

        -- Find the custom field ID for the given field name
        local field_id = nil
        if task_data.custom_fields then
            for _, field in ipairs(task_data.custom_fields) do
                if field.name == field_name then
                    field_id = field.id
                    break
                end
            end
        end

        if not field_id then
            callback(nil, "Custom field '" .. field_name .. "' not found in task")
            return
        end

        -- Now update the custom field using the field ID
        self:set_custom_field_value(task_id, field_id, field_value, function(success, _set_error)
            if success then
                callback(true, nil)
            else
                -- If dedicated endpoint fails, try the general task update method
                utils.notify_info(
                    "Dedicated field endpoint failed, trying task update method",
                    self.name
                )
                self:update_custom_field_by_id(task_id, field_id, field_value, callback)
            end
        end)
    end)
end

--- Set custom field value using dedicated endpoint
function ClickUpProvider:set_custom_field_value(task_id, field_id, field_value, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    local field_data = {
        value = field_value,
    }

    local json_data = vim.fn.json_encode(field_data)
    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id .. "/field/" .. field_id

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "Custom field API request failed with status: "
                        .. result.status
                    if result.body then
                        local success, parsed_error = pcall(vim.fn.json_decode, result.body)
                        if success and parsed_error and parsed_error.err then
                            error_msg = error_msg .. " - " .. parsed_error.err
                        else
                            error_msg = error_msg .. " - " .. result.body
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                local success, _response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse custom field response")
                    return
                end

                callback(true, nil)
            end)
        end
    })
end

--- Update custom field using general task update
function ClickUpProvider:update_custom_field_by_id(task_id, field_id, field_value, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Update custom field using field ID
    local custom_fields = {
        [field_id] = {
            value = field_value,
        },
    }

    local task_data = {
        custom_fields = custom_fields,
    }

    local json_data = vim.fn.json_encode(task_data)
    local api_url = "https://api.clickup.com/api/v2/task/" .. task_id

    curl.request({
        url = api_url,
        method = "put",
        headers = {
            accept = "application/json",
            Authorization = api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "API request failed with status: " .. result.status
                    if result.body then
                        local success, parsed_error = pcall(vim.fn.json_decode, result.body)
                        if success and parsed_error and parsed_error.err then
                            error_msg = error_msg .. " - " .. parsed_error.err
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

                if response.err then
                    callback(nil, "ClickUp API error: " .. response.err)
                    return
                end

                callback(true, nil)
            end)
        end,
    })
end

-- Register the ClickUp provider
interface.register_provider("clickup", ClickUpProvider)

return ClickUpProvider
