# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-10-26

### Breaking Changes 🚨
- **REMOVED**: All legacy commands (`ClickUpClose`, `ClickUpReview`, `ClickUpInProgress`, etc.)
- **REMOVED**: Safe wrapper functions for backward compatibility  
- **REMOVED**: Deprecation wrapper functions
- **CHANGED**: Command structure now requires explicit subcommands (e.g., `ClickUpTask new` instead of `ClickUpTask`)

### Added ✨
- **NEW**: Configurable ClickUp status names that match your workspace
- **NEW**: Custom status support for ClickUp with direct status commands
- **NEW**: Enhanced ClickUp completion with status names
- **NEW**: Clean subcommand-based structure for all providers

### Improved 🔧
- **CLEANED**: Removed all TODO comments and legacy code paths
- **CLEANED**: Consistent formatting and whitespace cleanup across all Lua files
- **CLEANED**: Removed trailing whitespace from all source files
- **UPDATED**: Test suite updated to reflect v2.0.0 changes
- **UPDATED**: Documentation with clear migration guide

## [Unreleased]

### Added
 - Deprecation warnings for legacy commands (ClickUpClose, ClickUpReview, etc.)

### Changed
  - `ClickUpTask` (no args) - defaults to creating a new task
  - `ClickUpTask close` - closes an existing task
  - `ClickUpTask review` - sets task to review (ClickUp only)
  - `ClickUpTask progress` - sets task to in progress (ClickUp only)
  - `ClickUpTask addfile` - adds current file to task
  - Similar structure for `GitHubTask`, `TodoistTask`, and `GitLabTask`
   - `ClickUpTask python` no longer works - use `ClickUpTask new python`
   - Forces explicit verb usage for cleaner, more consistent commands
- **BREAKING**: Removed all legacy commands for cleaner codebase
  - Removed: `ClickUpClose`, `ClickUpReview`, `ClickUpInProgress`, `ClickUpAddFile`
  - Removed: `GitHubClose`, `TodoistClose`, `GitLabClose`  
  - Use the new subcommand structure instead

### Migration Guide

#### Before (Old Structure)
```vim
:ClickUpTask           " Create task (optional language arg)
:ClickUpTask python    " Create task with Python language override
:ClickUpClose          " Close task
:ClickUpReview         " Set to review
:ClickUpInProgress     " Set to in progress
:ClickUpAddFile        " Add file to task
```

#### After (New Structure)
```vim
:ClickUpTask           " Create task (defaults to 'new')
:ClickUpTask new       " Create task explicitly
:ClickUpTask new python " Create task with Python language override
:ClickUpTask close     " Close task
:ClickUpTask review    " Set to review
:ClickUpTask progress  " Set to in progress (renamed from 'InProgress')
:ClickUpTask addfile   " Add file to task
```

For previous version history, see the git log or releases section.
