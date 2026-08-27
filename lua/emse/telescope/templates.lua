local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("emse.config")
local template = require("emse.template")

local M = {}

--- Scan cached templates folder and list files
--- @return table List of template file attributes
local function get_templates()
  local dir = config.get_template_dir()
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

--- Render Telescope picker to search, edit, create and select active templates
--- @param opts table|nil Telescope options
function M.picker(opts)
  opts = opts or {}
  local list = get_templates()
  local mappings = config.defaults.telescope_mappings.templates

  pickers.new(opts, {
    prompt_title = string.format(
      "EMSE Templates (Edit: %s | Select: %s | New: %s | Del: %s)",
      mappings.edit,
      mappings.select,
      mappings.new,
      mappings.delete
    ),
    results_title = "Templates",
    finder = finders.new_table({
      results = list,
      entry_maker = function(entry)
        local is_active = (config.state.active_template == entry.path)
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

      -- Action: Edit selected template in a float
      bind(mappings.edit, function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          template.edit_file(selection.value.path)
        end
      end)

      -- Action: Select template as the active active_template
      bind(mappings.select, function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local item = selection.value
          config.state.active_template = item.path
          vim.notify("emse.nvim: Active Template set to: " .. item.name, vim.log.levels.INFO)
        end
      end)

      -- Action: Create a brand new template on-the-fly
      bind(mappings.new, function()
        actions.close(prompt_bufnr)
        vim.ui.input({ prompt = "New Template Name: " }, function(input)
          if input and input ~= "" then
            template.create_new(input)
          end
        end)
      end)

      -- Action: Delete a template with confirmation
      bind(mappings.delete, function()
        local selection = action_state.get_selected_entry()
        if selection then
          local item = selection.value
          -- Simple yes/no confirmation prompt
          local confirm = vim.fn.confirm("Delete template: " .. item.name .. "?", "&Yes\n&No", 2)
          if confirm == 1 then
            actions.close(prompt_bufnr)
            local success, err = os.remove(item.path)
            if success then
              vim.notify("emse.nvim: Deleted template: " .. item.name, vim.log.levels.INFO)
              -- Re-open picker to show refreshed list
              M.picker(opts)
            else
              vim.notify("emse.nvim: Failed to delete template: " .. (err or ""), vim.log.levels.ERROR)
            end
          end
        end
      end)

      return true
    end,
  }):find()
end

return M