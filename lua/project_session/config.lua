---@class TreeConfig
---@field plugin_name string
---@field ft string
---@field on_open_dir function?
---@field on_restore function?

---@class ProjectSessionOpts
---@field dir string? session file storage directory
---@field session_opts table<string>? vim builtin option use "h 'sessionoptions'" to get help
---@field project_patterns table<string>? match project root directory
---@field file_tree "nvim-tree"|TreeConfig|nil open file tree plugin options

local M = {}

---@type table<string, TreeConfig>
local tree_config = {
  ["nvim-tree"] = {
    plugin_name = "nvim-tree",
    ft = "NvimTree",
    on_open_dir = function(root_dir)
      local ok, api = pcall(require, "nvim-tree.api")
      if not ok then return end
      api.tree.open({
        path = root_dir,
        winid = vim.api.nvim_get_current_win(),
        find_file = false,
        update_root = false,
      })
    end,
    on_restore = function()
      vim.schedule(function ()
        local ok, api = pcall(require, "nvim-tree.api")
        if not ok then return end
        local win_id = vim.api.nvim_get_current_win()
        api.tree.focus()
        vim.fn.win_gotoid(win_id)
      end)
    end
  }
}

---@type ProjectSessionOpts
local default_options = {
  dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
  session_opts = { "buffers", "curdir", "tabpages", "winsize", "folds" },
  project_patterns = { "cargo.toml", "package.json", "makefile", "lua", "lazy-lock.json", ".git" },
  file_tree = nil
}

---@type ProjectSessionOpts
M.options = nil

---@param opt ProjectSessionOpts?
function M.setup(opt)
  opt = opt or {}
  if type(opt.file_tree) == "string" then
    opt.file_tree = tree_config[opt.file_tree]
  end
  M.options = vim.tbl_deep_extend("force", {}, default_options, opt)
  local dir = vim.fs.normalize(M.options.dir)
  if not string.match(dir, "/$") then
    dir =  dir .. "/"
  end
  M.options.dir = dir
end

return M
