-- v2.0.0 Breaking Changes Complete
-- All legacy commands and wrapper functions have been removed.
-- The plugin now uses a clean subcommand-based structure with configurable ClickUp statuses.

local M = {}

local config = require("comment-tasks.core.config")
local utils = require("comment-tasks.core.utils")
local detection = require("comment-tasks.core.detection")
local interface = require("comment-tasks.providers.interface")

-- Import providers (this registers them automatically)
require("comment-tasks.providers.clickup")
require("comment-tasks.providers.github")
require("comment-tasks.providers.todoist")
require("comment-tasks.providers.gitlab")

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

-- Update task status from comment
function M.update_task_status_from_comment(status, action_name, lang_override)
    local current_config = config.get_config()

    if not utils.check_language_supported(lang_override, current_config.languages) then
        return
    end

    -- Try to find a comment using generalized detection
    local comment_info = detection.get_comment_info(
        lang_override,
        current_config.languages,
        current_config.fallback_to_regex
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

    utils.notify_info((action_name or "Updating") .. " task: " .. task_identifier, provider.name)

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

-- Add file to task from comment
function M.add_file_to_task_sources(lang_override)
    local current_config = config.get_config()

    if not utils.check_language_supported(lang_override, current_config.languages) then
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
        current_config.languages,
        current_config.fallback_to_regex
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

-- Provider-specific task creation functions
function M.create_clickup_task_from_comment(lang_override)
    M.create_task_from_comment(lang_override, "clickup")
end

function M.create_github_task_from_comment(lang_override)
    M.create_task_from_comment(lang_override, "github")
end

function M.create_todoist_task_from_comment(lang_override)
    M.create_task_from_comment(lang_override, "todoist")
end

function M.create_gitlab_task_from_comment(lang_override)
    M.create_task_from_comment(lang_override, "gitlab")
end

-- Status update functions
function M.close_task_from_comment(lang_override)
    M.update_task_status_from_comment("complete", "Closing", lang_override)
end

function M.review_task_from_comment(lang_override)
    M.update_task_status_from_comment("review", "Setting to review", lang_override)
end

function M.in_progress_task_from_comment(lang_override)
    M.update_task_status_from_comment("in progress", "Setting to in progress", lang_override)
end

-- Update ClickUp task to custom status
function M.update_clickup_task_status_from_comment(status_name, lang_override)
    -- Validate that this is for ClickUp
    if not config.is_provider_enabled("clickup") then
        utils.notify_error("ClickUp provider is not enabled")
        return
    end

    -- Get the actual status name from configuration
    local actual_status = config.get_clickup_status(status_name)
    local action_name = "Setting to " .. actual_status

    M.update_task_status_from_comment(status_name, action_name, lang_override)
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
    local create_subcommand_handler = utils.create_subcommand_handler
    local create_clickup_subcommand_handler = utils.create_clickup_subcommand_handler
    local language_completion = utils.create_language_completion(current_config.languages)
    local subcommand_completion = utils.create_subcommand_completion
    local clickup_subcommand_completion = utils.create_clickup_subcommand_completion

    -- Multi-provider commands (use default provider)
    vim.api.nvim_create_user_command(
        "TaskCreate",
        create_command_handler(M.create_task_from_comment),
        {
            desc = "Create task from comment using default provider (optional language arg)",
            nargs = "?",
            complete = language_completion
        })

    vim.api.nvim_create_user_command("TaskClose", create_command_handler(M.close_task_from_comment), {
        desc = "Close task from comment (optional language arg)",
        nargs = "?",
        complete = language_completion,
    })

    vim.api.nvim_create_user_command("TaskAddFile", create_command_handler(M.add_file_to_task_sources), {
        desc = "Add current file to task from comment (optional language arg)",
        nargs = "?",
        complete = language_completion,
    })

    -- Provider-specific commands with subcommand support
    vim.api.nvim_create_user_command(
        "ClickUpTask",
        create_clickup_subcommand_handler({
            new = M.create_clickup_task_from_comment,
            close = M.close_task_from_comment,
            review = M.review_task_from_comment,
            progress = M.in_progress_task_from_comment,
            addfile = M.add_file_to_task_sources,
        }, M.update_clickup_task_status_from_comment),
        {
            desc = "ClickUp task operations: [new|close|review|progress|addfile|status <status>|<custom_status>] [language]",
            nargs = "*",
            complete = clickup_subcommand_completion({"new", "close", "review", "progress", "addfile"}, current_config.languages)
        })

    vim.api.nvim_create_user_command(
        "GitHubTask",
        create_subcommand_handler({
            new = M.create_github_task_from_comment,
            close = M.close_task_from_comment,
            addfile = M.add_file_to_task_sources,
        }),
        {
            desc = "GitHub task operations: [new|close|addfile] [language]",
            nargs = "*",
            complete = subcommand_completion({"new", "close", "addfile"}, current_config.languages)
        })

    vim.api.nvim_create_user_command(
        "TodoistTask",
        create_subcommand_handler({
            new = M.create_todoist_task_from_comment,
            close = M.close_task_from_comment,
            addfile = M.add_file_to_task_sources,
        }),
        {
            desc = "Todoist task operations: [new|close|addfile] [language]",
            nargs = "*",
            complete = subcommand_completion({"new", "close", "addfile"}, current_config.languages)
        })

    vim.api.nvim_create_user_command(
        "GitLabTask",
        create_subcommand_handler({
            new = M.create_gitlab_task_from_comment,
            close = M.close_task_from_comment,
            addfile = M.add_file_to_task_sources,
        }),
        {
            desc = "GitLab task operations: [new|close|addfile] [language]",
            nargs = "*",
            complete = subcommand_completion({"new", "close", "addfile"}, current_config.languages)
        })


    -- Optional keybinding (fixed)
    if current_config.keymap then
        vim.keymap.set("n", current_config.keymap, function()
            M.create_task_from_comment()
        end, {
            desc = "Create task from comment (default provider)",
        })
    end
end

return M
