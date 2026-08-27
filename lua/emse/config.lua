local M = {}

M.defaults = {
  bin_path = nil, -- Custom path to emsexec. If nil, auto-detects in path or data directory.
  auto_download = true, -- Ask to download if emsexec is not found.
  output = {
    layout = "float", -- "float", "split", or "vsplit"
    border = "rounded", -- "rounded", "double", "single", "shadow"
    focus = true, -- Automatically focus log buffer on execution
  },
  execute_defaults = {
    -- Dynamic transaction mode defaults:
    -- "Always Rollback", "Commit If Successful", or "Use User Transaction"
    tx_mode = "Always Rollback",
    init_script = nil, -- Optional workspace default init script path
    active_template = nil, -- Optional workspace default active template path
  },
  telescope_mappings = {
    initializers = {
      edit = "<cr>",       -- Edit initializer
      select = "s",        -- Select as active init script
      new = "%",           -- Create a new initializer
      delete = "D",        -- Delete initializer with confirmation
    },
    templates = {
      edit = "<cr>",       -- Edit template
      select = "s",        -- Select as active template
      new = "%",           -- Create a new template
      delete = "D",        -- Delete template with confirmation
    },
    scratchpads = {
      edit = "<cr>",       -- Edit scratchpad
      new = "%",           -- Create a new scratchpad
      delete = "D",        -- Delete scratchpad with confirmation
    }
  }
}

-- Session state representing active configuration overrides
M.state = {
  active_agency = nil,
  active_env = nil,
  tx_mode = "Always Rollback", -- default transaction selection
  init_script = nil,
  active_template = nil,
}

--- Get absolute path to the directory where re-usable initializer scripts are saved
--- @return string Absolute directory path
function M.get_initializer_dir()
  local cache_dir = vim.fn.stdpath("cache") .. "/emse-nvim/initializers"
  vim.fn.mkdir(cache_dir, "p")
  return cache_dir
end

--- Get absolute path to the directory where templates are saved
--- @return string Absolute directory path
function M.get_template_dir()
  local cache_dir = vim.fn.stdpath("cache") .. "/emse-nvim/templates"
  vim.fn.mkdir(cache_dir, "p")
  return cache_dir
end

--- Get absolute path to the directory where scratchpads are saved
--- @return string Absolute directory path
function M.get_scratchpad_dir()
  local cache_dir = vim.fn.stdpath("cache") .. "/emse-nvim/scratchpads"
  vim.fn.mkdir(cache_dir, "p")
  return cache_dir
end

--- Merge user choices into plugin options and initialize state
--- @param opts table|nil User configuration options
function M.setup(opts)
  -- Reset defaults to base layout to prevent test leaks
  M.defaults = {
    bin_path = nil,
    auto_download = true,
    output = {
      layout = "float",
      border = "rounded",
      focus = true,
    },
    execute_defaults = {
      tx_mode = "Always Rollback",
      init_script = nil,
      active_template = nil,
    },
    telescope_mappings = {
      initializers = {
        edit = "<cr>",
        select = "s",
        new = "%",
        delete = "D",
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
  }

  M.defaults = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- Initialize runtime session state with execution defaults
  M.state.tx_mode = M.defaults.execute_defaults.tx_mode
  M.state.init_script = M.defaults.execute_defaults.init_script
  M.state.active_template = M.defaults.execute_defaults.active_template
end

return M