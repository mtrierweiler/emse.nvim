-- Test Suite for emse.nvim binary detection and installer module

describe("emse.installer", function()
  local installer = require("emse.installer")
  local config = require("emse.config")

  before_each(function()
    config.setup({})
  end)

  it("should return the correct system path properties", function()
    local paths = installer.get_paths()
    local expected_install_dir = vim.fn.stdpath("data") .. "/emse-nvim/bin"

    assert.are.same(nil, paths.custom)
    assert.are.same(expected_install_dir, paths.install_dir)
    assert.are_not.same(nil, paths.binary_name)
    assert.are_not.same(nil, paths.install_path)
  end)

  it("should respect the custom configuration path if valid", function()
    -- Set a custom executable
    config.setup({ bin_path = "/usr/bin/emsexec" })

    -- Mock vim.fn.executable so /usr/bin/emsexec is treated as valid
    local original_executable = vim.fn.executable
    vim.fn.executable = function(path)
      if path == "/usr/bin/emsexec" then
        return 1
      end
      return 0
    end

    local path = installer.find_binary()
    assert.are.same("/usr/bin/emsexec", path)

    -- Restore executable mock
    vim.fn.executable = original_executable
  end)

  it("should prioritize local installer bin if present and custom is invalid", function()
    -- Mock vim.fn.executable
    local original_executable = vim.fn.executable
    local paths = installer.get_paths()

    vim.fn.executable = function(path)
      if path == paths.install_path then
        return 1
      end
      return 0
    end

    local path = installer.find_binary()
    assert.are.same(paths.install_path, path)

    -- Restore executable mock
    vim.fn.executable = original_executable
  end)
end)
