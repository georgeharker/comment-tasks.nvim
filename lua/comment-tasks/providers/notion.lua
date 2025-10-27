-- Notion provider for comment-tasks plugin

local interface = require("comment-tasks.providers.interface")
local config = require("comment-tasks.core.config")
local curl = require("plenary.curl")

---@type Provider
local Provider = interface.Provider

local NotionProvider = {}
NotionProvider.__index = NotionProvider
setmetatable(NotionProvider, { __index = Provider })

--- Create a new Notion provider instance
function NotionProvider:new(provider_config)
    local provider = Provider.new(self, provider_config)
    return provider
end

--- Check if provider is properly configured and enabled
function NotionProvider:is_enabled()
    if not self.config.enabled then
        return false, "Notion provider is disabled"
    end

    if not self.config.database_id then
        return false, "Notion database_id not configured"
    end

    local api_key, error = self:get_api_key()
    if not api_key then
        return false, error
    end

    return true, nil
end

--- Get environment variable name for API key
function NotionProvider:get_api_key_env()
    return self.config.api_key_env or "NOTION_API_KEY"
end

--- Create a new Notion page in the configured database
function NotionProvider:create_task(task_name, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    if not self.config.database_id then
        callback(nil, "Notion database_id not configured")
        return
    end

    -- Get configured status for new tasks
    local notion_status = config.get_provider_status("notion", "new")

    -- Prepare page content
    local children = {
        {
            object = "block",
            type = "paragraph",
            paragraph = {
                rich_text = {
                    {
                        type = "text",
                        text = {
                            content = "Created from Neovim comment"
                        }
                    }
                }
            }
        }
    }

    -- Add file reference if provided
    if filename and filename ~= "" and filename ~= "[Unnamed Buffer]" then
        table.insert(children, {
            object = "block",
            type = "heading_3",
            heading_3 = {
                rich_text = {
                    {
                        type = "text",
                        text = {
                            content = "Source Files"
                        }
                    }
                }
            }
        })
        table.insert(children, {
            object = "block",
            type = "bulleted_list_item",
            bulleted_list_item = {
                rich_text = {
                    {
                        type = "text",
                        text = {
                            content = filename
                        }
                    }
                }
            }
        })
    end

    -- Prepare page data
    local page_data = {
        parent = {
            database_id = self.config.database_id
        },
        properties = {
            Name = {
                title = {
                    {
                        text = {
                            content = task_name
                        }
                    }
                }
            },
            Status = {
                select = {
                    name = notion_status
                }
            }
        },
        children = children
    }

    -- Add assignee if configured (assumes Person property exists)
    if self.config.assignee_id then
        page_data.properties.Assignee = {
            people = {
                {
                    id = self.config.assignee_id
                }
            }
        }
    end

    local json_data = vim.fn.json_encode(page_data)
    local api_url = "https://api.notion.com/v1/pages"

    curl.request({
        url = api_url,
        method = "post",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            ["Notion-Version"] = "2022-06-28",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "Notion API request failed with status: " .. result.status
                    if result.body then
                        local success, response = pcall(vim.fn.json_decode, result.body)
                        if success and response and response.message then
                            error_msg = error_msg .. " - " .. response.message
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

                if response and response.id then
                    local page_url = (response and response.url) or ("https://notion.so/" .. response.id:gsub("-", ""))
                    callback(page_url, nil)
                else
                    callback(nil, "No page ID in response")
                end
            end)
        end,
    })
end

--- Update Notion page status
function NotionProvider:update_task_status(page_id, status, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Get configured status for Notion
    local notion_status = config.get_provider_status("notion", status)

    -- Clean page ID (remove hyphens if present)
    page_id = page_id:gsub("-", "")

    local update_data = {
        properties = {
            Status = {
                select = {
                    name = notion_status
                }
            }
        }
    }

    local json_data = vim.fn.json_encode(update_data)
    local api_url = "https://api.notion.com/v1/pages/" .. page_id

    curl.request({
        url = api_url,
        method = "patch",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            ["Notion-Version"] = "2022-06-28",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "Notion API request failed with status: " .. result.status
                    if result.body then
                        local success, response = pcall(vim.fn.json_decode, result.body)
                        if success and response and response.message then
                            error_msg = error_msg .. " - " .. response.message
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

--- Add file reference to Notion page
function NotionProvider:add_file_to_task(page_id, filename, callback)
    local api_key, error = self:get_api_key()
    if not api_key then
        callback(nil, error)
        return
    end

    -- Clean page ID (remove hyphens if present)
    page_id = page_id:gsub("-", "")

    -- Add a new bullet point with the file reference
    local new_block = {
        object = "block",
        type = "bulleted_list_item",
        bulleted_list_item = {
            rich_text = {
                {
                    type = "text",
                    text = {
                        content = filename
                    }
                }
            }
        }
    }

    local append_data = {
        children = { new_block }
    }

    local json_data = vim.fn.json_encode(append_data)
    local api_url = "https://api.notion.com/v1/blocks/" .. page_id .. "/children"

    curl.request({
        url = api_url,
        method = "patch",
        headers = {
            Authorization = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            ["Notion-Version"] = "2022-06-28",
        },
        body = json_data,
        callback = function(result)
            vim.schedule(function()
                if result.status ~= 200 then
                    local error_msg = "Failed to add file to Notion page: " .. result.status
                    if result.body then
                        local success, response = pcall(vim.fn.json_decode, result.body)
                        if success and response and response.message then
                            error_msg = error_msg .. " - " .. response.message
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

--- Extract Notion page ID from URL
function NotionProvider:extract_task_identifier(url)
    if not url then
        return nil
    end
    -- Notion URLs: https://notion.so/PAGE_ID or https://www.notion.so/workspace/PAGE_ID
    local page_id = url:match("notion%.so/[^/]*/([a-f0-9]+)") or url:match("notion%.so/([a-f0-9]+)")
    return page_id
end

--- Check if URL belongs to Notion
function NotionProvider:matches_url(url)
    if not url then
        return false
    end
    return url:match("notion%.so/") ~= nil
end

--- Get Notion URL pattern for extraction
function NotionProvider:get_url_pattern()
    return "(https://[^%s]*notion%.so/[^%s]*[a-f0-9]+[^%s]*)"
end

-- Register the Notion provider
interface.register_provider("notion", NotionProvider)

return NotionProvider
