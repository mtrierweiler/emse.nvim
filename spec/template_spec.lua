-- Test Suite for EMSE Templates

describe("emse.template", function()
  local config = require("emse.config")
  local template = require("emse.template")

  before_each(function()
    config.setup({})
  end)

  it("should resolve the templates cached directory safely", function()
    local dir = config.get_template_dir()
    assert.are_not.same(nil, dir)
    assert.truthy(vim.fn.isdirectory(dir) == 1)
  end)

  it("should format file paths correctly and write defaults for new templates", function()
    local test_name = "test_mock_template"
    local expected_path = config.get_template_dir() .. "/" .. test_name .. ".js"

    -- Clean up if existed previously
    if vim.fn.filereadable(expected_path) == 1 then
      os.remove(expected_path)
    end

    -- Temporarily mock edit_file to bypass opening interactive float windows
    local original_edit = template.edit_file
    template.edit_file = function(_) end

    local created_path = template.create_new(test_name)

    assert.are.same(expected_path, created_path)
    assert.truthy(vim.fn.filereadable(created_path) == 1)

    -- Read written default header
    local f = io.open(created_path, "r")
    assert.truthy(f)
    local line1 = f:read("*l")
    f:close()

    assert.truthy(string.find(line1, "EMSE Accela Template"))

    -- Restore mocked edit
    template.edit_file = original_edit
    os.remove(created_path)
  end)
end)