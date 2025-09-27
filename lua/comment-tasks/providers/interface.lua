-- Generic provider interface for task management systems
-- All providers should implement this interface

local M = {}

---@class Provider
---@field config ProviderConfig
---@field name string

---@class ProviderConfig
---@field enabled? boolean
---@field name? string
---@field api_key_env? string

---@class TaskCreateOptions
---@field title? string
---@field description? string
---@field priority? number
---@field due_date? string

---@class TaskStatus
---@field id string|number
---@field status string
---@field title? string
---@field description? string

---@alias TaskCallback fun(success: boolean, result: any, error: string?)
---@alias StatusUpdateCallback fun(success: boolean, error: string?)
---@alias FileAttachCallback fun(success: boolean, error: string?)
---@alias TaskIdentifier string|number

---@class Provider
local Provider = {}
Provider.__index = Provider

 --- Create a new provider instance
 ---@param config ProviderConfig Provider configuration
 ---@return Provider provider instance
 ---@overload fun(config: ProviderConfig): Provider
function Provider:new(config)
    local provider = setmetatable({}, self)
    provider.config = config or {}
    provider.name = config.name or "unknown"
    return provider
end

--- Check if provider is properly configured and enabled
---@return boolean is_enabled
---@return string|nil error_message
function Provider:is_enabled()
    return self.config.enabled or false, nil
end

--- Create a new task in the provider system
---@param _task_name string Name of the task to create
---@param _filename string? Optional filename to associate with the task
---@param _callback TaskCallback Function called when task creation is complete
function Provider:create_task(_task_name, _filename, _callback)
    error("create_task must be implemented by provider")
end

--- Update the status of an existing task
---@param _task_identifier TaskIdentifier Unique identifier for the task
---@param _status string New status to set for the task
---@param _callback StatusUpdateCallback Function called when status update is complete
function Provider:update_task_status(_task_identifier, _status, _callback)
    error("update_task_status must be implemented by provider")
end

--- Add a file attachment to an existing task
---@param _task_identifier TaskIdentifier Unique identifier for the task
---@param _filename string Path to the file to attach
---@param _callback FileAttachCallback Function called when file attachment is complete
function Provider:add_file_to_task(_task_identifier, _filename, _callback)
    error("add_file_to_task must be implemented by provider")
end

--- Extract task identifier from a URL
---@param _url string URL containing task information
---@return TaskIdentifier? identifier Task identifier if successfully extracted
function Provider:extract_task_identifier(_url)
    error("extract_task_identifier must be implemented by provider")
end

--- Check if this provider can handle the given URL
---@param _url string URL to check
---@return boolean matches True if this provider can handle the URL
function Provider:matches_url(_url)
    error("matches_url must be implemented by provider")
end

--- Get provider-specific URL pattern for extraction
---@return string url_pattern Lua pattern for URL matching
function Provider:get_url_pattern()
    error("get_url_pattern must be implemented by provider")
end

--- Get environment variable name for API key
---@return string env_var_name
function Provider:get_api_key_env()
    return self.config.api_key_env or (self.name:upper() .. "_API_KEY")
end

--- Get API key from environment
---@return string|nil api_key
---@return string|nil error_message
function Provider:get_api_key()
    local env_var = self:get_api_key_env()
    local api_key = vim.fn.getenv(env_var)

    if not api_key or api_key == vim.NIL then
        return nil, "API key not found in environment variable: " .. env_var
    end

    return api_key, nil
end

--- Validate provider configuration
---@return boolean is_valid
---@return string|nil error_message
function Provider:validate_config()
    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

 ---@type table<string, Provider>
M.providers = {}

---@param name string Provider name
---@param provider_class table Provider class
function M.register_provider(name, provider_class)
    M.providers[name] = provider_class
end

--- Get registered provider
---@param name string Provider name
---@return table|nil provider_class
function M.get_provider_class(name)
    return M.providers[name]
end

--- Create provider instance
---@param name string Provider name
---@param config table Provider configuration
---@return table|nil provider_instance
---@return string|nil error_message
function M.create_provider(name, config)
    local provider_class = M.get_provider_class(name)
    if not provider_class then
        return nil, "Unknown provider: " .. name
    end

    local provider = provider_class:new(vim.tbl_extend("force", config, { name = name }))
    local is_valid, error = provider:validate_config()

    if not is_valid then
        return nil, error
    end

    return provider, nil
end

 ---@return string[] provider_names
function M.get_provider_names()
    local names = {}
    for name, _ in pairs(M.providers) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

--- The Provider base class
M.Provider = Provider

return M
