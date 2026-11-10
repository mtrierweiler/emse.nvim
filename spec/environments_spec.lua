package.path = package.path .. ";/tmp/telescope.nvim/lua/?.lua;/tmp/telescope.nvim/lua/?/init.lua"

-- Test Suite for EMSE Environment discovery and selection

describe("emse.telescope.environments", function()
  local config = require("emse.config")
  local environments = require("emse.telescope.environments")

  before_each(function()
    config.setup({})
  end)

  it("should format active environment display entries with an asterisk marker", function()
    config.state.active_agency = "CITY_DEV"
    config.state.active_env = "STAGE"

    local entry1 = { agency = "CITY_DEV", env = "STAGE", display = "STAGE (CITY_DEV)" }
    local entry2 = { agency = "CITY_DEV", env = "PROD", display = "PROD (CITY_DEV)" }

    local is_active1 = (config.state.active_agency == entry1.agency and config.state.active_env == entry1.env)
    local display1 = entry1.display
    if is_active1 then
      display1 = "* " .. display1
    end

    local is_active2 = (config.state.active_agency == entry2.agency and config.state.active_env == entry2.env)
    local display2 = entry2.display
    if is_active2 then
      display2 = "* " .. display2
    end

    assert.are.same("* STAGE (CITY_DEV)", display1)
    assert.are.same("PROD (CITY_DEV)", display2)
  end)

  it("should update config state when an environment is selected", function()
    config.state.active_agency = nil
    config.state.active_env = nil

    local item = { agency = "COUNTY_AGENCY", env = "DEV" }

    -- Simulate selection action in Telescope picker callback
    config.state.active_agency = item.agency
    config.state.active_env = item.env

    assert.are.same("COUNTY_AGENCY", config.state.active_agency)
    assert.are.same("DEV", config.state.active_env)
  end)

  it("should discover environments from emsexec config json", function()
    local temp_home = vim.fn.tempname()
    local config_dir = temp_home .. "/.config/emsexec"
    vim.fn.mkdir(config_dir, "p")

    local config_file = config_dir .. "/config.json"
    local f = io.open(config_file, "w")
    assert.truthy(f)
    f:write([[
    {
      "agencies": {
        "TEST_AGENCY": {
          "environments": {
            "DEV": {},
            "PROD": {}
          }
        }
      }
    }
    ]])
    f:close()

    local original_getenv = os.getenv
    os.getenv = function(var)
      if var == "HOME" or var == "USERPROFILE" then
        return temp_home
      end
      return original_getenv(var)
    end

    local envs = environments.discover_environments()
    os.getenv = original_getenv
    vim.fn.delete(temp_home, "rf")

    assert.are.same(2, #envs)
    local found_dev = false
    local found_prod = false
    for _, e in ipairs(envs) do
      if e.agency == "TEST_AGENCY" and e.env == "DEV" then found_dev = true end
      if e.agency == "TEST_AGENCY" and e.env == "PROD" then found_prod = true end
    end
    assert.truthy(found_dev)
    assert.truthy(found_prod)
  end)
end)