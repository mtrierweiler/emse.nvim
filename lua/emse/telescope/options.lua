local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("emse.config")

local M = {}

--- Generate status toggles menu options list
--- @return table Dynamic options list reflecting current active configuration values
local function get_options()
  local state = config.state
  return {
    {
      id = "active_env",
      label = string.format("Target Environment: %s", (state.active_agency and state.active_env) and string.format("%s (%s)", state.active_env, state.active_agency) or "NONE"),
      action = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        require("emse.telescope.environments").picker()
      end,
    },
    {
      id = "clear_env",
      label = "Clear Target Environment",
      action = function()
        state.active_agency = nil
        state.active_env = nil
        vim.notify("emse.nvim: Target environment cleared.", vim.log.levels.INFO)
      end,
    },
    {
      id = "tx_mode",
      label = string.format("Database Transaction: %s", state.tx_mode),
      action = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        -- Open sub-picker containing verbatim transaction modes
        vim.ui.select({ "Always Rollback", "Commit If Successful", "Use User Transaction" }, {
          prompt = "Select Database Transaction Mode:"
        }, function(choice)
          if choice then
            state.tx_mode = choice
            vim.notify("emse.nvim: Transaction mode updated to: " .. choice, vim.log.levels.INFO)
          end
          -- Re-open options config picker instantly for seamless feedback
          M.picker()
        end)
      end,
    },
    {
      id = "init_script",
      label = string.format("Active Init Script: %s", state.init_script and vim.fn.fnamemodify(state.init_script, ":t:r") or "NONE"),
      action = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        -- Open our dedicated Initializer selector
        require("emse.telescope.initializers").picker()
      end,
    },
    {
      id = "clear_init",
      label = "Clear Active Init Script",
      action = function()
        state.init_script = nil
        vim.notify("emse.nvim: Active Init Script cleared.", vim.log.levels.INFO)
      end,
    },
    {
      id = "active_template",
      label = string.format("Active Template: %s", state.active_template and vim.fn.fnamemodify(state.active_template, ":t:r") or "NONE"),
      action = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        -- Open our dedicated Template selector
        require("emse.telescope.templates").picker()
      end,
    },
    {
      id = "clear_template",
      label = "Clear Active Template",
      action = function()
        state.active_template = nil
        vim.notify("emse.nvim: Active Template cleared.", vim.log.levels.INFO)
      end,
    }
  }
end

--- Render Options configuration Telescope picker
--- @param opts table|nil Telescope options
function M.picker(opts)
  opts = opts or {}

  local function refresh_picker()
    local options = get_options()
    pickers.new(opts, {
      prompt_title = "EMSE Execution Options",
      finder = finders.new_table({
        results = options,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.label,
            ordinal = entry.id,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          if selection then
            local item = selection.value
            -- If it's a nested launcher action, we pass the bufnr
            if item.id == "init_script" or item.id == "active_template" or item.id == "tx_mode" or item.id == "active_env" then
              item.action(prompt_bufnr)
            else
              actions.close(prompt_bufnr)
              item.action()
              -- Re-open picker so toggling values stays visual/interactive!
              M.picker(opts)
            end
          end
        end)
        return true
      end,
    }):find()
  end

  refresh_picker()
end

return M