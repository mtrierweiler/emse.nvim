local M = {}
local config = require("emse.config")

-- Track the buffer and window handles
M.buf = nil
M.win = nil

--- Create or retrieve the custom interactive output buffer
--- @return number Buffer number
local function get_or_create_buf()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    return M.buf
  end

  M.buf = vim.api.nvim_create_buf(false, true) -- listed = false, scratch/scratchpad = true
  vim.api.nvim_buf_set_name(M.buf, "EMSE Execution Output")

  -- Set buffer specific options
  vim.api.nvim_buf_set_option(M.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(M.buf, "swapfile", false)
  vim.api.nvim_buf_set_option(M.buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(M.buf, "buflisted", false)
  vim.api.nvim_buf_set_option(M.buf, "undolevels", -1)
  vim.api.nvim_buf_set_option(M.buf, "modeline", false)

  -- Register keymaps inside the log buffer
  local opts = { silent = true, buffer = M.buf }

  -- 'q' to close the output window
  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)

  -- 'c' to clear the output logs
  vim.keymap.set("n", "c", function()
    M.clear()
  end, opts)

  -- 'y' to copy logs into Neovim's clipboard register
  vim.keymap.set("n", "y", function()
    local lines = vim.api.nvim_buf_get_lines(M.buf, 0, -1, false)
    vim.fn.setreg("+", table.concat(lines, "\n"))
    vim.notify("emse.nvim: Copied execution logs to clipboard", vim.log.levels.INFO)
  end, opts)

  -- Setup basic syntax highlight pattern definitions
  vim.api.nvim_create_autocmd("FileType", {
    buffer = M.buf,
    callback = function()
      vim.cmd([[
        syntax clear
        syntax match EmseLogInfo /^\[INFO\].*/
        syntax match EmseLogError /^\[ERROR\].*/
        syntax match EmseLogDebug /^\[DEBUG\].*/
        syntax match EmseLogSuccess /.*SUCCESS.*/
        syntax match EmseLogRollback /.*ROLLBACK.*/
        syntax match EmseLogCommit /.*COMMIT.*/

        highlight default link EmseLogInfo DiagnosticInfo
        highlight default link EmseLogError DiagnosticError
        highlight default link EmseLogDebug DiagnosticHint
        highlight default link EmseLogSuccess DiagnosticOk
        highlight default link EmseLogRollback DiagnosticWarn
        highlight default link EmseLogCommit DiagnosticOk
      ]])
    end
  })

  vim.api.nvim_buf_set_option(M.buf, "filetype", "emse-output")

  return M.buf
end

--- Close the active output window if open
function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
  end
end

--- Clear the log outputs buffer
function M.clear()
  local buf = get_or_create_buf()
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "--- EMSE Execution Output ---",
    "",
  })
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

--- Append log strings safely to the log output buffer
--- @param content string|table Lines of string to append
function M.append(content)
  local buf = get_or_create_buf()
  local lines = type(content) == "table" and content or vim.split(content, "[\r\n]")

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  -- Remove trailing empty logs
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines, #lines)
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Auto-scroll to the bottom of the window
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    local new_line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(M.win, { new_line_count, 0 })
  end
end

--- Open and render the output window depending on the configured layout style
function M.open()
  local buf = get_or_create_buf()

  -- If window is already valid, just refocus if layout allows
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    if config.defaults.output.focus then
      vim.api.nvim_set_current_win(M.win)
    end
    return
  end

  local layout = config.defaults.output.layout

  if layout == "float" then
    -- Center float layout sizes
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    M.win = vim.api.nvim_open_win(buf, config.defaults.output.focus, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      border = config.defaults.output.border,
      title = " EMSE Output Logs ",
      title_pos = "center",
      footer = " [q]: Close  |  [c]: Clear  |  [y]: Copy Logs ",
      footer_pos = "center",
    })
    
    -- Explicitly link the floating window highlights to Standard Telescope Normal Float highlights
    -- NormalFloat is used for background color, FloatBorder for borders.
    vim.api.nvim_win_set_option(M.win, "winhl", "Normal:NormalFloat,FloatBorder:FloatBorder")
  elseif layout == "split" then
    vim.cmd("split")
    M.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.win, buf)
    vim.api.nvim_win_set_height(M.win, math.floor(vim.o.lines * 0.3))
  elseif layout == "vsplit" then
    vim.cmd("vsplit")
    M.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.win, buf)
    vim.api.nvim_win_set_width(M.win, math.floor(vim.o.columns * 0.4))
  end

  -- Enable standard window options
  vim.api.nvim_win_set_option(M.win, "wrap", true)
  vim.api.nvim_win_set_option(M.win, "number", false)
  vim.api.nvim_win_set_option(M.win, "relativenumber", false)
end

return M