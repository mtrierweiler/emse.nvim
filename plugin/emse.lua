-- Initialize Neovim User Commands for emse.nvim

-- Run current file
vim.api.nvim_create_user_command("EmseRun", function()
  require("emse").run_current_file()
end, {
  desc = "Execute the active Javascript buffer against target Accela environment using emsexec"
})

-- Run visual selection
vim.api.nvim_create_user_command("EmseRunVisual", function()
  require("emse").run_visual_selection()
end, {
  range = true,
  desc = "Execute active visual block against target Accela environment using emsexec"
})

-- Install/update emsexec command-line binary tool
vim.api.nvim_create_user_command("EmseInstall", function()
  require("emse").install_binary()
end, {
  desc = "Download and install/update mtrierweiler/emsexec binary matching host architecture"
})

-- Load custom commands shortcuts or Telescope pickers
vim.api.nvim_create_user_command("Emse", function(opts)
  local arg = opts.fargs[1]

  if not arg then
    -- If no subcommand, search for available local scripts
    local telescope_ok, telescope = pcall(require, "telescope")
    if telescope_ok then
      vim.cmd("Telescope emse scripts")
    else
      require("emse").run_current_file()
    end
    return
  end

  if arg == "run" then
    require("emse").run_current_file()
  elseif arg == "install" then
    require("emse").install_binary()
  elseif arg == "env" then
    local telescope_ok, _ = pcall(require, "telescope")
    if telescope_ok then
      vim.cmd("Telescope emse environments")
    else
      vim.notify("emse.nvim: Telescope.nvim is required for environment picker.", vim.log.levels.WARN)
    end
  elseif arg == "opts" then
    local telescope_ok, _ = pcall(require, "telescope")
    if telescope_ok then
      vim.cmd("Telescope emse options")
    else
      vim.notify("emse.nvim: Telescope.nvim is required for options configuration.", vim.log.levels.WARN)
    end
  elseif arg == "init" then
    local telescope_ok, _ = pcall(require, "telescope")
    if telescope_ok then
      vim.cmd("Telescope emse initializers")
    else
      vim.notify("emse.nvim: Telescope.nvim is required for initializer picker.", vim.log.levels.WARN)
    end
  elseif arg == "template" then
    local telescope_ok, _ = pcall(require, "telescope")
    if telescope_ok then
      vim.cmd("Telescope emse templates")
    else
      vim.notify("emse.nvim: Telescope.nvim is required for template picker.", vim.log.levels.WARN)
    end
  elseif arg == "scratch" then
    local telescope_ok, _ = pcall(require, "telescope")
    if telescope_ok then
      vim.cmd("Telescope emse scratchpads")
    else
      vim.notify("emse.nvim: Telescope.nvim is required for scratchpad picker.", vim.log.levels.WARN)
    end
  else
    vim.notify("emse.nvim: Unknown subcommand '" .. arg .. "'. Use run, install, env, opts, init, template, or scratch.", vim.log.levels.ERROR)
  end
end, {
  nargs = "?",
  complete = function(arglead, cmdline, cursorpos)
    local subcommands = { "run", "install", "env", "opts", "init", "template", "scratch" }
    local matches = {}
    for _, sub in ipairs(subcommands) do
      if sub:sub(1, #arglead) == arglead then
        table.insert(matches, sub)
      end
    end
    return matches
  end,
  desc = "Accela EMSE script runner control center"
})