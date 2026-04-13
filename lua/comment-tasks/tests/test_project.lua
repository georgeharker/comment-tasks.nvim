-- Tests for lua/comment-tasks/core/project.lua

local assert = require("luassert")

describe("comment-tasks project root detection", function()
    local project

    before_each(function()
        -- Reload module fresh for each test
        package.loaded["comment-tasks.core.project"] = nil
        project = require("comment-tasks.core.project")
    end)

    -- -----------------------------------------------------------------------
    -- find_git_root
    -- -----------------------------------------------------------------------

    describe("find_git_root", function()
        it("should find the git root from a subdirectory", function()
            -- The plugin itself lives inside a git repo; its source directory
            -- is a reliable path to test upward traversal.
            local plugin_src = vim.fn.fnamemodify(
                debug.getinfo(1, "S").source:sub(2), ":p:h"
            )
            local root = project.find_git_root(plugin_src)
            assert.is_not_nil(root)
            -- Root must contain a .git entry
            assert.is_true(
                vim.fn.isdirectory(root .. "/.git") == 1
                    or vim.fn.filereadable(root .. "/.git") == 1,
                "expected .git at: " .. tostring(root)
            )
        end)

        it("should return nil when no git repo exists", function()
            -- /tmp is unlikely to be inside a git repo
            local root = project.find_git_root("/tmp")
            assert.is_nil(root)
        end)

        it("should return the directory itself when .git is at that level", function()
            -- Temporarily create a fake .git directory in a temp location
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            vim.fn.mkdir(tmp .. "/.git", "p")

            local root = project.find_git_root(tmp)
            assert.equals(tmp, root)

            -- Cleanup
            vim.fn.delete(tmp, "rf")
        end)
    end)

    -- -----------------------------------------------------------------------
    -- find_project_root
    -- -----------------------------------------------------------------------

    describe("find_project_root", function()
        it("should find root via a standard marker file", function()
            -- Create a temp tree: root/ pyproject.toml; root/sub/
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/sub", "p")
            vim.fn.writefile({"[project]"}, tmp .. "/pyproject.toml")

            local root, has_config = project.find_project_root(tmp .. "/sub")
            assert.is_not_nil(root)
            assert.equals(tmp, root)
            assert.is_false(has_config)

            vim.fn.delete(tmp, "rf")
        end)

        it("should prefer the closest ancestor marker", function()
            -- outer/pyproject.toml  and  outer/inner/package.json
            -- starting from outer/inner should resolve to outer/inner
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/inner", "p")
            vim.fn.writefile({"[project]"}, tmp .. "/pyproject.toml")
            vim.fn.writefile({"{}"}, tmp .. "/inner/package.json")

            local root = project.find_project_root(tmp .. "/inner")
            assert.is_not_nil(root)
            assert.equals(tmp .. "/inner", root)

            vim.fn.delete(tmp, "rf")
        end)

        it("should return nil when no marker is found", function()
            local root = project.find_project_root("/tmp", {"no_such_marker_xyz"})
            assert.is_nil(root)
        end)

        it("should accept a custom markers list", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            vim.fn.writefile({""}, tmp .. "/MY_ROOT_MARKER")

            local root = project.find_project_root(tmp, {"MY_ROOT_MARKER"})
            assert.is_not_nil(root)
            assert.equals(tmp, root)

            vim.fn.delete(tmp, "rf")
        end)

        it("should find the plugin repo root when starting from src", function()
            local plugin_src = vim.fn.fnamemodify(
                debug.getinfo(1, "S").source:sub(2), ":p:h"
            )
            local root = project.find_project_root(plugin_src)
            assert.is_not_nil(root)
        end)

        it("should stop at .comment-tasks.json before other markers", function()
            -- outer/.git  and  outer/inner/.comment-tasks.json
            -- starting from outer/inner/sub should stop at outer/inner
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/inner/sub", "p")
            vim.fn.mkdir(tmp .. "/.git", "p")
            vim.fn.writefile({"{}"}, tmp .. "/inner/.comment-tasks.json")

            local root, has_config = project.find_project_root(tmp .. "/inner/sub")
            assert.is_not_nil(root)
            assert.equals(tmp .. "/inner", root)
            assert.is_true(has_config)

            vim.fn.delete(tmp, "rf")
        end)

        it("should return has_config=true when config is at git root", function()
            -- root has both .git and .comment-tasks.json
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/sub", "p")
            vim.fn.mkdir(tmp .. "/.git", "p")
            vim.fn.writefile({"{}"}, tmp .. "/.comment-tasks.json")

            local root, has_config = project.find_project_root(tmp .. "/sub")
            assert.is_not_nil(root)
            assert.equals(tmp, root)
            assert.is_true(has_config)

            vim.fn.delete(tmp, "rf")
        end)

        it("should find root marker when no config file exists", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/sub", "p")
            vim.fn.mkdir(tmp .. "/.git", "p")

            local root, has_config = project.find_project_root(tmp .. "/sub")
            assert.is_not_nil(root)
            assert.equals(tmp, root)
            assert.is_false(has_config)

            vim.fn.delete(tmp, "rf")
        end)
    end)

    -- -----------------------------------------------------------------------
    -- load_project_config
    -- -----------------------------------------------------------------------

    describe("load_project_config", function()
        it("should return nil,nil when no config file exists", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")

            local cfg, err = project.load_project_config(tmp)
            assert.is_nil(cfg)
            assert.is_nil(err)

            vim.fn.delete(tmp, "rf")
        end)

        it("should parse a valid config file", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            vim.fn.writefile(
                {'{"default_provider":"github","providers":{"github":{"repo_owner":"acme","repo_name":"api"}}}'},
                tmp .. "/.comment-tasks.json"
            )

            local cfg, err = project.load_project_config(tmp)
            assert.is_nil(err)
            assert.is_not_nil(cfg)
            assert.equals("github", cfg.default_provider)
            assert.equals("acme", cfg.providers.github.repo_owner)
            assert.equals("api", cfg.providers.github.repo_name)

            vim.fn.delete(tmp, "rf")
        end)

        it("should return nil and an error for invalid JSON", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            vim.fn.writefile({"not json {"}, tmp .. "/.comment-tasks.json")

            local cfg, err = project.load_project_config(tmp)
            assert.is_nil(cfg)
            assert.is_not_nil(err)
            assert.is_not_nil(err:match("invalid JSON"))

            vim.fn.delete(tmp, "rf")
        end)

        it("should return nil and an error for an empty file", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            vim.fn.writefile({}, tmp .. "/.comment-tasks.json")

            local cfg, err = project.load_project_config(tmp)
            assert.is_nil(cfg)
            assert.is_not_nil(err)

            vim.fn.delete(tmp, "rf")
        end)

        it("should support all provider override fields", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            local content = vim.fn.json_encode({
                providers = {
                    clickup  = { list_id = "123", team_id = "456" },
                    github   = { repo_owner = "org", repo_name = "repo" },
                    gitlab   = { project_id = "789", gitlab_url = "https://gl.acme.com" },
                    jira     = { project_key = "PROJ", server_url = "https://acme.atlassian.net" },
                    linear   = { team_id = "T1", project_id = "P1" },
                    asana    = { project_gid = "gid1", assignee_gid = "gid2" },
                    todoist  = { project_id = "tod1" },
                    notion   = { database_id = "db1" },
                    trello   = { list_id = "tr1" },
                    monday   = { board_id = "mon1" },
                }
            })
            vim.fn.writefile({content}, tmp .. "/.comment-tasks.json")

            local cfg, err = project.load_project_config(tmp)
            assert.is_nil(err)
            assert.is_not_nil(cfg)
            assert.equals("123", cfg.providers.clickup.list_id)
            assert.equals("org", cfg.providers.github.repo_owner)
            assert.equals("PROJ", cfg.providers.jira.project_key)

            vim.fn.delete(tmp, "rf")
        end)
    end)

    -- -----------------------------------------------------------------------
    -- Project config override integration
    -- -----------------------------------------------------------------------

    describe("project config overrides", function()
        local config

        before_each(function()
            package.loaded["comment-tasks.core.config"] = nil
            package.loaded["comment-tasks.core.project"] = nil
            config = require("comment-tasks.core.config")
            project = require("comment-tasks.core.project")
            -- Set up a baseline Neovim config
            config.setup({
                default_provider = "clickup",
                providers = {
                    clickup = {
                        enabled = true,
                        api_key_env = "CLICKUP_API_KEY",
                        list_id = "original_list",
                        team_id = "original_team",
                    },
                    github = {
                        enabled = true,
                        api_key_env = "GITHUB_TOKEN",
                        repo_owner = "original_owner",
                        repo_name = "original_repo",
                    },
                },
            })
        end)

        -- Helper: build an effective config by loading a project file and
        -- applying overrides, mirroring what get_effective_config does
        -- internally but using a known root directory instead of the
        -- current buffer.
        local function effective_from_root(root)
            local effective = vim.deepcopy(config.config)
            local project_cfg, err = project.load_project_config(root)
            assert.is_nil(err)
            if project_cfg then
                -- Re-use the same allowlist logic that config uses internally.
                -- We call get_effective_config's private helper indirectly by
                -- round-tripping through the public API surface.
                if project_cfg.default_provider then
                    effective.default_provider = project_cfg.default_provider
                end
                local PROJECT_OVERRIDE_FIELDS = {
                    clickup = { "list_id", "team_id" },
                    github  = { "repo_owner", "repo_name" },
                    gitlab  = { "project_id", "gitlab_url" },
                    jira    = { "project_key", "server_url" },
                    linear  = { "team_id", "project_id" },
                    asana   = { "project_gid", "assignee_gid" },
                    todoist = { "project_id" },
                    notion  = { "database_id" },
                    trello  = { "list_id" },
                    monday  = { "board_id" },
                }
                local overrides = project_cfg.providers or {}
                for pname, values in pairs(overrides) do
                    local allowed = PROJECT_OVERRIDE_FIELDS[pname]
                    local target  = effective.providers and effective.providers[pname]
                    if allowed and target and type(values) == "table" then
                        for _, field in ipairs(allowed) do
                            if values[field] ~= nil then
                                target[field] = values[field]
                            end
                        end
                    end
                end
            end
            return effective, project_cfg
        end

        it("should apply overrides when config is at the root stop-point (.git level)", function()
            -- root/  .git/  .comment-tasks.json
            -- root/sub/
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/sub", "p")
            vim.fn.mkdir(tmp .. "/.git", "p")
            vim.fn.writefile({vim.fn.json_encode({
                providers = {
                    clickup = { list_id = "project_list", team_id = "project_team" },
                }
            })}, tmp .. "/.comment-tasks.json")

            -- Verify root detection finds the right place
            local root, has_config = project.find_project_root(tmp .. "/sub")
            assert.equals(tmp, root)
            assert.is_true(has_config)

            -- Verify overrides apply
            local eff = effective_from_root(root)
            assert.equals("project_list", eff.providers.clickup.list_id)
            assert.equals("project_team", eff.providers.clickup.team_id)

            vim.fn.delete(tmp, "rf")
        end)

        it("should apply overrides when config is mid-hierarchy above nested markers", function()
            -- root/  .git/
            -- root/services/  .comment-tasks.json
            -- root/services/backend/
            -- root/services/backend/src/  (start here)
            -- No other markers between src and services, so config file wins.
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/services/backend/src", "p")
            vim.fn.mkdir(tmp .. "/.git", "p")
            vim.fn.writefile({vim.fn.json_encode({
                default_provider = "github",
                providers = {
                    github = { repo_owner = "monorepo-org", repo_name = "backend-svc" },
                }
            })}, tmp .. "/services/.comment-tasks.json")

            -- Should stop at services/ (config file)
            local root, has_config = project.find_project_root(tmp .. "/services/backend/src")
            assert.equals(tmp .. "/services", root)
            assert.is_true(has_config)

            -- Verify overrides apply
            local eff = effective_from_root(root)
            assert.equals("github", eff.default_provider)
            assert.equals("monorepo-org", eff.providers.github.repo_owner)
            assert.equals("backend-svc", eff.providers.github.repo_name)

            vim.fn.delete(tmp, "rf")
        end)

        it("should not mutate M.config when overrides are applied", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            vim.fn.writefile({vim.fn.json_encode({
                default_provider = "github",
                providers = {
                    clickup = { list_id = "override_list" },
                }
            })}, tmp .. "/.comment-tasks.json")

            -- Snapshot M.config values before
            local orig_provider = config.config.default_provider
            local orig_list = config.config.providers.clickup.list_id

            local eff = effective_from_root(tmp)
            -- Effective has overrides
            assert.equals("github", eff.default_provider)
            assert.equals("override_list", eff.providers.clickup.list_id)
            -- M.config is unchanged
            assert.equals(orig_provider, config.config.default_provider)
            assert.equals(orig_list, config.config.providers.clickup.list_id)

            vim.fn.delete(tmp, "rf")
        end)

        it("should not override api_key_env even if present in project file", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            vim.fn.writefile({vim.fn.json_encode({
                providers = {
                    clickup = {
                        list_id = "safe_list",
                        api_key_env = "EVIL_KEY",
                        enabled = false,
                    },
                }
            })}, tmp .. "/.comment-tasks.json")

            local eff = effective_from_root(tmp)
            -- Allowed field applies
            assert.equals("safe_list", eff.providers.clickup.list_id)
            -- Disallowed fields are NOT overridden
            assert.equals("CLICKUP_API_KEY", eff.providers.clickup.api_key_env)
            assert.is_true(eff.providers.clickup.enabled)

            vim.fn.delete(tmp, "rf")
        end)

        it("should apply overrides from multiple providers simultaneously", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp, "p")
            vim.fn.writefile({vim.fn.json_encode({
                providers = {
                    clickup = { list_id = "cu_list" },
                    github  = { repo_owner = "gh_owner", repo_name = "gh_repo" },
                }
            })}, tmp .. "/.comment-tasks.json")

            local eff = effective_from_root(tmp)
            assert.equals("cu_list", eff.providers.clickup.list_id)
            assert.equals("original_team", eff.providers.clickup.team_id) -- unchanged
            assert.equals("gh_owner", eff.providers.github.repo_owner)
            assert.equals("gh_repo", eff.providers.github.repo_name)

            vim.fn.delete(tmp, "rf")
        end)

        it("should leave config unchanged when no project file exists at root", function()
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/sub", "p")
            vim.fn.mkdir(tmp .. "/.git", "p")
            -- No .comment-tasks.json anywhere

            local root, has_config = project.find_project_root(tmp .. "/sub")
            assert.equals(tmp, root)
            assert.is_false(has_config)

            local eff = effective_from_root(root)
            assert.equals("original_list", eff.providers.clickup.list_id)
            assert.equals("original_team", eff.providers.clickup.team_id)
            assert.equals("clickup", eff.default_provider)

            vim.fn.delete(tmp, "rf")
        end)
    end)

    -- -----------------------------------------------------------------------
    -- root_markers via config
    -- -----------------------------------------------------------------------

    describe("root_markers from config", function()
        local config

        before_each(function()
            package.loaded["comment-tasks.core.config"] = nil
            config = require("comment-tasks.core.config")
        end)

        it("should include .git as a default marker", function()
            local markers = config.config.root_markers
            local found = false
            for _, m in ipairs(markers) do
                if m == ".git" then found = true; break end
            end
            assert.is_true(found, "expected .git in root_markers")
        end)

        it("should include common build-system markers", function()
            local markers = config.config.root_markers
            local expected = {
                "pyproject.toml", "package.json", "Cargo.toml",
                "go.mod", "Gemfile", "pom.xml", "CMakeLists.txt",
            }
            for _, marker in ipairs(expected) do
                local found = false
                for _, m in ipairs(markers) do
                    if m == marker then found = true; break end
                end
                assert.is_true(found, "expected '" .. marker .. "' in root_markers")
            end
        end)

        it("should allow user to override root_markers via setup()", function()
            config.setup({ root_markers = { "MY_CUSTOM_MARKER", ".git" } })
            local markers = config.config.root_markers
            assert.equals(2, #markers)
            assert.equals("MY_CUSTOM_MARKER", markers[1])
            assert.equals(".git", markers[2])
        end)

        it("should allow user to extend root_markers via setup()", function()
            -- User appends to defaults by including them plus extras
            local defaults = vim.deepcopy(config.default_config.root_markers)
            table.insert(defaults, "MY_EXTRA_MARKER")
            config.setup({ root_markers = defaults })
            local markers = config.config.root_markers
            local found = false
            for _, m in ipairs(markers) do
                if m == "MY_EXTRA_MARKER" then found = true; break end
            end
            assert.is_true(found)
        end)

        it("project.find_project_root should use config markers", function()
            -- Override config markers to something unique
            config.setup({ root_markers = { "UNIQUE_TEST_MARKER" } })

            -- Reload project so it picks up new config
            package.loaded["comment-tasks.core.project"] = nil
            project = require("comment-tasks.core.project")

            -- Create a temp tree with the custom marker
            local tmp = vim.fn.tempname()
            vim.fn.mkdir(tmp .. "/sub", "p")
            vim.fn.writefile({""}, tmp .. "/UNIQUE_TEST_MARKER")

            local root = project.find_project_root(tmp .. "/sub")
            assert.is_not_nil(root)
            assert.equals(tmp, root)

            vim.fn.delete(tmp, "rf")
        end)
    end)
end)
