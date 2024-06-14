---@class Project
---@field name string
---@field full_path string
---@field session_file string
local Project = {}
Project.__index = Project

local utils = require("project_session.utils")

---@param session_path string
---@param session_file string
---@return Project
function Project:from_session(session_path, session_file)
  local path = utils.name2path(vim.fn.fnamemodify(session_file, ":t:r"))
  return setmetatable({
    name = vim.fn.fnamemodify(path, ":t"),
    full_path = path,
    session_file = session_path .. session_file
  }, self)
end

---@param session_path string
---@param project_path string
---@return Project
function Project:from_path(session_path, project_path)
  local session_file = utils.path2name(project_path)
  return setmetatable({
    name = vim.fn.fnamemodify(project_path, ":t"),
    full_path = vim.fs.normalize(project_path),
    session_file = session_path .. session_file .. ".vim"
  }, self)
end

---@param session_opts table<string>
---@param notify boolean?
function Project:save(session_opts, notify)
  local def_opts = vim.opt.sessionoptions
  if vim.fn.empty(session_opts) ~= 1 then
    vim.opt.sessionoptions = session_opts
  end
  vim.cmd("mks! " .. vim.fn.fnameescape(self.session_file))
  vim.opt.sessionoptions = def_opts

  if notify then
    vim.notify(
      string.format("project %s save to: %s", self.name, self.session_file),
      vim.log.levels.INFO)
  end
end

---@param notify boolean?
function Project:delete(notify)
  assert(self:is_saved(), "file not exists: " .. self.session_file)
  local uv = vim.uv or vim.loop
  local success, err, err_name = uv.fs_unlink(self.session_file)
  assert(success, "delete file error: ", err, err_name)

  if notify then
    vim.notify(
      string.format(
        "delete project %s from session dir: %s", self.name, self.session_file),
      vim.log.levels.INFO)
  end
end

---@return boolean
function Project:is_saved()
  return vim.fn.filereadable(self.session_file) == 1
end

function Project:load()
  if not self:is_saved() then
    vim.notify("session file not exists", vim.log.levels.WARN)
    return
  end
  vim.cmd("silent! source " .. vim.fn.fnameescape(self.session_file))
end

return Project
