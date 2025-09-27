-- Configuration tests for comment-tasks plugin using plenary

-- Import plenary test functions
local plenary = require("plenary.busted")
local describe = plenary.describe
local it = plenary.it
local before_each = plenary.before_each
local assert = require("luassert")

describe("comment-tasks configuration", function()
    local config

    before_each(function()
        -- Clear any cached modules
        for module_name, _ in pairs(package.loaded) do
            if module_name:match("^comment%-tasks") then
                package.loaded[module_name] = nil
            end
        end
        config = require("comment-tasks.core.config")
    end)

    describe("default configuration", function()
        it("should have valid default configuration", function()
            local default_config = config.default_config
            assert.is_not_nil(default_config)
            assert.equals("clickup", default_config.default_provider)
            assert.is_not_nil(default_config.providers)
        end)

        it("should have all provider configurations", function()
            local default_config = config.default_config
            assert.is_not_nil(default_config.providers.clickup)
            assert.is_not_nil(default_config.providers.github)
            assert.is_not_nil(default_config.providers.todoist)
            assert.is_not_nil(default_config.providers.gitlab)
        end)
    end)

    describe("configuration setup", function()
        it("should update configuration correctly", function()
            config.setup({
                default_provider = "gitlab",
                providers = {
                    gitlab = {
                        enabled = true,
                        project_id = "12345"
                    }
                }
            })

            local current_config = config.get_config()
            assert.equals("gitlab", current_config.default_provider)
            assert.equals("12345", current_config.providers.gitlab.project_id)
        end)

        it("should handle legacy configuration", function()
            config.setup({
                list_id = "legacy_list_id",
                api_key_env = "LEGACY_API_KEY"
            })

            local legacy_config = config.get_config()
            assert.equals("legacy_list_id", legacy_config.providers.clickup.list_id)
            assert.equals("LEGACY_API_KEY", legacy_config.providers.clickup.api_key_env)
        end)
    end)

    describe("provider status", function()
        before_each(function()
            config.setup({
                providers = {
                    gitlab = {
                        enabled = true,
                        project_id = "12345"
                    },
                    clickup = {
                        enabled = false
                    }
                }
            })
        end)

        it("should check provider enabled status", function()
            assert.is_true(config.is_provider_enabled("gitlab"))
            assert.is_false(config.is_provider_enabled("clickup"))
            assert.is_false(config.is_provider_enabled("nonexistent"))
        end)

        it("should return enabled providers list", function()
            local enabled = config.get_enabled_providers()
            assert.is_table(enabled)

            local found_gitlab = false
            for _, provider in ipairs(enabled) do
                if provider == "gitlab" then
                    found_gitlab = true
                    break
                end
            end
            assert.is_true(found_gitlab)
        end)
    end)

    describe("configuration validation", function()
        it("should validate configuration", function()
            config.setup({
                providers = {
                    gitlab = {
                        enabled = true,
                        project_id = "12345"
                    }
                }
            })

            local validation = config.validate_config()
            assert.is_not_nil(validation.warnings)
            assert.is_not_nil(validation.errors)
            assert.is_not_nil(validation.enabled_providers)
        end)
    end)
end)
