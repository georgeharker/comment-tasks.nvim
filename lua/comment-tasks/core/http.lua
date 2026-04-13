-- lua/comment-tasks/core/http.lua
-- Minimal async HTTP client backed by the system curl binary and vim.system.
-- Zero external dependencies.  Drop-in replacement for plenary.curl in this
-- plugin -- exposes M.request(opts) with the same call signature.
--
-- Public API:
--   M.request(opts)  — async HTTP request (GET/POST/PUT/PATCH/DELETE)
--
-- Threading contract:
--   vim.system spawns curl in a child process; its completion handler runs
--   in a luv callback (fast context — most Neovim API is off-limits).
--   All callbacks to the caller are delivered via vim.schedule (main-loop
--   context).  Callers may safely call any Neovim API from within the
--   callback.
--
-- opts = {
--   url      : string,
--   method   : string?,           -- "get"|"post"|"put"|"patch" (default "get")
--   headers  : table<string,string>?,
--   body     : string?,           -- raw body string (JSON or form-encoded)
--   timeout  : number?,           -- milliseconds (curl uses seconds internally)
--   callback : fun({status:integer, body:string})
-- }
--
-- The callback receives { status = <http_status_integer>, body = <string> }.
-- On curl process failure (non-zero exit) status is 0 and body is stderr.
--
-- Backend selection:
--   Neovim 0.12+ exposes vim.net.request() but the module is GET-only:
--   no vim.net.post/put/patch, no method parameter, no request body, and
--   the response only carries .body (no HTTP status code — it uses
--   curl --fail so HTTP errors become process exit codes).
--   This plugin needs POST/PUT/PATCH with JSON bodies and status-code
--   inspection, so vim.net cannot be used yet.
--   When vim.net gains full HTTP verb support, the has_vim_net guard
--   below makes it straightforward to add a second backend.

local M = {}

-- Feature detection for future vim.net adoption.
local has_vim_net = vim.net and type(vim.net.request) == "function"
    -- vim.net.request currently lacks method/body support;
    -- flip this flag when it does.
    and false

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Build the curl argument list from the request opts table.
---@param opts table
---@return string[]
local function build_args(opts)
    -- -s  suppress progress meter
    -- -S  still show errors when -s is active
    -- -w  append HTTP status code as the final line of stdout
    local args = { "curl", "-s", "-S", "-w", "\n%{http_code}" }

    local method = (opts.method or "get"):upper()
    args[#args + 1] = "-X"
    args[#args + 1] = method

    if opts.headers then
        for k, v in pairs(opts.headers) do
            args[#args + 1] = "-H"
            args[#args + 1] = k .. ": " .. v
        end
    end

    if opts.body and opts.body ~= "" then
        args[#args + 1] = "-d"
        args[#args + 1] = opts.body
    end

    -- Timeout: our API accepts milliseconds; curl expects whole seconds.
    if opts.timeout then
        args[#args + 1] = "--max-time"
        args[#args + 1] = tostring(math.ceil(opts.timeout / 1000))
    end

    args[#args + 1] = opts.url
    return args
end

-- ---------------------------------------------------------------------------
-- Backend: vim.system + curl  (current)
-- ---------------------------------------------------------------------------

--- Async HTTP request via vim.system + curl CLI.
---
--- callback receives { status: integer, body: string }.
--- On curl process failure (non-zero exit) status is 0 and body is stderr.
---
---@param opts { url: string, method: string?, headers: table<string,string>?, body: string?, timeout: number?, callback: fun(response: {status: integer, body: string}) }
local function request_curl(opts)
    local callback = opts.callback
    local args = build_args(opts)

    vim.system(args, { text = true }, function(obj)
        vim.schedule(function()
            if obj.code ~= 0 then
                callback({ status = 0, body = obj.stderr or "" })
                return
            end

            -- The last line of stdout is the HTTP status code injected by -w.
            local stdout = obj.stdout or ""
            local last_nl = stdout:find("\n[^\n]*$")
            local body, status_str
            if last_nl then
                body = stdout:sub(1, last_nl - 1)
                status_str = stdout:sub(last_nl + 1)
            else
                body = ""
                status_str = stdout
            end

            callback({ status = tonumber(vim.trim(status_str)) or 0, body = body })
        end)
    end)
end

-- ---------------------------------------------------------------------------
-- Backend: vim.net  (future — not yet usable, see header comment)
-- ---------------------------------------------------------------------------

--- Placeholder for vim.net-backed requests.
--- Uncomment and implement when vim.net supports method, body, and status codes.
-- local function request_vim_net(opts)
--     vim.net.request(opts.url, {
--         headers = opts.headers,
--     }, function(err, res)
--         vim.schedule(function()
--             if err then
--                 opts.callback({ status = 0, body = err })
--                 return
--             end
--             opts.callback({ status = res.status or 0, body = res.body or "" })
--         end)
--     end)
-- end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Async HTTP request.
---
--- Dispatches to the best available backend:
---   - vim.net.request  (Neovim 0.12+ when method/body/status support lands)
---   - vim.system + curl CLI  (current default)
---
---@param opts { url: string, method: string?, headers: table<string,string>?, body: string?, timeout: number?, callback: fun(response: {status: integer, body: string}) }
function M.request(opts)
    if has_vim_net then
        -- request_vim_net(opts)  -- enable when vim.net is ready
        request_curl(opts)
    else
        request_curl(opts)
    end
end

return M
