local M = {}

local is_windows = vim.fn.has("win32") == 1

-- 将项目路径解析为session文件名
M.get_session_file_name = function(dir)
  dir = vim.fs.normalize(dir)
  local pattern = is_windows and "[/:]" or "/"
  local session_name = string.gsub(dir, pattern, "%%")
  return session_name .. ".vim"
end

-- 将session名称还原成项目路径
M.parse_session_file = function(session_file)
  local session_name = vim.fn.fnamemodify(session_file, ":t")
  session_name = string.gsub(session_name, "%%", "/")
  if is_windows then
    session_name = string.gsub(session_name, "//", ":/", 1)
  end
  session_name = string.gsub(session_name, ".vim$", "")
  return session_name
end

-- 保存session
M.save_session = function(session_file, session_opts)
  local def_opts = vim.opt.sessionoptions
  if type(session_opts) == "table" and #session_opts ~= 0 then
    vim.opt.sessionoptions = session_opts
  end
  vim.cmd("mks! " .. vim.fn.fnameescape(session_file))
  vim.opt.sessionoptions = def_opts
end

-- 加载session
M.load_session = function(session_file)
  if not session_file or vim.fn.filereadable(session_file) == 0 then
    vim.notify("session file is nil or is not readable!", vim.log.levels.WARN)
    return
  end
  vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
end

-- session文件列表
M.list_sessions = function(session_dir)
  return vim.fn.glob(session_dir .. "*.vim", true, true)
end

return M
