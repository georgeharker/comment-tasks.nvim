# Testing Strategy for comment-tasks.nvim

This document outlines the testing strategy, setup, and guidelines for the
comment-tasks.nvim plugin.

## Test Framework

All tests use [vusted](https://github.com/notomo/vusted), a Busted wrapper
designed for Neovim plugin development.  vusted runs each spec file in an
isolated headless Neovim process, providing the full `vim.*` API without a
running editor instance.

### Why vusted?

* Full Busted feature set (`describe`, `it`, `before_each`, `after_each`,
  `setup`, `teardown`, `insulate`, `finally`, test tagging).
* Same `describe`/`it`/`before_each` syntax as the former plenary.busted
  tests — migration is near-zero.
* Zero plenary.nvim dependency.
* Standard TAP output, easy to parse in CI.

### Installation

```bash
luarocks --lua-version=5.1 install vusted
```

---

## Test Structure

```
tests/                                    # Top-level integration tests
├── detection_spec.lua                   # Comment detection system tests
├── init_spec.lua                        # Plugin initialisation tests
├── run_tests.sh                         # Test runner (vusted)
└── TESTING.md                           # This document

lua/comment-tasks/tests/                 # Internal module tests
├── test_config.lua                      # Configuration management
├── test_detection.lua                   # Enhanced detection tests
├── test_integration.lua                 # Cross-module integration
├── test_neovim_integration.lua          # Neovim-specific integration
├── test_providers.lua                   # Provider-specific tests
└── detection_languages_spec.lua         # Multi-language detection tests

run_all_tests.sh                         # Comprehensive runner (project root)
```

---

## Running Tests

### Prerequisites

1. Install [vusted](https://github.com/notomo/vusted):
   ```bash
   luarocks --lua-version=5.1 install vusted
   ```
2. Ensure the plugin is in Neovim's runtimepath (vusted handles this for specs
   in the project tree).

### Automated Runners (recommended)

```bash
# Run all tests with comprehensive reporting (from project root)
./run_all_tests.sh

# Run tests from tests/ directory
cd tests/ && ./run_tests.sh
```

### Individual spec files

```bash
# Single file
vusted tests/init_spec.lua
vusted lua/comment-tasks/tests/test_config.lua

# Multiple files / whole suite
vusted tests/init_spec.lua tests/detection_spec.lua
vusted lua/comment-tasks/tests/
```

### CI/CD

```bash
#!/bin/bash
set -e
luarocks --lua-version=5.1 install vusted
./run_all_tests.sh
```

---

## Test Status Summary

| File | Tests | Status |
|------|-------|--------|
| tests/detection_spec.lua | 13 | passing |
| tests/init_spec.lua | 12 | passing |
| test_config.lua | 7 | passing |
| test_detection.lua | 6 | passing |
| test_integration.lua | 5/6 | 1 failing |
| test_neovim_integration.lua | 12 | passing |
| test_providers.lua | 7 | passing |
| detection_languages_spec.lua | 20 | passing |

**Total: 82/83 tests passing (98.8%)**

---

## Test Environment

### Mock Environment Variables

```lua
vim.env.CLICKUP_API_KEY = "test_clickup_key"
vim.env.GITHUB_TOKEN    = "test_github_token"
vim.env.TODOIST_API_KEY = "test_todoist_token"
vim.env.GITLAB_API_KEY  = "test_gitlab_token"
```

### HTTP Request Mocking

External API calls are mocked by replacing the `comment-tasks.http` module
before loading providers:

```lua
package.loaded["comment-tasks.http"] = {
    request = function(opts)
        vim.schedule(function()
            opts.callback({
                status = 201,
                body = vim.fn.json_encode({ id = "mock_task_123" })
            })
        end)
    end
}
```

---

## Test Writing Guidelines

### Structure

Follow Arrange-Act-Assert:

```lua
it("should detect Lua comments", function()
    -- Arrange
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"-- TODO: Fix this"})
    vim.bo[buf].filetype = "lua"
    vim.api.nvim_set_current_buf(buf)

    -- Act
    local comment_info = detection.get_comment_info(nil, config.languages, true)

    -- Assert
    assert.is_not_nil(comment_info)
    assert.is_true(comment_info.is_comment)

    -- Cleanup
    vim.api.nvim_buf_delete(buf, {force = true})
end)
```

### Assertions

* `assert.is_not_nil()` — existence checks
* `assert.equals()` — exact matches
* `assert.matches()` — pattern matching
* `assert.is_true()` / `assert.is_false()` — boolean results

Use `assert.is_not_nil(s:match(...))` rather than `assert.is_true(s:match(...))`.

---

## Languages Covered in Detection Tests

Lua, Python, JavaScript, TypeScript, Rust, C/C++, Go, Java, Ruby, PHP,
CSS, HTML, Shell, YAML, JSON, Vim Script (16 languages, 20 test cases).
