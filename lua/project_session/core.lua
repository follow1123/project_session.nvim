local utils = require("project_session.utils")
local config = require("project_session.config")
local Project = require("project_session.project")

local M = {}

---@param session_file string
local function mks_plugin(session_file)
  local file_tree_conf =  config.options.file_tree
  if not file_tree_conf or
    not package.loaded[file_tree_conf.plugin_name] then return end

  assert(file_tree_conf.ft, "`options.file_tree.ft` is not exists")

  if utils.match_visible_win(file_tree_conf.ft) and
    type(file_tree_conf.on_restore) == "function" then
    utils.append_file(session_file,
      "lua require('project_session.config').options.file_tree.on_restore()")
  end
end

---save session only save existing session
---@param path string?
function M.save_project(path)
  local project = Project:from_path(config.options.dir, path or vim.fn.getcwd())
  if not project:is_saved() then
    vim.notify(
      "project not in session list, please add project first, path: " ..
      project.full_path, vim.log.levels.INFO)
    return
  end
  project:save(config.options.session_opts, true)
  mks_plugin(project.session_file)
end

---add project
function M.add_project()
  local file = vim.fs.normalize(vim.fn.expand("%:p"))
  if vim.fn.filereadable(file) ~= 1 and vim.fn.isdirectory(file) ~= 1 then
    vim.notify(
      "this file or directory is invalid: " .. file, vim.log.levels.INFO)
    return
  end

  local root_dir = utils.find_root(vim.fn.fnamemodify(file, ":p:h"), config.options.project_patterns)
  vim.api.nvim_set_current_dir(root_dir)

  local project = Project:from_path(config.options.dir, root_dir)
  project:save(config.options.session_opts, true)
  mks_plugin(project.session_file)
end

---check unsaved file
---@return boolean
local function check_unsaved_file()
  local bufs = vim.api.nvim_list_bufs()
  local unsaved_files = ""

  -- concat unsaved filename
  for _, bufnr in ipairs(bufs) do
    if vim.api.nvim_buf_get_option(bufnr, "modified") then
      local file_name = vim.api.nvim_buf_get_name(bufnr)
      if vim.fn.empty(file_name) ~= 1 then
        unsaved_files = unsaved_files .. file_name .. "\n"
      end
    end
  end
  if vim.fn.empty(unsaved_files) == 1 then return true end

  -- 2: save all and open project
  -- 3: don't save and open project
  -- otherwise: do not open the project
  local choice = vim.fn.confirm(
    unsaved_files .. "these file not save", "&ok\n&save all\n&ignore", 1)

  if choice == 2 then
    vim.cmd.wa()
    return true
  end
  if choice == 3 then return true end
  return false
end

---stop lsp service and wait shut down completely
local function stop_lsp()
  local ok = pcall(vim.lsp.stop_client, vim.lsp.get_active_clients())
  if not ok then return end

  -- wait for lsp shut down completely
  local mill = 0
  while mill < 300 do
    local clients = vim.lsp.get_active_clients()
    if not clients or #clients == 0 then break end
    vim.wait(1)
    mill = mill + 1
  end
end

---before open project
local function before_open_project()
  local is_continue = check_unsaved_file()
  stop_lsp()
  return is_continue
end

---open project
---@param project string|Project
function M.open_project(project)
  if not before_open_project() then return end

  -- save current project
  if not utils.is_empty_project() then
    local cur_project = Project:from_path(config.options.dir, vim.fn.getcwd())
    if cur_project:is_saved() then
      cur_project:save(config.options.session_opts)
      mks_plugin(project.session_file)
    end
  end

  vim.cmd.clearjumps() -- clear jump list
  vim.cmd("silent! %bwipeout!") -- force clear all buffer

  if type(project) == "string" then
    local path = project
    local root_dir = utils.find_root(project, config.options.project_patterns)
    project = Project:from_path(config.options.dir, root_dir)

    if vim.fn.isdirectory(path) == 0 then
      vim.cmd.e(path)
    end

    -- way to open directory
    if config.options.file_tree and
      type(config.options.file_tree.on_open_dir) == "function" then
      config.options.file_tree.on_open_dir(root_dir)
    else
      vim.cmd({ cmd = "E", args = { path } })
    end
    vim.api.nvim_set_current_dir(project.full_path)
    project:save(config.options.session_opts)
    return
  end

  project:load()
end

---@return table<Project>
function M.list_projects()
  local dir = config.options.dir
  assert(dir and vim.fn.isdirectory(dir) == 1, "dir not exists: " .. dir)

  local uv = vim.uv or vim.loop
  local data, err, err_msg = uv.fs_scandir(dir)
  assert(not err and not err_msg, "scandir error: ", err_msg)

  ---@type table<Project>
  local project_list = {}
  for file, _ in uv.fs_scandir_next, data do
    table.insert(project_list, Project:from_session(dir, file))
  end

  table.sort(project_list, function(a, b)
    return uv.fs_stat(a.session_file).mtime.sec >
      uv.fs_stat(b.session_file).mtime.sec
  end)
  return project_list
end

---delete project
---@param path string
function M.delete_project(path)
  Project:from_path(config.options.dir, path):delete(true)
end

return M
