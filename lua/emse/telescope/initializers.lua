local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("emse.config")
local initializer = require("emse.initializer")

local M = {}

--- Scan cached initializers folder and list files
--- @return table List of initializer file attributes
local function get_initializers()
  local dir = config.get_initializer_dir()
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

--- Render Telescope picker to search, edit, create and select active init scripts
--- @param opts table|nil Telescope options
function M.picker(opts)
  opts = opts or {}
  local list = get_initializers()
  local mappings = config.defaults.telescope_mappings.initializers

  pickers.new(opts, {
    prompt_title = string.format(
      "EMSE Initializers (Edit: %s | Select: %s | New: %s | Del: %s)",
      mappings.edit,
      mappings.select,
      mappings.new,
      mappings.delete
    ),
    results_title = "Initializers",
    finder = finders.new_table({
      results = list,
      entry_maker = function(entry)
        local is_active = (config.state.init_script == entry.path)
        local display_name = entry.name
        if is_active then
          display_name = "* " .. display_name
        end
        return {
          value = entry,
          display = display_name,
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

      -- Action: Edit selected initializer in a float
      bind(mappings.edit, function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          initializer.edit_file(selection.value.path)
        end
      end)

      -- Action: Select initializer as the active init_script
      bind(mappings.select, function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local item = selection.value
          config.state.init_script = item.path
          vim.notify("emse.nvim: Active Init Script set to: " .. item.name, vim.log.levels.INFO)
        end
      end)

      -- Action: Create a brand new initializer on-the-fly
      bind(mappings.new, function()
        actions.close(prompt_bufnr)
        vim.ui.input({ prompt = "New Initializer Name: " }, function(input)
          if input and input ~= "" then
            initializer.create_new(input)
          end
        end)
      end)

      -- Action: Delete an initializer with confirmation
      bind(mappings.delete, function()
        local selection = action_state.get_selected_entry()
        if selection then
          local item = selection.value
          -- Simple yes/no confirmation prompt
          local confirm = vim.fn.confirm("Delete initializer: " .. item.name .. "?", "&Yes\n&No", 2)
          if confirm == 1 then
            actions.close(prompt_bufnr)
            local success, err = os.remove(item.path)
            if success then
              vim.notify("emse.nvim: Deleted initializer: " .. item.name, vim.log.levels.INFO)
              -- Re-open picker to show refreshed list
              M.picker(opts)
            else
              vim.notify("emse.nvim: Failed to delete initializer: " .. (err or ""), vim.log.levels.ERROR)
            end
          end
        end
      end)

      return true
    end,
  }):find()
end

return M