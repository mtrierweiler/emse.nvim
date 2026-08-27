-- Test Suite for UI Log Buffers and Interactive Highlights

describe("emse.ui", function()
  local ui = require("emse.ui")
  local config = require("emse.config")

  before_each(function()
    config.setup({})
    ui.close()
    if ui.buf and vim.api.nvim_buf_is_valid(ui.buf) then
      vim.api.nvim_buf_delete(ui.buf, { force = true })
    end
    ui.buf = nil
    ui.win = nil
  end)

  after_each(function()
    ui.close()
  end)

  it("should lazily instantiate and initialize output buffer", function()
    ui.open()
    assert.are_not.same(nil, ui.buf)
    assert.truthy(vim.api.nvim_buf_is_valid(ui.buf))

    -- Check buffer options
    local buftype = vim.api.nvim_buf_get_option(ui.buf, "buftype")
    local swapfile = vim.api.nvim_buf_get_option(ui.buf, "swapfile")
    local filetype = vim.api.nvim_buf_get_option(ui.buf, "filetype")

    assert.are.same("nofile", buftype)
    assert.are.same(false, swapfile)
    assert.are.same("emse-output", filetype)
  end)

  it("should open window according to layout options", function()
    config.setup({ output = { layout = "float", border = "single" } })
    ui.open()

    assert.are_not.same(nil, ui.win)
    assert.truthy(vim.api.nvim_win_is_valid(ui.win))

    local config_got = vim.api.nvim_win_get_config(ui.win)
    assert.are.same("editor", config_got.relative)
  end)

  it("should append execution logs safely and scroll to bottom", function()
    ui.open()
    ui.clear()

    ui.append("Test output 1")
    ui.append({ "Test output 2", "Test output 3" })

    local lines = vim.api.nvim_buf_get_lines(ui.buf, 0, -1, false)
    -- Total lines: header line + blank + 3 appended logs
    assert.are.same(5, #lines)
    assert.are.same("Test output 1", lines[3])
    assert.are.same("Test output 2", lines[4])
    assert.are.same("Test output 3", lines[5])
  end)

  it("should support clearing active output logs", function()
    ui.open()
    ui.append("Discard me")
    ui.clear()

    local lines = vim.api.nvim_buf_get_lines(ui.buf, 0, -1, false)
    assert.are.same(2, #lines)
    assert.are.same("--- EMSE Execution Output ---", lines[1])
  end)
end)
