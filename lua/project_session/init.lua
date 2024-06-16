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
function M.add() core.add_project(true) end

function M.recent_projects()
  local projects = core.list_projects()

  local indent_len = 0
  for _, project in ipairs(projects) do
    indent_len = math.max(indent_len, #project.name)
  end
  indent_len = indent_len + 1

  vim.ui.select(projects,
    {
      prompt = "Recent projects: ",
      format_item = function(item)
        return string.format("%s%s[%s]",
          item.name, string.rep(" ", indent_len - #item.name), item.full_path)
      end
    },
    function(item)
      if item then
        core.open_project(item)
      end
    end)
end

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
vim.api.nvim_create_user_command("ProjectAdd",
  function () core.add_project(true) end,
  { desc = "add project to session list" })

---add dir to project list
vim.api.nvim_create_user_command("ProjectAddDir",
  function () core.add_project(false) end,
  { desc = "add project dir to session list" })

---open project command
vim.api.nvim_create_user_command("ProjectOpen",
  function(args)
    local path = args.args
    if not path or vim.fn.empty(vim.trim(path)) == 1 then return end
    path = vim.fn.fnamemodify(path, ":p")
    core.open_project(path)
  end,
  { nargs = "?", complete = "file", desc = "open project" })

---delete project command no args will delete current project
vim.api.nvim_create_user_command("ProjectDelete",
  function(args)
    local path = args.args
    if not path or vim.fn.empty(vim.trim(path)) == 1 then
      path = vim.fn.getcwd()
    end
    path = vim.fn.fnamemodify(path, ":p")

    local project_filtered = vim.tbl_filter(function(project)
      return vim.fs.normalize(path) == project.full_path
    end, core.list_projects())

    if vim.fn.empty(project_filtered) == 1 then
      vim.notify(
        string.format(
          "project: '%s' not in project list", path), vim.log.levels.WARN)
      return
    end
    core.delete_project(path)
  end,
  {
    nargs = "?", desc = "open project",
    complete = function ()
      return vim.tbl_map(function(project)
        return project.full_path
      end, core.list_projects())
    end
  })

return M
