-- v2.0.0 Breaking Changes Complete
-- All legacy commands and wrapper functions have been removed.
-- The plugin now uses a clean subcommand-based structure with configurable ClickUp statuses.

local M = {}

local config = require("comment-tasks.core.config")
local utils = require("comment-tasks.core.utils")
local detection = require("comment-tasks.core.detection")
local interface = require("comment-tasks.providers.interface")
require("comment-tasks.providers.clickup")
require("comment-tasks.providers.github")
require("comment-tasks.providers.todoist")
require("comment-tasks.providers.gitlab")
require("comment-tasks.providers.asana")
require("comment-tasks.providers.linear")
require("comment-tasks.providers.jira")
require("comment-tasks.providers.notion")
require("comment-tasks.providers.monday")
require("comment-tasks.providers.trello")

-- Provider instances cache
local provider_instances = {}

-- Get or create provider instance
local function get_provider_instance(provider_name)
    if not provider_instances[provider_name] then
        local provider_config = config.get_provider_config(provider_name)
        if provider_config then
            local provider, error = interface.create_provider(provider_name, provider_config)
            if provider then
                provider_instances[provider_name] = provider
            else
                utils.notify_error("Failed to create provider '" .. provider_name .. "': " .. (error or "unknown error"))
                return nil
            end
        else
            utils.notify_error("No configuration found for provider: " .. provider_name)
            return nil
        end
    end
    return provider_instances[provider_name]
end

-- Get provider from URL
local function get_provider_from_url(url)
    for _, provider_name in ipairs(interface.get_provider_names()) do
        local provider = get_provider_instance(provider_name)
        if provider and provider:matches_url(url) then
            return provider
        end
    end
    return nil
end

-- Show task creation dialog
local function show_task_dialog_for_block(initial_text, comment_info, filename, provider_name)
    provider_name = provider_name or config.get_config().default_provider

    local provider = get_provider_instance(provider_name)
    if not provider then
        return
    end

    local is_enabled, error = provider:is_enabled()
    if not is_enabled then
        utils.notify_error("Provider " .. provider_name .. " is not enabled: " .. (error or "unknown reason"))
        return
    end

    vim.ui.input({
        prompt = "Task name: ",
        default = initial_text,
        completion = nil,
    }, function(input)
        if not input or input == "" then
            utils.notify_info("Task creation cancelled", provider_name)
            return
        end

        utils.notify_info("Creating task...", provider_name)

        provider:create_task(input, filename, function(task_url, create_error)
            if create_error then
                utils.notify_error("Error creating task: " .. create_error, provider_name)
                return
            end

            if task_url then
                local success = detection.extend_comment_with_url(comment_info, task_url)
                if success then
                    utils.notify_success("Task created: " .. task_url, provider_name)
                else
                    utils.notify_error("Error updating comment with task URL", provider_name)
                end
            end
        end)
    end)
end

-- Create task from comment (main function)
function M.create_task_from_comment(lang_override, provider_name)
    provider_name = provider_name or config.get_config().default_provider
    local current_config = config.get_config()

    if not utils.check_language_supported(lang_override, current_config.languages, provider_name) then
        return
    end

    -- Check if provider is enabled
    if not config.is_provider_enabled(provider_name) then
        utils.notify_error("Provider " .. provider_name .. " is not enabled")
        return
    end

    -- Get current buffer filename
    local filename = utils.get_current_filename()

    -- Try to find a comment using generalized detection
    local comment_info = detection.get_comment_info(
        lang_override,
        current_config.languages,
        current_config.fallback_to_regex
    )

    if not comment_info then
        local lang = lang_override or vim.bo.filetype
        utils.notify_warn("No comment found on current line for language: " .. lang, provider_name)
        return
    end

    -- Extract content from the comment
    local comment_content = detection.extract_comment_content(comment_info, current_config.comment_prefixes)

    if comment_content == "" then
        utils.notify_warn("Comment is empty", provider_name)
        return
    end

    -- Check if URL already exists in comment
    if detection.comment_has_url(comment_info) then
        utils.notify_warn("Comment already contains a task URL", provider_name)
        return
    end

    show_task_dialog_for_block(comment_content, comment_info, filename, provider_name)
end

function M.update_task_status_from_comment(status, lang_override, _)

    if not utils.check_language_supported(lang_override, config.languages) then
        return
    end

    -- Try to find a comment using generalized detection
    local comment_info = detection.get_comment_info(
        lang_override,
        config.languages,
        config.fallback_to_regex
    )

    if not comment_info then
        local lang = lang_override or vim.bo.filetype
        utils.notify_warn("No comment found on current line for language: " .. lang)
        return
    end

    -- Extract task URL from comment
    local task_url = detection.extract_task_url_from_comment(comment_info)
    if not task_url then
        utils.notify_warn("No task URL found in comment")
        return
    end

    -- Get provider for this URL
    local provider = get_provider_from_url(task_url)
    if not provider then
        utils.notify_error("No provider found for URL: " .. task_url)
        return
    end

    -- Extract task identifier
    local task_identifier = provider:extract_task_identifier(task_url)
    if not task_identifier then
        utils.notify_error("Could not extract task identifier from URL")
        return
    end

    -- Generate action name from status
    local action_name = "Setting to " .. status
    utils.notify_info(action_name .. " task: " .. task_identifier, provider.name)

    -- Update task status using appropriate provider
    provider:update_task_status(task_identifier, status, function(success, update_error)
        if update_error then
            utils.notify_error("Error updating task: " .. update_error, provider.name)
            return
        end

        if success then
            utils.notify_success("Task updated successfully (" .. status .. "): " .. task_url, provider.name)
        end
    end)
end

function M.add_file_to_task_sources(lang_override, _)

    if not utils.check_language_supported(lang_override, config.languages) then
        return
    end

    -- Get current buffer filename
    local filename = utils.get_current_filename()
    if filename == "" or filename == "[Unnamed Buffer]" then
        utils.notify_warn("No valid filename to add")
        return
    end

    -- Try to find a comment using generalized detection
    local comment_info = detection.get_comment_info(
        lang_override,
        config.languages,
        config.fallback_to_regex
    )

    if not comment_info then
        local lang = lang_override or vim.bo.filetype
        utils.notify_warn("No comment found on current line for language: " .. lang)
        return
    end

    -- Extract task URL from comment
    local task_url = detection.extract_task_url_from_comment(comment_info)
    if not task_url then
        utils.notify_warn("No task URL found in comment")
        return
    end

    -- Get provider for this URL
    local provider = get_provider_from_url(task_url)
    if not provider then
        utils.notify_error("No provider found for URL: " .. task_url)
        return
    end

    -- Extract task identifier
    local task_identifier = provider:extract_task_identifier(task_url)
    if not task_identifier then
        utils.notify_error("Could not extract task identifier from URL")
        return
    end

    utils.notify_info("Adding " .. filename .. " to task: " .. task_identifier, provider.name)

    provider:add_file_to_task(task_identifier, filename, function(success, add_error)
        if add_error then
            utils.notify_error("Error adding file to task: " .. add_error, provider.name)
            return
        end

        if success then
            utils.notify_success("Successfully added " .. filename .. " to task: " .. task_url, provider.name)
        end
    end)
end

function M.close_task_from_comment(lang_override, provider_name)
    return M.update_task_status_from_comment("completed", lang_override, provider_name)
end

function M.setup(user_config)
    -- Setup configuration
    config.setup(user_config)
    local current_config = config.get_config()

    -- Validate configuration and show warnings
    local validation = config.validate_config()

    for _, warning in ipairs(validation.warnings) do
        utils.notify_warn(warning)
    end

    for _, error in ipairs(validation.errors) do
        utils.notify_error(error)
    end

    -- if #validation.enabled_providers > 0 then
    --     utils.notify_info("Enabled providers: " .. table.concat(validation.enabled_providers, ", "))
    -- end

    -- Create user commands with proper function references
    local create_command_handler = utils.create_command_handler
    local language_completion = utils.create_language_completion(current_config.languages)
    local subcommand_completion = utils.create_subcommand_completion

    -- Multi-provider commands (use default provider)
    vim.api.nvim_create_user_command(
        "CommentTask",
        function(opts)
            local args = {}
            if opts.args and opts.args ~= "" then
                args = vim.split(vim.trim(opts.args), "%s+")
            end

            -- Default to "new" if no args
            if #args == 0 then
                M.create_task_from_comment()
                return
            end

            local first_arg = args[1]
            local second_arg = args[2]

            -- Handle standard subcommands
            if first_arg == "new" then
                M.create_task_from_comment(second_arg) -- Uses default_provider internally
            elseif first_arg == "close" then
                M.update_task_status_from_comment("complete", second_arg) -- Auto-detects provider from URL
            elseif first_arg == "addfile" then
                M.add_file_to_task_sources(second_arg) -- Auto-detects provider from URL
            else
                -- Treat as custom status for default provider
                local default_provider = config.get_config().default_provider
                -- For all providers, use the generic function
                M.update_task_status_from_comment(first_arg, second_arg, default_provider)
            end
        end,
        {
            desc = "Generic task operations using default provider: [new|close|addfile|<custom_status>] [language]",
            nargs = "*",
            complete = subcommand_completion({"new", "close", "addfile"}, current_config.languages)
        })

    vim.api.nvim_create_user_command("CommentTaskClose", create_command_handler(function(lang_override)
        M.update_task_status_from_comment("complete", lang_override)
    end), {
        desc = "Close task from comment using default provider (optional language arg)",
        nargs = "?",
        complete = language_completion,
    })

    vim.api.nvim_create_user_command("CommentTaskAddFile", create_command_handler(M.add_file_to_task_sources), {
        desc = "Add current file to task using default provider (optional language arg)",
        nargs = "?",
        complete = language_completion,
    })

    -- Provider-specific commands with subcommand support (only for enabled providers)

    -- ClickUp commands
    if config.is_provider_enabled("clickup") then
        vim.api.nvim_create_user_command(
            "ClickUpTask",
            utils.create_provider_command_handler("clickup",
                function(lang_override) M.create_task_from_comment(lang_override, "clickup") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "clickup") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "clickup") end
            ),
            {
                desc = "ClickUp task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("clickup", current_config.languages)
            })
    end

    -- GitHub commands
    if config.is_provider_enabled("github") then
        vim.api.nvim_create_user_command(
            "GitHubTask",
            utils.create_provider_command_handler("github",
                function(lang_override) M.create_task_from_comment(lang_override, "github") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "github") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "github") end
            ),
            {
                desc = "GitHub task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("github", current_config.languages)
            })
    end

    -- Todoist commands
    if config.is_provider_enabled("todoist") then
        vim.api.nvim_create_user_command(
            "TodoistTask",
            utils.create_provider_command_handler("todoist",
                function(lang_override) M.create_task_from_comment(lang_override, "todoist") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "todoist") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "todoist") end
            ),
            {
                desc = "Todoist task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("todoist", current_config.languages)
            })
    end

    -- GitLab commands
    if config.is_provider_enabled("gitlab") then
        vim.api.nvim_create_user_command(
            "GitLabTask",
            utils.create_provider_command_handler("gitlab",
                function(lang_override) M.create_task_from_comment(lang_override, "gitlab") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "gitlab") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "gitlab") end
            ),
            {
                desc = "GitLab task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("gitlab", current_config.languages)
            })
    end

    -- Asana commands
    if config.is_provider_enabled("asana") then
        vim.api.nvim_create_user_command(
            "AsanaTask",
            utils.create_provider_command_handler("asana",
                function(lang_override) M.create_task_from_comment(lang_override, "asana") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "asana") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "asana") end
            ),
            {
                desc = "Asana task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("asana", current_config.languages)
            })
    end

    -- Linear commands
    if config.is_provider_enabled("linear") then
        vim.api.nvim_create_user_command(
            "LinearTask",
            utils.create_provider_command_handler("linear",
                function(lang_override) M.create_task_from_comment(lang_override, "linear") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "linear") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "linear") end
            ),
            {
                desc = "Linear task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("linear", current_config.languages)
            })
    end

    -- Jira commands
    if config.is_provider_enabled("jira") then
        vim.api.nvim_create_user_command(
            "JiraTask",
            utils.create_provider_command_handler("jira",
                function(lang_override) M.create_task_from_comment(lang_override, "jira") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "jira") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "jira") end
            ),
            {
                desc = "Jira task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("jira", current_config.languages)
            })
    end

    -- Notion commands
    if config.is_provider_enabled("notion") then
        vim.api.nvim_create_user_command(
            "NotionTask",
            utils.create_provider_command_handler("notion",
                function(lang_override) M.create_task_from_comment(lang_override, "notion") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "notion") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "notion") end
            ),
            {
                desc = "Notion task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("notion", current_config.languages)
            })
    end

    -- Monday.com commands
    if config.is_provider_enabled("monday") then
        vim.api.nvim_create_user_command(
            "MondayTask",
            utils.create_provider_command_handler("monday",
                function(lang_override) M.create_task_from_comment(lang_override, "monday") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "monday") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "monday") end
            ),
            {
                desc = "Monday.com task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("monday", current_config.languages)
            })
    end

    -- Trello commands
    if config.is_provider_enabled("trello") then
        vim.api.nvim_create_user_command(
            "TrelloTask",
            utils.create_provider_command_handler("trello",
                function(lang_override) M.create_task_from_comment(lang_override, "trello") end,
                function(status, lang_override) M.update_task_status_from_comment(status, lang_override, "trello") end,
                function(lang_override) M.add_file_to_task_sources(lang_override, "trello") end
            ),
            {
                desc = "Trello task operations: [<status>|addfile] [language] (statuses from config)",
                nargs = "*",
                complete = utils.create_provider_completion("trello", current_config.languages)
            })
    end


end


-- TODO: Tidy up these functions
-- Provider-specific wrapper functions for easier keybinding setup
-- These functions provide cleaner API for users who want provider-specific bindings


-- Provider-specific wrapper functions for easier keybinding setup
-- These functions provide cleaner API for users who want provider-specific bindings

-- ClickUp wrapper functions
function M.create_clickup_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "clickup")
end

function M.update_clickup_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "clickup")
end

function M.add_clickup_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "clickup")
end

-- GitHub wrapper functions
function M.create_github_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "github")
end

function M.update_github_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "github")
end

function M.add_github_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "github")
end

-- Asana wrapper functions
function M.create_asana_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "asana")
end

function M.update_asana_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "asana")
end

function M.add_asana_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "asana")
end

-- Linear wrapper functions
function M.create_linear_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "linear")
end

function M.update_linear_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "linear")
end

function M.add_linear_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "linear")
end

-- Jira wrapper functions
function M.create_jira_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "jira")
end

function M.update_jira_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "jira")
end

function M.add_jira_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "jira")
end

-- Notion wrapper functions
function M.create_notion_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "notion")
end

function M.update_notion_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "notion")
end

function M.add_notion_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "notion")
end

-- Monday wrapper functions
function M.create_monday_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "monday")
end

function M.update_monday_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "monday")
end

function M.add_monday_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "monday")
end

-- Trello wrapper functions
function M.create_trello_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "trello")
end

function M.update_trello_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "trello")
end

function M.add_trello_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "trello")
end

-- GitLab wrapper functions
function M.create_gitlab_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "gitlab")
end

function M.update_gitlab_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "gitlab")
end

function M.add_gitlab_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "gitlab")
end

-- Todoist wrapper functions
function M.create_todoist_task_from_comment(lang_override)
    return M.create_task_from_comment(lang_override, "todoist")
end

function M.update_todoist_task_status_from_comment(status, lang_override)
    return M.update_task_status_from_comment(status, lang_override, "todoist")
end

function M.add_todoist_file_to_task_sources(lang_override)
    return M.add_file_to_task_sources(lang_override, "todoist")
end
return M
