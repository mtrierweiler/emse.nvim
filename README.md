# emse.nvim

`emse.nvim` is a highly extendable and interactive Neovim plugin designed for Accela EMSE (Event Management Scripting Engine) developers. It seamlessly integrates with the `emsexec` command-line utility and `telescope.nvim` to edit, test, and run Accela scripts directly from your editor.

---

## Features

- **Asynchronous Execution**: Run whole files or highlighted visual selections with zero UI freeze.
- **Telescope Integration**: Easily navigate environments, script repositories, and custom workspaces.
- **Interactive Initializers**: Create, edit, and select isolated initialization scripts (re-usable mocks) on-the-fly.
- **Templates Workspace**: Manage base template scripts with quick selections.
- **Isolated Scratchpads**: Draft code in real-time scratchpads that automatically execute bypassing any active templates or initializers.
- **Automated Bin Management**: Automatic download, install, and update matching host systems with `emsexec` releases.
- **Interactive Log Split/Floats**: Cleanly parsed, syntax-highlighted server output panels.

---

## Installation

### Dependencies
- [Neovim (v0.9.0+)](https://github.com/neovim/neovim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (required)

### Lazy.nvim
```lua
{
  "username/emse.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("emse").setup({
      -- Overrides go here (see Configuration below)
    })
    
    -- Load telescope extension
    pcall(require("telescope").load_extension, "emse")
  end,
  keys = {
    -- Execution
    { "<leader>er", "<cmd>EmseRun<cr>", desc = "EMSE Run Current Buffer" },
    { "<leader>ev", ":EmseRunVisual<cr>", mode = "v", desc = "EMSE Run Selection" },
    
    -- Telescope Pickers
    { "<leader>ee", "<cmd>Telescope emse environments<cr>", desc = "EMSE Environments" },
    { "<leader>eo", "<cmd>Telescope emse options<cr>", desc = "EMSE Options Toggle" },
    { "<leader>ei", "<cmd>Telescope emse initializers<cr>", desc = "EMSE Initializers (Mocks)" },
    { "<leader>et", "<cmd>Telescope emse templates<cr>", desc = "EMSE Templates" },
    { "<leader>es", "<cmd>Telescope emse scratchpads<cr>", desc = "EMSE Scratchpads" },
  }
}
```

---

## Configuration

You can configure `emse.nvim` by passing a table into `require("emse").setup()`. Below are the default settings:

```lua
require("emse").setup({
  -- Custom path to emsexec. If nil, auto-detects in PATH or installs in cache data directory.
  bin_path = nil, 

  -- Ask to download emsexec automatically if not found.
  auto_download = true, 

  output = {
    layout = "float",   -- Layout style: "float", "split", or "vsplit"
    border = "rounded", -- Border style: "rounded", "double", "single", "shadow"
    focus = true,       -- Automatically focus log buffer on execution
  },

  execute_defaults = {
    commit = false,        -- Default transaction mode (false = Rollback/Simulate, true = Commit)
    user_tx = false,       -- Run under author context without simulating user transactions
    init_script = nil,     -- Default initializer script path
    active_template = nil, -- Default template script path
  },

  telescope_mappings = {
    initializers = {
      edit = "<cr>",   -- Open file in floating editor
      select = "s",    -- Select as active initializer script
      new = "%",       -- Create new file
      delete = "D",    -- Delete file (with confirmation)
    },
    templates = {
      edit = "<cr>",
      select = "s",
      new = "%",
      delete = "D",
    },
    scratchpads = {
      edit = "<cr>",
      new = "%",
      delete = "D",
    }
  }
})
```

---

## Usage

### Subcommands
You can use the unified `:Emse` control command:

* `:Emse run` — Runs the current focused JavaScript buffer.
* `:Emse env` — Opens the environments list picker.
* `:Emse opts` — Toggles transaction modes, active initializers, or templates.
* `:Emse init` — Manages reusable **initializers** scripts.
* `:Emse template` — Manages reusable **templates** scripts.
* `:Emse scratch` — Opens **scratchpads** editor picker.
* `:Emse install` — Downloads or updates the matching `emsexec` CLI tool.

---

## Keymaps Cheat Sheet

By default, the following keymaps can be configured inside your config:

| Keymap | Mode | Action | Description |
|---|---|---|---|
| `<leader>er` | Normal | `EmseRun` | Executes the current active JS file buffer |
| `<leader>ev` | Visual | `EmseRunVisual` | Executes the highlighted code block dynamically |
| `<leader>ee` | Normal | `Telescope emse environments` | Select target agency and environment |
| `<leader>eo` | Normal | `Telescope emse options` | Interactive execution options panel |
| `<leader>ei` | Normal | `Telescope emse initializers` | Open/Select/Create mocks & setups |
| `<leader>et` | Normal | `Telescope emse templates` | Open/Select/Create templates |
| `<leader>es` | Normal | `Telescope emse scratchpads` | Open/Create isolated scratchpads |

---

## Contributing and Testing

The plugin features a robust test suite powered by [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

To run all unit tests locally:
```bash
make test
```
