local Session = require("project_session.session")
local Config = require("project_session.config")

local M = {}

-- 根据文件路径查找项目root
M.find_root = function(path, patterns)
  local results = vim.fs.find(patterns, {
    path = path,
    upward = true
  })
  path = (results and #results == 1) and results[1] or path
  return vim.fn.fnamemodify(path, ":h")
end

-- 最近打开的项目列表
M.recent_projects = function()
  local sessions = Session.list_sessions(Config.options.dir)
  table.sort(sessions, function(a, b)
    return vim.loop.fs_stat(a).mtime.sec > vim.loop.fs_stat(b).mtime.sec
  end)
  return sessions
end

-- 删除项目，直接删除对应的session文件
M.delete_project = function(file)
  vim.fn.delete(file)
end

-- 添加当前项目
M.add_project = function()
  local root_dir = M.find_root(vim.fn.getcwd(), Config.options.patterns)
  vim.api.nvim_set_current_dir(root_dir)

  local session_file = vim.fs.normalize(Config.options.dir .. "/" .. Session.get_session_file_name(root_dir))
  Session.save_session(session_file, Config.options.options)
end

return M
