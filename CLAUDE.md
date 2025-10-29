# CLAUDE.md

You are a Lua(LuaJIT) programming language for develop the Neovim plugin.

# Purpose

Provide expert-level insights and solutions for the Lua(LuaJIT) programming language for develop the Neovim plugin.

Your responses should include code snippet examples (where applicable), best practices, and explanations of underlying concepts.

Remember:

* Do not include the entire Lua(LuaJIT) code in your response; only save it to the specified file if specified.
* If you encounter any insurmountable issues during conversion, explain them clearly in the conversion summary.

## General Rules

* **MUST use the OpenResty forked (https://github.com/openresty/luajit2) LuaJIT.**
* **MUST actively use third-party packages whenever possible, like when performance or any other requirement is involved.**
* Highlight any considerations, such as potential performance impacts, with advised solutions.
* Include links to reputable sources for further reading (when beneficial), and prefer official documentation.
* Provide real-world examples or code snippets to illustrate solutions.
* Avoid `No newline at end of file` git error.

## Project Structure & Module Organization

Contributor guide for accelerated-jk.nvim - a Neovim plugin that accelerates j/k movement steps during key repetition.

The plugin follows the standard Neovim plugin structure:

```
accelerated-jk.nvim/
├── lua/accelerated-jk/      # Core plugin modules
│   ├── init.lua            # Main entry point and setup
│   ├── config.lua          # Configuration management
│   ├── time_driven.lua     # Time-based acceleration mode
│   └── position_driven.lua # Position-based acceleration mode
├── plugin/                 # Plugin initialization
│   └── accelerated-jk.lua  # Auto-loaded plugin entry
└── doc/                    # Vim help documentation
    ├── accelerated-jk.txt  # Help file
    └── tags                # Help tags index
```

**Module Organization:**
- Each Lua module exports a table (typically `M`) containing its public API
- Modules use `require()` for dependencies
- Driver pattern: `init.lua` creates mode-specific drivers (`time_driven` or `position_driven`)

## Coding Style & Naming Conventions

This project uses StyLua for code formatting. Configuration in `.stylua.toml`:

- **Indentation:** 2 spaces (no tabs)
- **Line width:** 120 characters maximum
- **Quotes:** Single quotes preferred (`'string'`)
- **Function calls:** Always use parentheses
- **Naming:** snake_case for functions and variables (e.g., `create_driver`, `acceleration_table`)
- **Module pattern:** `local M = {}` followed by `return M`
- **Function definition:** `M.function_name = function(args) ... end`

**Formatting Command:**
```bash
stylua .
```

**Code Conventions:**
- Use early returns and guard clauses
- Clear separation between local functions and exported functions
- Prefer explicit over implicit (e.g., always use `function()` keyword)

## Development Commands

**Format code with StyLua:**
```bash
stylua .
```

**Test the plugin locally:**
1. Clone the repository
2. Add to your Neovim config (example with lazy.nvim):
   ```lua
   { dir = '/path/to/accelerated-jk.nvim', config = function()
     require('accelerated-jk').setup()
   end }
   ```
3. Restart Neovim and test the mappings

**Generate help tags:**
```vim
:helptags doc/
```

## Documentation Guidelines

**Vim Help Documentation:**
- Located in `doc/accelerated-jk.txt`
- Uses standard Vimdoc format with tags
- All tags prefixed with namespace: `accelerated-jk-*`
- Examples: `*accelerated-jk-usage*`, `*accelerated-jk-conf.mode*`
- Keep aligned with README.md content

**Tag Naming Pattern:**
- General sections: `accelerated-jk-section`
- Configuration options: `accelerated-jk-conf.option_name`
- Modes: `accelerated-jk-modes.mode_name`

## Commit & Pull Request Guidelines

**Commit Message Format:**

The project uses conventional-style commit messages with flexible formatting:

```
type(scope): description
```

or

```
type: description
```

or

```
[type]: description
```

**Types:**
- `feat`: New feature or enhancement
- `fix`: Bug fix
- `doc`: Documentation changes
- `refactor`: Code refactoring without behavior changes
- `format`: Code formatting changes (StyLua, whitespace)
- `init`: Initial commits or major restructuring

**Examples from project history:**
- `fix(config): setup() can only be enabled on the first call because of the init guard clause`
- `feat: add acceleration support for every motions given by config.acceleration_motions`
- `doc: add acceleration_motions description`
- `[format]: add stylua.toml`

**Guidelines:**
- Keep messages concise and descriptive
- Use present tense ("add feature" not "added feature")
- Use lowercase for the first word after the colon
- Reference issue numbers when applicable

**Pull Requests:**
- Ensure code is formatted with StyLua before submitting
- Test changes locally in Neovim
- Update documentation (both README.md and doc/accelerated-jk.txt) if adding features
- Include examples in PR description for new features

## Testing

Currently, this project does not have an automated testing framework. When making changes:

1. **Manual Testing:** Test all affected functionality in Neovim
2. **Test both modes:** Verify changes work with both `time_driven` and `position_driven` modes
3. **Edge cases:** Test with various `acceleration_table` and `deceleration_table` configurations
4. **Key mappings:** Verify all four mappings work correctly: `<Plug>(accelerated_jk_j/k/gj/gk)`

## Architecture Overview

**Plugin Initialization Flow:**
1. `plugin/accelerated-jk.lua` loads on Neovim startup (if installed)
2. User calls `require('accelerated-jk').setup(opts)` with configuration
3. `config.lua` merges user options with defaults
4. `init.lua` creates appropriate driver (time_driven or position_driven)
5. Key mappings are created for configured motions

**Movement Handling:**
1. User presses mapped key (j/k/gj/gk or custom motion)
2. Mapping calls `require('accelerated-jk').move_to(movement)`
3. Driver calculates acceleration step based on timing/position
4. Driver executes movement with calculated step count

**Key Design Patterns:**
- **Strategy Pattern:** Pluggable acceleration modes (time_driven vs position_driven)
- **Module Pattern:** Each file exports a table with public functions
- **Configuration Management:** Centralized in config.lua with validation
