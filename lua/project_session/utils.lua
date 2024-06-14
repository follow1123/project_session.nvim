local M = {}

local is_windows = vim.fn.has("win32") == 1

---@param filetype string
---@return boolean
function M.match_visible_win(filetype)
  local win_list = vim.api.nvim_list_wins()
  for _, win_id in ipairs(win_list) do
    local bufnr = vim.api.nvim_win_get_buf(win_id)
    if filetype == vim.api.nvim_buf_get_option(bufnr, "filetype") then
      return true
    end
  end
  return false
end

---@return boolean
function M.is_empty_project()
  local all_bufs = vim.api.nvim_list_bufs()
  return #all_bufs == 1 and
    vim.fn.filereadable(vim.api.nvim_buf_get_name(all_bufs[1])) ~= 1
end

---replace path separator to %
---`/a/b/c` -> `%a%b%c`
---`C:/a/b/c` -> `C%%a%b%c` on windows
---@param path string
---@return string
function M.path2name(path)
  assert(vim.fn.isdirectory(path) == 1, "path not exists: " .. path)
  path = vim.fs.normalize(path)
  local pattern = is_windows and "[/:]" or "/"
  local session_name = string.gsub(path, pattern, "%%")
  return session_name
end

---restore path separator
---`%a%b%c` -> `/a/b/c`
---`C%%a%b%c` -> `C:/a/b/c` on windows
---@param name string
---@return string
function M.name2path(name)
  local path, count = string.gsub(name, "%%", "/")
  assert(count > 0, "name is not contains %")
  if is_windows then
    path = string.gsub(path, "//", ":/", 1)
  end
  return path
end

---find project root directory by patterns
---@param path string
---@param patterns table<string>
---@return string
function M.find_root(path, patterns)
  local results = vim.fs.find(patterns, {
    path = path,
    upward = true
  })
  path = (results and #results == 1) and results[1] or path
  return vim.fn.fnamemodify(path, ":h")
end

---@param path string
---@param data string|table<string>
function M.append_file(path, data)
  local uv = vim.uv or vim.loop
  local file, err, err_name = uv.fs_open(path, "a", 660)
  if not file or err or err_name then
    vim.notify("file open error: " .. err_name, vim.log.levels.WARN)
    return
  end
  uv.fs_write(file, data, -1, function(e)
    if e then
      vim.notify("file append error: " .. e, vim.log.levels.WARN)
    end
    uv.fs_close(file)
  end)
end


return M
