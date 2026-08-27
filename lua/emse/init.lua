local M = {}

local config = require("emse.config")
local executor = require("emse.executor")
local installer = require("emse.installer")

--- Setup plugin user options and configurations
--- @param opts table|nil User override preferences
function M.setup(opts)
  config.setup(opts)

  -- Lazy load the telescope extension registration
  local ok, telescope = pcall(require, "telescope")
  if ok then
    pcall(telescope.load_extension, "emse")
  end
end

--- Expose core executor runs
function M.run_current_file()
  executor.run_current_file()
end

function M.run_visual_selection()
  executor.run_visual_selection()
end

--- Expose manual installation routine
--- @param callback function|nil Callback called on download status
function M.install_binary(callback)
  installer.install(callback)
end

return M
