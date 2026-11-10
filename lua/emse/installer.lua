local M = {}

--- Get the system OS and CPU Architecture
--- @return string, string OS string, Arch string
local function get_system_info()
  local os_name = vim.loop.os_uname().sysname
  local arch = vim.loop.os_uname().machine

  -- Normalize OS
  if os_name == "Linux" then
    os_name = "linux"
  elseif os_name == "Darwin" then
    os_name = "macos"
  elseif string.find(os_name, "Windows") then
    os_name = "windows"
  else
    os_name = string.lower(os_name)
  end

  -- Normalize Architecture
  if arch == "x86_64" or arch == "amd64" then
    arch = "x64"
  elseif arch == "arm64" or arch == "aarch64" then
    arch = "arm64"
  end

  return os_name, arch
end

--- Determine the release asset filename based on OS and architecture
--- @param os string
--- @param arch string
--- @return string|nil Asset name, or nil if unsupported
local function get_asset_name(os, arch)
  if os == "linux" and arch == "x64" then
    return "emsexec-linux-x64"
  elseif os == "macos" then
    if arch == "arm64" then
      return "emsexec-macos-arm64"
    else
      return "emsexec-macos-x64"
    end
  elseif os == "windows" and arch == "x64" then
    return "emsexec-windows-x64.exe"
  end
  return nil
end

--- Get paths where emsexec might live or should be installed
--- @return table Paths containing local bin dir, global path bin, and download target
function M.get_paths()
  local config = require("emse.config")
  local data_path = vim.fn.stdpath("data")
  local install_dir = data_path .. "/emse-nvim/bin"
  local binary_name = vim.loop.os_uname().sysname:find("Windows") and "emsexec.exe" or "emsexec"
  local install_path = install_dir .. "/" .. binary_name

  return {
    custom = config.defaults.bin_path,
    install_dir = install_dir,
    install_path = install_path,
    binary_name = binary_name,
  }
end

--- Find the path to the valid emsexec binary
--- @return string|nil Path to working binary, or nil if none found
function M.find_binary()
  local paths = M.get_paths()

  -- 1. Check custom configured path
  if paths.custom and vim.fn.executable(paths.custom) == 1 then
    return paths.custom
  end

  -- 2. Check local plugin auto-installed path
  if vim.fn.executable(paths.install_path) == 1 then
    return paths.install_path
  end

  -- 3. Check system wide path
  if vim.fn.executable(paths.binary_name) == 1 then
    return paths.binary_name
  end

  return nil
end

--- Calculate SHA-256 digest for a file on disk
--- @param file_path string Path to file
--- @return string|nil Hex SHA-256 string, or nil if unreadable
function M.compute_file_sha256(file_path)
  local f = io.open(file_path, "rb")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return vim.fn.sha256(content)
end

--- Download and install the emsexec binary from GitHub releases asynchronously
--- @param callback function|nil Callback called with (success, err_msg)
function M.install(callback)
  local paths = M.get_paths()
  local os_name, arch = get_system_info()
  local asset = get_asset_name(os_name, arch)

  if not asset then
    local err = string.format("Unsupported system architecture: %s %s", os_name, arch)
    if callback then callback(false, err) else vim.notify(err, vim.log.levels.ERROR) end
    return
  end

  -- Ensure target directory exists
  vim.fn.mkdir(paths.install_dir, "p")

  -- We pull the latest tag dynamically by letting GitHub redirect us to latest
  local url = string.format("https://github.com/mtrierweiler/emsexec/releases/latest/download/%s", asset)
  local checksum_url = "https://github.com/mtrierweiler/emsexec/releases/latest/download/checksums.txt"
  local checksum_file = paths.install_dir .. "/checksums.txt"

  vim.notify("emse.nvim: Downloading emsexec binary...", vim.log.levels.INFO)

  -- Use curl to download the binary
  local download_cmd = {
    "curl",
    "-sL",
    "-o",
    paths.install_path,
    url
  }

  vim.system(download_cmd, {}, function(obj)
    if obj.code ~= 0 then
      local err = "Failed to download binary: " .. (obj.stderr or "")
      vim.schedule(function()
        if callback then callback(false, err) else vim.notify(err, vim.log.levels.ERROR) end
      end)
      return
    end

    -- Attempt to fetch checksums.txt for SHA-256 verification
    vim.system({ "curl", "-sL", "-o", checksum_file, checksum_url }, {}, function(cs_obj)
      local verified = false
      if cs_obj.code == 0 and vim.fn.filereadable(checksum_file) == 1 then
        local f = io.open(checksum_file, "r")
        if f then
          local cs_content = f:read("*a")
          f:close()
          os.remove(checksum_file)

          local computed = M.compute_file_sha256(paths.install_path)
          for line in cs_content:gmatch("[^\r\n]+") do
            local hash, filename = line:match("(%x+)%s+(%S+)")
            if filename == asset and computed then
              if hash:lower() == computed:lower() then
                verified = true
              else
                os.remove(paths.install_path)
                local err = string.format("Security verification failed! SHA-256 hash mismatch for %s", asset)
                vim.schedule(function()
                  if callback then callback(false, err) else vim.notify(err, vim.log.levels.ERROR) end
                end)
                return
              end
            end
          end
        end
      end

      -- Make it executable (Linux / macOS)
      if os_name ~= "windows" then
        -- Use os.execute or vim.uv.fs_chmod, as vim.fn.system cannot be called inside fast event callbacks
        pcall(function()
          vim.uv.fs_chmod(paths.install_path, 493) -- 493 decimal is 0o755 octal (rwxr-xr-x)
        end)
      end

      vim.schedule(function()
        if verified then
          vim.notify("emse.nvim: Installation completed successfully! (SHA-256 Verified)", vim.log.levels.INFO)
        else
          vim.notify("emse.nvim: Installation completed successfully!", vim.log.levels.INFO)
        end
        if callback then callback(true, nil) end
      end)
    end)
  end)
end

return M
