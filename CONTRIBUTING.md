# Contributing to Comment Tasks

Thank you for your interest in contributing to comment-tasks.nvim! We welcome contributions of all kinds.

## 🐛 Filing Bug Reports

When filing a bug report, please include:

1. **Neovim version** (`nvim --version`)
2. **Plugin configuration** (your setup code)
3. **Provider being used** (ClickUp, GitHub, etc.)
4. **Steps to reproduce** the issue
5. **Expected vs actual behavior**
6. **Error messages** (if any)

**Template:**
```markdown
## Bug Description
Brief description of the issue

## Environment
- Neovim version: 
- Plugin version/commit: 
- Provider: 

## Configuration
```lua
-- Your setup code here
```

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior

## Actual Behavior

## Error Messages

## 🚀 Pull Requests

### Before Submitting
- Check existing issues and PRs to avoid duplicates
- Run tests: `nvim --headless -c "PlenaryBustedDirectory tests" -c "qa!"`
- Update documentation if needed

### PR Guidelines
1. **Clear description** of what the PR does
2. **Reference related issues** (if any)
3. **Test your changes** with multiple providers
4. **Follow existing code style** (4 spaces, Lua conventions)
5. **Update docs** if adding/changing functionality

### Adding New Providers
If adding a new provider:
- Follow the pattern in `lua/comment-tasks/providers/`
- Extend the `Provider` class from `providers/interface.lua`
- Add configuration to `core/config.lua`
- Add tests in `tests/`
- Update README provider table

### Commit Messages
Use clear, descriptive commit messages:
```
feat: add Linear provider support
fix: handle missing task URLs in comments
docs: update ClickUp configuration examples
```

## 🧪 Running Tests

```bash
# Run all tests
nvim --headless -c "PlenaryBustedDirectory tests" -c "qa!"

# Run specific test file
nvim --headless -c "PlenaryBustedFile tests/init_spec.lua" -c "qa!"
```

## 📝 Documentation

- Keep README examples up to date
- Update provider-specific docs in `docs/providers/`
- Add examples to `docs/examples/` for new features

## ❓ Questions

- **General questions**: Use [GitHub Discussions](https://github.com/georgeharker/comment-tasks.nvim/discussions)  
- **Bug reports**: Use [GitHub Issues](https://github.com/georgeharker/comment-tasks.nvim/issues)
- **Feature requests**: Use [GitHub Issues](https://github.com/georgeharker/comment-tasks.nvim/issues) with "enhancement" label

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.
