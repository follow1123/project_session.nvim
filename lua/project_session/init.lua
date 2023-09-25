local Session = require("project_session.session")
local Config = require("project_session.config")
local Project = require("project_session.project")
local M = {}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, Config.options, opts or {})
  if vim.fn.isdirectory(M.options.dir) == 0 then
    vim.fn.mkdir(M.options.dir, "p")
  end
  M.start()
end

-- 加载上次的session
M.load_last = function()
  local sessions = Session.list_sessions(Config.options.dir)
  if not sessions or #sessions == 0 then
    vim.notify("no sessions", vim.log.levels.WARN)
    return
  end
  table.sort(sessions, function(a, b)
    return vim.loop.fs_stat(a).mtime.sec > vim.loop.fs_stat(b).mtime.sec
  end)
  Session.load_session(sessions[1])
end

-- 保存session，只保存已存在的session
M.save = function()
  Project.save_project(vim.fn.getcwd())
end

-- 添加项目
M.add = function ()
  Project.add_project(vim.fn.getcwd())
end

-- 打开项目
M.open = function()
  vim.ui.input({ prompt = "input project path", }, function(path)
    if path then
      Project.open_project(path)
    end
  end)
end

-- 开启保存session的操作
M.start = function()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("project_session", { clear = true }),
    callback = M.save
  })
end

-- 关闭保存session的操作
M.stop = function()
  pcall(vim.api.nvim_del_augroup_by_name, "project_session")
end

-- 添加当前项目到项目列表
vim.api.nvim_create_user_command("ProjectAdd", Project.add_project, {
  desc = "add current project to list"
})

vim.api.nvim_create_user_command("ProjectOpen", function(o)
  Project.open_project(o.args)
end, {
    desc = "add current project to list",
    nargs = "?"
  })

return M
