local M = {}
local config = require("emse.config")

--- Open a file path in a comfortable floating buffer editor
--- @param file_path string Path to scratchpad JavaScript file
function M.edit_file(file_path)
  -- Add and load the file naturally as a standard Neovim buffer
  -- This ensures standard :w and :wq commands work perfectly without overrides
  local buf = vim.fn.bufadd(file_path)
  vim.fn.bufload(buf)
  vim.api.nvim_buf_set_option(buf, "buflisted", true)

  -- Create comfortable center floating window
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = config.defaults.output.border or "rounded",
    title = " EMSE Scratchpad: " .. vim.fn.fnamemodify(file_path, ":t:r") .. " ",
    title_pos = "center",
  })

  -- Enable editor standard features inside the float
  vim.api.nvim_win_set_option(win, "number", true)
  vim.api.nvim_win_set_option(win, "wrap", true)

  -- Notify user on save
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = buf,
    callback = function()
      vim.notify("emse.nvim: Scratchpad saved.", vim.log.levels.INFO)
    end
  })

  -- Clear buffer on hidden/unloaded to avoid name clashes
  vim.api.nvim_create_autocmd({ "BufHidden" }, {
    buffer = buf,
    callback = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end
  })
end

--- Create a new empty scratchpad and immediately open it
--- @param name string Base name of file without extension
--- @return string|nil Saved scratchpad path
function M.create_new(name)
  if not name or name == "" then
    return nil
  end

  -- Ensure name has a .js extension
  if not string.find(name, "%.js$") then
    name = name .. ".js"
  end

  local scratchpad_dir = config.get_scratchpad_dir()
  local file_path = scratchpad_dir .. "/" .. name

  -- Create file with minimal header if it doesn't exist
  if vim.fn.filereadable(file_path) == 0 then
    local f = io.open(file_path, "w")
    if f then
      f:write("// EMSE Isolated Scratchpad: " .. name .. "\n")
      f:write("// Code written here executes independently (without active initializers or templates)\n\n")
      f:close()
    end
  end

  M.edit_file(file_path)
  return file_path
end

return M