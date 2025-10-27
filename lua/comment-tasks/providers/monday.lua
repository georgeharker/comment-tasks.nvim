-- Monday.com provider for comment-tasks plugin

local interface = require("comment-tasks.providers.interface")
local config = require("comment-tasks.core.config")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local MondayProvider = {}
MondayProvider.__index = MondayProvider
setmetatable(MondayProvider, { __index = Provider })

--- Create a new Monday provider instance
function MondayProvider:new(provider_config)
    local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function MondayProvider:is_enabled()
    if not self.config.enabled then
        return false, "Monday.com provider is disabled"
    end

    if not self.config.board_id then
        return false, "Monday.com board_id not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Get environment variable name for API key
function MondayProvider:get_api_key_env()
    return self.config.api_key_env or "MONDAY_API_TOKEN"
end

--- Create a new Monday.com item
function MondayProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.board_id then
        callback(nil, "Monday.com board_id not configured")
        return
    end

    -- Get configured status for new items
    local monday_status = config.get_provider_status("monday", "new")

    -- Prepare item creation mutation
    local mutation = [[
        mutation CreateItem($boardId: ID!, $itemName: String!, $groupId: String, $columnValues: JSON) {
            create_item(
                board_id: $boardId,
                item_name: $itemName,
                group_id: $groupId,
                column_values: $columnValues
            ) {
                id
                name
                url
            }
        }
    ]]

    -- Prepare column values
    local column_values = {}

    -- Add status if configured
    if self.config.status_column_id then
        column_values[self.config.status_column_id] = monday_status
    end

    -- Add file reference if provided
    local description = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        description = description .. "\n\nSource Files:\n• " .. filename
    end

    -- Add description/notes if column is configured
    if self.config.notes_column_id then
        column_values[self.config.notes_column_id] = description
    end

    local variables = {
        boardId = tonumber(self.config.board_id),
        itemName = task_name,
        columnValues = vim.fn.json_encode(column_values)
    }

    -- Add group if configured
    if self.config.group_id then
        variables.groupId = self.config.group_id
    end

    local request_data = {
        query = mutation,
        variables = variables
    }

    local json_data = vim.fn.json_encode(request_data)
    local api_url = "https://api.monday.com/v2"

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
                    local error_msg = "Monday.com API request failed with status: " .. result.status
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
                    local error_msg = "Monday.com API errors: "
                    for _, err in ipairs(response.errors) do
                        if err and err.message then
                            error_msg = error_msg .. err.message .. "; "
                        end
                    end
                    callback(nil, error_msg)
                    return
                end

                if response and response.data and response.data.create_item then
                    local item = response.data.create_item
                    local item_url = (item and item.url) or (item and item.id and ("https://view.monday.com/items/" .. item.id))
                    callback(item_url, nil)
                else
                    callback(nil, "No item data in response")
                end
            end)
        end,
    })
end

--- Update Monday.com item status
function MondayProvider:update_task_status(item_id, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Get configured status for Monday.com
    local monday_status = config.get_provider_status("monday", status)

    if not self.config.status_column_id then
        callback(nil, "Monday.com status_column_id not configured")
        return
    end

    local mutation = [[
        mutation ChangeItemColumnValue($boardId: ID!, $itemId: ID!, $columnId: String!, $value: JSON!) {
            change_column_value(
                board_id: $boardId,
                item_id: $itemId,
                column_id: $columnId,
                value: $value
            ) {
                id
            }
        }
    ]]

    local variables = {
        boardId = tonumber(self.config.board_id),
        itemId = tonumber(item_id),
        columnId = self.config.status_column_id,
        value = vim.fn.json_encode(monday_status)
    }

    local request_data = {
        query = mutation,
        variables = variables
    }

    local json_data = vim.fn.json_encode(request_data)

    curl.request({
        url = "https://api.monday.com/v2",
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(nil, "Monday.com API request failed with status: " .. result.status)
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response and response.errors then
                    local error_msg = "Monday.com API errors: "
                    for _, err in ipairs(response.errors) do
                        if err and err.message then
                            error_msg = error_msg .. err.message .. "; "
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

--- Add file reference to Monday.com item
function MondayProvider:add_file_to_task(item_id, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.notes_column_id then
        callback(nil, "Monday.com notes_column_id not configured for file references")
        return
    end

    -- First get the current notes/description
    local query = [[
        query GetItem($itemId: ID!) {
            items(ids: [$itemId]) {
                column_values {
                    column {
                        id
                    }
                    text
                }
            }
        }
    ]]

    local variables = {
        itemId = tonumber(item_id)
    }

    local request_data = {
        query = query,
        variables = variables
    }

    curl.request({
        url = "https://api.monday.com/v2",
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
        },
        body = vim.fn.json_encode(request_data),
        callback = function(get_result)
            vim.schedule(function()
                if get_result.status ~= 200 then
                    callback(nil, "Failed to get current item")
                    return
                end

                local success, response = pcall(vim.fn.json_decode, get_result.body)
                if not success or not response or not response.data or not response.data.items or #response.data.items == 0 then
                    callback(nil, "Failed to parse item data")
                    return
                end

                -- Find current notes value
                local current_notes = ""
                for _, column_value in ipairs(response.data.items[1].column_values) do
                    if column_value and column_value.column and column_value.column.id == self.config.notes_column_id then
                        current_notes = column_value.text or ""
                        break
                    end
                end

                -- Append file reference
                local updated_notes = current_notes
                if not updated_notes:match("Source Files:") then
                    updated_notes = updated_notes .. "\n\nSource Files:\n"
                end

                -- Add file if not already present
                if not updated_notes:match(vim.pesc(filename)) then
                    updated_notes = updated_notes .. "• " .. filename .. "\n"
                end

                -- Update the item
                local update_mutation = [[
                    mutation ChangeItemColumnValue($boardId: ID!, $itemId: ID!, $columnId: String!, $value: JSON!) {
                        change_column_value(
                            board_id: $boardId,
                            item_id: $itemId,
                            column_id: $columnId,
                            value: $value
                        ) {
                            id
                        }
                    }
                ]]

                local update_variables = {
                    boardId = tonumber(self.config.board_id),
                    itemId = tonumber(item_id),
                    columnId = self.config.notes_column_id,
                    value = vim.fn.json_encode(updated_notes)
                }

                local update_request = {
                    query = update_mutation,
                    variables = update_variables
                }

                curl.request({
                    url = "https://api.monday.com/v2",
                    method = "post",
                    headers = {
                        Authorization = "Bearer " .. api_key,
                        ["Content-Type"] = "application/json",
                    },
                    body = vim.fn.json_encode(update_request),
                    callback = function(update_result)
                        vim.schedule(function()
                            if update_result.status ~= 200 then
                                callback(nil, "Failed to update item with file")
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

--- Extract Monday.com item ID from URL
function MondayProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    -- Monday.com URLs: https://view.monday.com/items/123456 or various other formats
    return url:match("/items/(%d+)") or url:match("item_id=(%d+)")
end

--- Check if URL belongs to Monday.com
function MondayProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("monday%.com") ~= nil and (url:match("/items/") ~= nil or url:match("item_id=") ~= nil)
end

--- Get Monday.com URL pattern for extraction
function MondayProvider:get_url_pattern()
    return "(https://[^%s]*monday%.com[^%s]*)"
end

-- Register the Monday.com provider
interface.register_provider("monday", MondayProvider)

return MondayProvider
