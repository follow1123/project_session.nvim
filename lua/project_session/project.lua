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

-- 保存session，只保存已存在的session
M.save_project = function(path)
  local session_dir = Config.options.dir
  local session_file = vim.fs.normalize(session_dir .. "/" .. Session.get_session_file_name(path))
  local result = vim.tbl_filter(function(file)
    return vim.fn.fnameescape(vim.fs.normalize(file)) == vim.fn.fnameescape(session_file)
  end, Session.list_sessions(session_dir))
  if result and #result > 0 then
    Session.save_session(session_file, Config.options.options)
    Config.mks_plugin(session_file)
  end
  vim.notify("project save to: " .. session_file, vim.log.levels.INFO)
  return session_file
end

-- 添加当前项目
M.add_project = function(path)
  local root_dir = M.find_root(path, Config.options.patterns)
  vim.api.nvim_set_current_dir(root_dir)

  local session_file = vim.fs.normalize(Config.options.dir .. "/" .. Session.get_session_file_name(root_dir))
  Session.save_session(session_file, Config.options.options)
  Config.mks_plugin(session_file)
  vim.notify("project add to: " .. session_file, vim.log.levels.INFO)
end

-- 检查是否有未保存的文件，并执行相关操作
-- @return is continue next option
M.check_unsaved_file = function ()

  local bufs = vim.api.nvim_list_bufs()
  local unsaved_files = ""

  -- 获取未保存的文件
  for _, bufnr in ipairs(bufs) do
    if vim.api.nvim_buf_get_option(bufnr, "modified") then
      local file_name = vim.api.nvim_buf_get_name(bufnr)
      if file_name then
        unsaved_files = unsaved_files .. file_name .. "\n"
      end
    end
  end

  -- 没有未保存的文件直接返回
  if vim.fn.empty(unsaved_files) == 1 then
    return true
  end

  -- 选择未保存文件的处理方式
  local choice = vim.fn.confirm(unsaved_files .. "these file not save", "&ok\n&save all\n&force open", 1)
  -- 全部保存
  if choice == 2 then
    vim.cmd(":wa")
    return true
  -- 不保存
  elseif choice == 3 then
    return true
  end

  -- 其他情况直接结束操作
  return false
end

-- 检查LSP服务是否关闭
-- TODO 切换到相同类型的项目时，lsp不会重新打开，需要打开一个新的buffer或则手动启动lsp服务
M.check_lsp = function ()
  local clients = vim.lsp.get_active_clients()
  for _, client in ipairs(clients) do
    if not vim.lsp.client_is_stopped(client.id) then
      vim.lsp.stop_client(client.id, false)
    end
  end
  return true
end

-- 打开项目前操作
M.before_open_project = function()
  return M.check_unsaved_file() and M.check_lsp()
end

-- 打开项目
M.open_project = function (path)

  -- 执行打开项目前操作
  local is_continue = M.before_open_project()

  if not is_continue then
    return
  end

  path = vim.fs.normalize(path)
  local stat = vim.loop.fs_stat(path)
  if not stat then
    vim.notify("error path: " .. path, vim.log.levels.WARN)
    return
  end
  local root_dir = M.find_root(path, Config.options.patterns)
  if not root_dir then
    vim.notify("not a project path: " .. path, vim.log.levels.WARN)
    return
  end
  M.add_project(path)
  vim.cmd("silent! %bwipeout!") -- 强制清空当前的所有buffer

  vim.api.nvim_set_current_dir(root_dir)

  if vim.fn.isdirectory(path) == 0 then
    vim.cmd("e " .. path)
    return
  end

  -- 如果使用打开项目目录的方式则使用对应的方式打开，否是使用netrw打开
  if type(Config.options.open_project_method) == "function" then
    Config.options.open_project_method(root_dir)
  else
    vim.cmd("E " .. path)
  end
end

return M
