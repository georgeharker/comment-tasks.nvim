-- Trello provider for comment-tasks plugin

local curl = require("plenary.curl")
local interface = require("comment-tasks.providers.interface")

---@type Provider
local Provider = interface.Provider

local TrelloProvider = {}
TrelloProvider.__index = TrelloProvider
setmetatable(TrelloProvider, { __index = Provider })

--- Create a new Trello provider instance
function TrelloProvider:new(provider_config)
    local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function TrelloProvider:is_enabled()
    if not self.config.enabled then
        return false, "Trello provider is disabled"
    end

    if not self.config.board_id then
        return false, "Trello board_id not configured"
    end

    if not self.config.list_mapping then
        return false, "Trello list_mapping not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    local api_token, token_error = self:get_api_token()
    if not api_token then
        return false, token_error
    end

    return true, nil
end

--- Get environment variable name for API key
function TrelloProvider:get_api_key_env()
    return self.config.api_key_env or "TRELLO_API_KEY"
end

--- Get API token from environment
function TrelloProvider:get_api_token()
    local env_var = self.config.api_token_env or "TRELLO_API_TOKEN"
    local api_token = vim.fn.getenv(env_var)

    if not api_token or api_token == vim.NIL then
        return nil, "API token not found in environment variable: " .. env_var
    end

    return api_token, nil
end

--- Get list ID for a given status
function TrelloProvider:get_list_id_for_status(status)
    if not self.config.statuses then
        return nil, "No status configuration found"
    end

    local statuses = self.config.statuses
    local list_name = statuses[status]
    if not list_name then
        return nil, "Status not configured: " .. status
    end

    return list_name, nil
end

--- Create a new Trello card
function TrelloProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    local api_token, token_error = self:get_api_token()
    if not api_token then
        callback(nil, token_error)
        return
    end

    -- Get list for new tasks
    local list_id, list_error = self:get_list_id_for_status("new")
    if not list_id then
        callback(nil, list_error or "Could not determine list for new tasks")
        return
    end

    -- Prepare card description
    local description = "Created from Neovim comment"
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        description = description .. "\n\n**Source Files:**\n- " .. filename
    end

    -- If list_id is a name, we need to get the actual list ID first
    if not list_id:match("^[a-f0-9]+$") or #list_id ~= 24 then
        -- Get board lists to find the list ID
        local lists_url = "https://api.trello.com/1/boards/" .. self.config.board_id .. "/lists"
        local lists_params = "key=" .. api_key .. "&token=" .. api_token

        curl.request({
            url = lists_url .. "?" .. lists_params,
            method = "get",
            callback = function(lists_result)
                vim.schedule(function()
                    if lists_result.status ~= 200 then
                        callback(nil, "Failed to get board lists")
                        return
                    end

                    local success, lists_data = pcall(vim.fn.json_decode, lists_result.body)
                    if not success then
                        callback(nil, "Failed to parse lists response")
                        return
                    end

                    -- Find the list ID by name
                    local found_list_id = nil
                    if lists_data and type(lists_data) == "table" then
                        for _, list_item in ipairs(lists_data) do
                            if list_item and type(list_item) == "table" and list_item.name == list_id then
                                found_list_id = list_item.id
                                break
                            end
                        end
                    else
                        callback(nil, "No lists data returned")
                        return
                    end

                    if not found_list_id then
                        callback(nil, "List not found: " .. list_id)
                        return
                    end

                    -- Now create the card with the found list ID
                    self:create_card_in_list(
                        found_list_id,
                        task_name,
                        description,
                        api_key,
                        api_token,
                        callback
                    )
                end)
            end,
        })
    else
        -- list_id is already a valid ID
        self:create_card_in_list(list_id, task_name, description, api_key, api_token, callback)
    end
end

--- Create card in specific list (helper function)
function TrelloProvider:create_card_in_list(
    list_id,
    task_name,
    description,
    api_key,
    api_token,
    callback
)
    local card_params = {
        name = task_name,
        desc = description,
        idList = list_id,
        key = api_key,
        token = api_token,
    }

    -- Convert params to URL-encoded string
    local param_strings = {}
    for key, value in pairs(card_params) do
        table.insert(param_strings, key .. "=" .. vim.fn.shellescape(tostring(value)))
    end
    local params_string = table.concat(param_strings, "&")

    curl.request({
        url = "https://api.trello.com/1/cards",
        method = "post",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        },
        body = params_string,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "Trello API request failed with status: " .. result.status
                    if result.body then
                        error_msg = error_msg .. " - " .. result.body
                    end
                    callback(nil, error_msg)
                    return
                end

                local success, response = pcall(vim.fn.json_decode, result.body)
                if not success or not response then
                    callback(nil, "Failed to parse JSON response")
                    return
                end

                if response and response.id then
                    local card_url = (response.shortUrl)
                        or (response.url)
                        or (response.shortLink and ("https://trello.com/c/" .. response.shortLink))
                    callback(card_url, nil)
                else
                    callback(nil, "No card ID in response")
                end
            end)
        end,
    })
end

--- Update Trello card status (move to different list)
function TrelloProvider:update_task_status(card_id, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    local api_token, token_error = self:get_api_token()
    if not api_token then
        callback(nil, token_error)
        return
    end

    -- Get target list for the status
    local list_id, list_error = self:get_list_id_for_status(status)
    if not list_id then
        callback(nil, list_error or ("Could not determine target list for status: " .. status))
        return
    end

    -- If list_id is a name, resolve it to an ID first
    if not list_id:match("^[a-f0-9]+$") or #list_id ~= 24 then
        local lists_url = "https://api.trello.com/1/boards/" .. self.config.board_id .. "/lists"
        local lists_params = "key=" .. api_key .. "&token=" .. api_token

        curl.request({
            url = lists_url .. "?" .. lists_params,
            method = "get",
            callback = function(lists_result)
                vim.schedule(function()
                    if lists_result.status ~= 200 then
                        callback(nil, "Failed to get board lists")
                        return
                    end

                    local success, lists_data = pcall(vim.fn.json_decode, lists_result.body)
                    if not success then
                        callback(nil, "Failed to parse lists response")
                        return
                    end

                    -- Find the list ID by name
                    local found_list_id = nil
                    if lists_data and type(lists_data) == "table" then
                        for _, list_item in ipairs(lists_data) do
                            if list_item and type(list_item) == "table" and list_item.name == list_id then
                                found_list_id = list_item.id
                                break
                            end
                        end
                    end

                    if not found_list_id then
                        callback(nil, "Target list not found: " .. list_id)
                        return
                    end

                    -- Now move the card
                    self:move_card_to_list(card_id, found_list_id, api_key, api_token, callback)
                end)
            end,
        })
    else
        -- list_id is already a valid ID
        self:move_card_to_list(card_id, list_id, api_key, api_token, callback)
    end
end

--- Move card to different list (helper function)
function TrelloProvider:move_card_to_list(card_id, list_id, api_key, api_token, callback)
    local update_params = {
        idList = list_id,
        key = api_key,
        token = api_token,
    }

    local param_strings = {}
    for key, value in pairs(update_params) do
        table.insert(param_strings, key .. "=" .. tostring(value))
    end
    local params_string = table.concat(param_strings, "&")

    curl.request({
        url = "https://api.trello.com/1/cards/" .. card_id,
        method = "put",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        },
        body = params_string,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    callback(nil, "Failed to move card: " .. (result.body or "Unknown error"))
                    return
                end
                callback(true, nil)
            end)
        end,
    })
end

--- Add file reference to Trello card
function TrelloProvider:add_file_to_task(card_id, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    local api_token, token_error = self:get_api_token()
    if not api_token then
        callback(nil, token_error)
        return
    end

    -- Get current card to append to existing description
    local get_params = "key=" .. api_key .. "&token=" .. api_token .. "&fields=desc"

    curl.request({
        url = "https://api.trello.com/1/cards/" .. card_id .. "?" .. get_params,
        method = "get",
        callback = function(get_result)
            vim.schedule(function()
                if get_result.status ~= 200 then
                    callback(nil, "Failed to get current card")
                    return
                end

                local success, card_data = pcall(vim.fn.json_decode, get_result.body)
                if not success then
                    callback(nil, "Failed to parse card data")
                    return
                end

                -- Update description with file reference
                local current_description = (card_data and card_data.desc) or ""
                local updated_description = current_description

                -- Add source files section if it doesn't exist
                if not updated_description:match("Source Files:") then
                    updated_description = updated_description .. "\n\n**Source Files:**\n"
                end

                -- Add file if not already present
                if not updated_description:match(vim.pesc(filename)) then
                    updated_description = updated_description .. "- " .. filename .. "\n"
                end

                -- Update the card
                local update_params = {
                    desc = updated_description,
                    key = api_key,
                    token = api_token,
                }

                local param_strings = {}
                for key, value in pairs(update_params) do
                    table.insert(param_strings, key .. "=" .. vim.fn.shellescape(tostring(value)))
                end
                local params_string = table.concat(param_strings, "&")

                curl.request({
                    url = "https://api.trello.com/1/cards/" .. card_id,
                    method = "put",
                    headers = {
                        ["Content-Type"] = "application/x-www-form-urlencoded",
                    },
                    body = params_string,
                    callback = function(update_result)
                        vim.schedule(function()
                            if update_result.status ~= 200 then
                                callback(nil, "Failed to update card with file")
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

--- Extract Trello card ID from URL
function TrelloProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    -- Trello URLs: https://trello.com/c/CARD_ID or short URLs
    return url:match("/c/([a-zA-Z0-9]+)")
end

--- Check if URL belongs to Trello
function TrelloProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("trello%.com/c/") ~= nil
end

--- Get Trello URL pattern for extraction
function TrelloProvider:get_url_pattern()
    return "(https://trello%.com/c/[a-zA-Z0-9]+[^%s]*)"
end

-- Register the Trello provider
interface.register_provider("trello", TrelloProvider)

return TrelloProvider
