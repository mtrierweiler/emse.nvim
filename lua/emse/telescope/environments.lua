local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("emse.config")

local M = {}

--- Parse ~/.config/emsexec/config.json to discover configurations
--- @return table Array of discovered { agency = string, env = string } environments
function M.discover_environments()
  local home = os.getenv("HOME") or os.getenv("USERPROFILE")
  local config_file = home .. "/.config/emsexec/config.json"

  -- If on Windows, check APPDATA location too
  if vim.loop.os_uname().sysname:find("Windows") then
    local appdata = os.getenv("APPDATA")
    if appdata then
      config_file = appdata .. "\\emsexec\\config.json"
    end
  end

  local f = io.open(config_file, "r")
  if not f then
    return {}
  end

  local raw_data = f:read("*a")
  f:close()

  local ok, json = pcall(vim.json.decode, raw_data)
  if not ok or not json or not json.agencies then
    return {}
  end

  local envs = {}

  for agency_name, agency_data in pairs(json.agencies) do
    if agency_data.environments then
      for env_name, _ in pairs(agency_data.environments) do
        table.insert(envs, {
          agency = agency_name,
          env = env_name,
          display = string.format("%s (%s)", env_name, agency_name)
        })
      end
    end
  end

  return envs
end

--- Render Telescope picker for choosing configured Accela environment targets
--- @param opts table|nil Telescope options
function M.picker(opts)
  opts = opts or {}
  local envs = M.discover_environments()

  if #envs == 0 then
    vim.notify("emse.nvim: No environments found in ~/.config/emsexec/config.json. Run 'emsexec config add' first.", vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = "Select Accela Environment",
    finder = finders.new_table({
      results = envs,
      entry_maker = function(entry)
        local is_active = (config.state.active_agency == entry.agency and config.state.active_env == entry.env)
        local display = entry.display
        if is_active then
          display = "* " .. display
        end
        return {
          value = entry,
          display = display,
          ordinal = entry.display,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          local item = selection.value
          config.state.active_agency = item.agency
          config.state.active_env = item.env
          vim.notify(string.format("emse.nvim: Switched target environment to %s:%s", item.agency, item.env), vim.log.levels.INFO)
        end
      end)
      return true
    end,
  }):find()
end

return M
