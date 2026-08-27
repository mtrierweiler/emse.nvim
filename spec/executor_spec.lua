-- Test Suite for emse.executor arguments building

describe("emse.executor", function()
  local config = require("emse.config")
  local executor = require("emse.executor")
  local installer = require("emse.installer")

  -- Safe execution paths spy definitions
  local system_calls = {}
  local original_system
  local original_find_bin

  before_each(function()
    system_calls = {}
    config.setup({})
    original_system = vim.system
    original_find_bin = installer.find_binary

    -- Mock find_binary
    installer.find_binary = function()
      return "/usr/local/bin/emsexec"
    end

    -- Mock vim.system to inspect spawned args asynchronously
    vim.system = function(cmd, opts, callback)
      table.insert(system_calls, { cmd = cmd, opts = opts })
      -- Trigger asynchronous callback immediately in test scope
      if callback then
        callback({ code = 0, stdout = "Mock Output", stderr = "" })
      end
      return {}
    end
  end)

  after_each(function()
    vim.system = original_system
    installer.find_binary = original_find_bin
  end)

  it("should construct minimum execution arguments", function()
    -- Create dummy target script
    local path = vim.fn.tempname() .. ".js"
    local f = io.open(path, "w")
    f:write("// Sample")
    f:close()

    executor.run_file_path(path)

    assert.are.same(1, #system_calls)
    local called = system_calls[1].cmd

    assert.are.same("/usr/local/bin/emsexec", called[1])
    assert.are.same("run", called[2])
    assert.are.same(path, called[3])

    os.remove(path)
  end)

  it("should append agency and environment flags if set in active state", function()
    local path = vim.fn.tempname() .. ".js"
    local f = io.open(path, "w")
    f:write("// Sample")
    f:close()

    config.state.active_agency = "SANDBOX"
    config.state.active_env = "DEV"

    executor.run_file_path(path)

    local called = system_calls[1].cmd
    assert.are.same("--agency", called[4])
    assert.are.same("SANDBOX", called[5])
    assert.are.same("--env", called[6])
    assert.are.same("DEV", called[7])

    os.remove(path)
  end)

  it("should append commit transactions flags if active", function()
    local path = vim.fn.tempname() .. ".js"
    local f = io.open(path, "w")
    f:write("// Sample")
    f:close()

    config.state.tx_mode = "Commit If Successful"

    executor.run_file_path(path)

    local called = system_calls[1].cmd
    -- Confirm --commit is passed
    local has_commit = false
    for _, arg in ipairs(called) do
      if arg == "--commit" then has_commit = true end
    end
    assert.truthy(has_commit)

    os.remove(path)
  end)

  it("should append user-tx transaction flags if active", function()
    local path = vim.fn.tempname() .. ".js"
    local f = io.open(path, "w")
    f:write("// Sample")
    f:close()

    config.state.tx_mode = "Use User Transaction"

    executor.run_file_path(path)

    local called = system_calls[1].cmd
    -- Confirm --user-tx is passed
    local has_user_tx = false
    for _, arg in ipairs(called) do
      if arg == "--user-tx" then has_user_tx = true end
    end
    assert.truthy(has_user_tx)

    os.remove(path)
  end)

  it("should inject init script path parameter if set in active state", function()
    local path = vim.fn.tempname() .. ".js"
    local f = io.open(path, "w")
    f:write("// Sample")
    f:close()

    config.state.init_script = "/tmp/my_init.js"

    executor.run_file_path(path)

    local called = system_calls[1].cmd
    local init_idx = nil
    for idx, arg in ipairs(called) do
      if arg == "--init" then init_idx = idx end
    end

    assert.truthy(init_idx)
    assert.are.same("/tmp/my_init.js", called[init_idx + 1])

    os.remove(path)
  end)
end)