local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("emse.config")
local scratchpad = require("emse.scratchpad")

local M = {}

--- Scan cached scratchpads folder and list files
--- @return table List of scratchpad file attributes
local function get_scratchpads()
  local dir = config.get_scratchpad_dir()
  local files = vim.fn.globpath(dir, "*.js", false, true)
  local results = {}

  for _, path in ipairs(files) do
    local base_name = vim.fn.fnamemodify(path, ":t:r")
    table.insert(results, {
      path = path,
      name = base_name,
    })
  end

  return results
end

--- Render Telescope picker to search, edit, create scratchpads
--- @param opts table|nil Telescope options
function M.picker(opts)
  opts = opts or {}
  local list = get_scratchpads()
  local mappings = config.defaults.telescope_mappings.scratchpads

  pickers.new(opts, {
    prompt_title = string.format(
      "EMSE Scratchpads (Edit: %s | New: %s | Del: %s)",
      mappings.edit,
      mappings.new,
      mappings.delete
    ),
    results_title = "Scratchpads",
    finder = finders.new_table({
      results = list,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name,
          ordinal = entry.name,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      -- Helper to bind actions to both normal and insert modes safely
      local function bind(key, action)
        if key and key ~= "" then
          map("i", key, action)
          map("n", key, action)
        end
      end

      -- Action: Edit selected scratchpad in a float
      bind(mappings.edit, function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          scratchpad.edit_file(selection.value.path)
        end
      end)

      -- Action: Create a brand new scratchpad on-the-fly
      bind(mappings.new, function()
        actions.close(prompt_bufnr)
        vim.ui.input({ prompt = "New Scratchpad Name: " }, function(input)
          if input and input ~= "" then
            scratchpad.create_new(input)
          end
        end)
      end)

      -- Action: Delete a scratchpad with confirmation
      bind(mappings.delete, function()
        local selection = action_state.get_selected_entry()
        if selection then
          local item = selection.value
          -- Simple yes/no confirmation prompt
          local confirm = vim.fn.confirm("Delete scratchpad: " .. item.name .. "?", "&Yes\n&No", 2)
          if confirm == 1 then
            actions.close(prompt_bufnr)
            local success, err = os.remove(item.path)
            if success then
              vim.notify("emse.nvim: Deleted scratchpad: " .. item.name, vim.log.levels.INFO)
              -- Re-open picker to show refreshed list
              M.picker(opts)
            else
              vim.notify("emse.nvim: Failed to delete scratchpad: " .. (err or ""), vim.log.levels.ERROR)
            end
          end
        end
      end)

      return true
    end,
  }):find()
end

return M