local M = {}
local config = require("emse.config")
local installer = require("emse.installer")
local ui = require("emse.ui")

--- Write visual selection string or current buffers to a temporary JavaScript file
--- @param lines table Array of source code lines
--- @return string Target file path
local function write_temp_script(lines)
  local temp_path = vim.fn.tempname() .. ".js"
  local f = io.open(temp_path, "w")
  if f then
    f:write(table.concat(lines, "\n"))
    f:close()
  end
  return temp_path
end

--- Execute a target script or command asynchronously using emsexec
--- @param target_path string Path to target JavaScript file
--- @param is_temp boolean Whether the target is a temp file that needs cleanup
--- @param bypass_inits boolean Whether to bypass any active init_script or active_template
local function execute_run(target_path, is_temp, bypass_inits)
  local binary = installer.find_binary()

  if not binary then
    if config.defaults.auto_download then
      vim.ui.select({ "Yes", "No" }, {
        prompt = "emsexec binary is required but not found. Install it now?"
      }, function(choice)
        if choice == "Yes" then
          installer.install(function(success, err)
            if success then
              execute_run(target_path, is_temp, bypass_inits)
            end
          end)
        else
          if is_temp then os.remove(target_path) end
        end
      end)
    else
      vim.notify("emse.nvim: emsexec binary is missing from your PATH. Setup bin_path or enable auto_download.", vim.log.levels.ERROR)
      if is_temp then os.remove(target_path) end
    end
    return
  end

  local state = config.state

  -- Build command args array
  local args = { "run", target_path }

  -- Inject environment coordinates if active
  if state.active_agency and state.active_env then
    table.insert(args, "--agency")
    table.insert(args, state.active_agency)
    table.insert(args, "--env")
    table.insert(args, state.active_env)
  end

  -- Determine transaction flags based on verbatim selected state.tx_mode
  if state.tx_mode == "Commit If Successful" then
    table.insert(args, "--commit")
  elseif state.tx_mode == "Use User Transaction" then
    table.insert(args, "--user-tx")
  end
  -- Note: "Always Rollback" passes neither of these flags, enforcing rollback default.

  -- Determine if we are running in scratchpad mode (bypasses initializers and templates)
  local scratchpad_dir = config.get_scratchpad_dir()
  local is_scratchpad = bypass_inits or (target_path:sub(1, #scratchpad_dir) == scratchpad_dir)

  if not is_scratchpad then
    if state.init_script then
      table.insert(args, "--init")
      table.insert(args, state.init_script)
    end
  end

  -- Open the output log interface and prepare logs
  ui.open()
  ui.clear()
  ui.append(string.format("[INFO] Starting Execution: %s", vim.fn.fnamemodify(target_path, ":t")))
  ui.append(string.format("[INFO] Target: %s (%s)", state.active_agency or "(default)", state.active_env or "(default)"))
  ui.append(string.format("[INFO] Database Transaction Mode: %s", state.tx_mode))
  
  if is_scratchpad then
    ui.append("[INFO] Scratchpad Mode: Initializers & Templates Bypassed")
  else
    if state.init_script then
      ui.append(string.format("[INFO] Loaded Init Script: %s", state.init_script))
    end
    if state.active_template then
      ui.append(string.format("[INFO] Active Template (Placeholder): %s", state.active_template))
    end
  end
  ui.append("------------------------------------------")

  -- Asynchronously run emsexec
  vim.system({ binary, unpack(args) }, {
    text = true,
  }, function(obj)
    -- Cleanup visual selections / temporary scripts safely
    if is_temp then
      os.remove(target_path)
    end

    -- Format standard output streams
    vim.schedule(function()
      if obj.stdout and obj.stdout ~= "" then
        ui.append(obj.stdout)
      end

      if obj.stderr and obj.stderr ~= "" then
        ui.append(obj.stderr)
      end

      if obj.code == 0 then
        ui.append("[SUCCESS] Execution Completed Successfully.")
      else
        ui.append(string.format("[ERROR] Execution Failed with Code %d.", obj.code))
      end
    end)
  end)
end

--- Execute the currently focused Neovim buffer/file
function M.run_current_file()
  local file_path = vim.api.nvim_buf_get_name(0)
  if file_path == "" then
    vim.notify("emse.nvim: Active buffer has no file path saved.", vim.log.levels.ERROR)
    return
  end

  -- Check if file is a Javascript file
  if vim.bo.filetype ~= "javascript" and vim.fn.fnamemodify(file_path, ":e") ~= "js" then
    vim.notify("emse.nvim: Only Javascript (*.js) scripts are supported.", vim.log.levels.WARN)
    return
  end

  -- Save file before run if modified
  if vim.bo.modified then
    vim.cmd("write")
  end

  execute_run(file_path, false, false)
end

--- Execute a specific file path
--- @param file_path string Target script file path
function M.run_file_path(file_path)
  if vim.fn.filereadable(file_path) == 0 then
    vim.notify("emse.nvim: Script file is unreadable or does not exist: " .. file_path, vim.log.levels.ERROR)
    return
  end
  execute_run(file_path, false, false)
end

--- Execute selected code blocks directly
function M.run_visual_selection()
  -- Extract start and end selection indexes
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  local file_path = vim.api.nvim_buf_get_name(0)
  local scratchpad_dir = config.get_scratchpad_dir()
  local is_scratchpad = file_path ~= "" and (file_path:sub(1, #scratchpad_dir) == scratchpad_dir)

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    vim.notify("emse.nvim: Empty visual selection.", vim.log.levels.WARN)
    return
  end

  -- Write lines to isolated temporary script
  local temp_path = write_temp_script(lines)
  execute_run(temp_path, true, is_scratchpad)
end

return M