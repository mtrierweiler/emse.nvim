local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local executor = require("emse.executor")

local M = {}

--- Render Telescope picker to search for local .js scripts and execute them
--- @param opts table|nil Telescope options
function M.picker(opts)
  opts = opts or {}

  -- Use find_files logic but filter specifically for JavaScript files
  opts.attach_mappings = function(prompt_bufnr, map)
    actions.select_default:replace(function()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      if selection then
        -- Instead of opening the file, execute it directly with emsexec!
        local file_path = selection[1] or selection.value or selection.path
        if file_path then
          vim.notify("emse.nvim: Executing " .. vim.fn.fnamemodify(file_path, ":t") .. "...", vim.log.levels.INFO)
          -- Run through executor asynchronously
          -- Since we're executing a file found on disk, we pass the absolute or relative path
          require("emse.executor").run_file_path(file_path)
        end
      end
    end)
    return true
  end

  -- Fallback search command restricted to *.js files
  opts.find_command = { "find", ".", "-type", "f", "-name", "*.js" }
  if vim.fn.executable("rg") == 1 then
    opts.find_command = { "rg", "--files", "--glob", "*.js" }
  end

  require("telescope.builtin").find_files(opts)
end

return M
