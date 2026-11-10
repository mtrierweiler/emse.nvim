local M = {}

--- Prompts for password in a centered floating modal window with masked input (`*`)
--- Handles typing, pasting, and backspacing with real-time masking
--- @param prompt_title string Title for the floating window
--- @param callback function Callback function(password_or_nil)
function M.prompt(prompt_title, callback)
  local buf = vim.api.nvim_create_buf(false, true)

  -- Calculate centered floating window dimensions
  local width = math.max(#prompt_title + 10, 50)
  local height = 1
  local row = math.floor((vim.o.lines - height) / 2) - 1
  col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " " .. (prompt_title or "Enter Accela Password") .. " ",
    title_pos = "center",
    footer = " [<Enter>]: Confirm | [<Esc>]: Cancel ",
    footer_pos = "center",
  })

  -- Window & Buffer options
  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat,FloatBorder:FloatBorder")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "undolevels", -1)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  local actual_password = ""
  local current_mask = ""
  local is_updating = false
  local is_done = false

  local function close_modal(confirmed)
    if is_done then return end
    is_done = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    
    local pwd = confirmed and actual_password or nil
    actual_password = ""
    current_mask = ""
    if callback then
      callback(pwd)
    end
  end

  -- Listen to buffer line modifications (typing AND pasting)
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(_, _, _, _, _, _)
      if is_updating or is_done then return end

      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) or is_done then return end
        
        local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
        local raw_line = lines[1] or ""

        -- Strip any stray newlines if pasted
        raw_line = raw_line:gsub("[\r\n]", "")

        if raw_line == current_mask then
          return
        end

        is_updating = true

        if #raw_line > #current_mask then
          -- User typed or pasted new character(s)
          if raw_line:sub(1, #current_mask) == current_mask then
            local added = raw_line:sub(#current_mask + 1)
            actual_password = actual_password .. added
          else
            -- Entire line replaced (e.g., visual paste)
            actual_password = raw_line
          end
        elseif #raw_line < #current_mask then
          -- User backspaced / deleted characters
          local deleted = #current_mask - #raw_line
          actual_password = actual_password:sub(1, math.max(0, #actual_password - deleted))
        else
          -- Replacement of same length
          actual_password = raw_line
        end

        current_mask = string.rep("*", #actual_password)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { current_mask })

        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_set_cursor(win, { 1, #current_mask })
        end

        is_updating = false
      end)
    end,
  })

  -- Start insert mode
  vim.cmd("startinsert!")

  local opts = { buffer = buf, silent = true, nowait = true }

  -- Confirm with Enter
  vim.keymap.set({ "n", "i" }, "<CR>", function()
    close_modal(true)
  end, opts)

  -- Cancel with Esc or Ctrl+C
  vim.keymap.set({ "n", "i" }, "<Esc>", function()
    close_modal(false)
  end, opts)

  vim.keymap.set({ "n", "i" }, "<C-c>", function()
    close_modal(false)
  end, opts)
end

return M