-- Test Suite for emse.config options setups

describe("emse.config", function()
  local config = require("emse.config")

  before_each(function()
    config.setup({})
  end)

  it("should initialize default options correctly", function()
    assert.are.same(nil, config.defaults.bin_path)
    assert.are.same(true, config.defaults.auto_download)
    assert.are.same("float", config.defaults.output.layout)
    assert.are.same("rounded", config.defaults.output.border)
    assert.are.same(true, config.defaults.output.focus)
    assert.are.same("Always Rollback", config.defaults.execute_defaults.tx_mode)
    assert.are.same(nil, config.defaults.execute_defaults.init_script)
    assert.are.same("<cr>", config.defaults.telescope_mappings.initializers.edit)
    assert.are.same("s", config.defaults.telescope_mappings.initializers.select)
    assert.are.same("%", config.defaults.telescope_mappings.initializers.new)
    assert.are.same("D", config.defaults.telescope_mappings.initializers.delete)
    assert.are.same("<cr>", config.defaults.telescope_mappings.templates.edit)
    assert.are.same("s", config.defaults.telescope_mappings.templates.select)
    assert.are.same("%", config.defaults.telescope_mappings.templates.new)
    assert.are.same("D", config.defaults.telescope_mappings.templates.delete)
    assert.are.same("<cr>", config.defaults.telescope_mappings.scratchpads.edit)
    assert.are.same("%", config.defaults.telescope_mappings.scratchpads.new)
    assert.are.same("D", config.defaults.telescope_mappings.scratchpads.delete)
  end)

  it("should initialize state mirroring defaults", function()
    assert.are.same(nil, config.state.active_agency)
    assert.are.same(nil, config.state.active_env)
    assert.are.same("Always Rollback", config.state.tx_mode)
    assert.are.same(nil, config.state.init_script)
    assert.are.same(nil, config.state.active_template)
  end)

  it("should support custom configuration overrides", function()
    config.setup({
      bin_path = "/usr/custom/bin/emsexec",
      auto_download = false,
      output = {
        layout = "split",
        border = "double",
        focus = false,
      },
      execute_defaults = {
        tx_mode = "Commit If Successful",
        init_script = "/global/init.js"
      }
    })

    assert.are.same("/usr/custom/bin/emsexec", config.defaults.bin_path)
    assert.are.same(false, config.defaults.auto_download)
    assert.are.same("split", config.defaults.output.layout)
    assert.are.same("double", config.defaults.output.border)
    assert.are.same(false, config.defaults.output.focus)

    assert.are.same("Commit If Successful", config.state.tx_mode)
    assert.are.same("/global/init.js", config.state.init_script)
  end)

  it("should allow runtime updates to state without touching defaults", function()
    config.state.active_agency = "TEST_AGENCY"
    config.state.active_env = "PROD"

    assert.are.same("TEST_AGENCY", config.state.active_agency)
    assert.are.same("PROD", config.state.active_env)

    -- Assert defaults still have base layout properties
    assert.are.same(nil, config.defaults.bin_path)
  end)
end)