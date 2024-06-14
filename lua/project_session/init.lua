local config = require("project_session.config")
local core = require("project_session.core")

local M = {}

---@param opts ProjectSessionOpts?
function M.setup(opts)
  config.setup(opts)
  if vim.fn.isdirectory(config.options.dir) == 0 then
    vim.fn.mkdir(config.options.dir, "p")
  end
  M.start()
end

---load last project
function M.load_last()
  local projects = core.list_projects()
  if vim.fn.empty(projects) == 1 then
    vim.notify("no projects", vim.log.levels.WARN)
    return
  end
  core.open_project(projects[1])
end

---save session only save existing session
function M.save() core.save_project() end

---add project
M.add = core.add_project


---open project
function M.open()
  vim.ui.input(
    {
      prompt = "Input project path: ",
      completion = "file",
      kind = "projectsession"
    },
    function(path)
      if not path or vim.fn.empty(vim.trim(path)) == 1 then return end
      path = vim.fn.fnamemodify(path, ":p")
      core.open_project(path)
    end)
end

---enable session saving
function M.start()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("project_session", { clear = true }),
    callback = M.save
  })
end

---disable session saving
function M.stop()
  pcall(vim.api.nvim_del_augroup_by_name, "project_session")
end

---add to project list
vim.api.nvim_create_user_command("ProjectAdd", core.add_project,
  { desc = "add project to session list" })

---open project command
vim.api.nvim_create_user_command("ProjectOpen",
  function(args)
    local path = args.args
    if not path or vim.fn.empty(vim.trim(path)) == 1 then return end
    path = vim.fn.fnamemodify(path, ":p")
    core.open_project(path)
  end,
  { nargs = "?", complete = "file", desc = "open project" })

return M
