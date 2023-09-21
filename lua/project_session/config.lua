local M = {}

M.options = {
  dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
  options = { "buffers", "curdir", "tabpages", "winsize" },
  patterns = { "cargo.toml", "package.json", "makefile", "lua", "lazy-lock.json", ".git" },
  -- 插件窗口配置
  pluginwins = {
    ["nvim-tree"] = {
      ft = "NvimTree",
      open = function()
        vim.schedule(function ()
          local winnr = vim.fn.winnr()
          require("nvim-tree.api").tree.focus()
          vim.cmd((winnr + 1) .. "wincmd w")
        end)
      end
    }
  }
}

-- 判断当前窗口内是否又某个类型的buffer
local function match_visible_win(filetype)
  local win_list = vim.api.nvim_list_wins()
  for _, win_id in ipairs(win_list) do
    local bufnr = vim.api.nvim_win_get_buf(win_id)
      if filetype == vim.api.nvim_buf_get_option(bufnr, "filetype") then
      return true
    end
  end
  return false
end

-- 追加内容
local function append(path, data)
  local uv = vim.loop
  local file  = uv.fs_open(path, "a", 660)
  if file then
    uv.fs_write(file, data, -1, function(err)
      if err then
        vim.notify(err, vim.log.levels.WARN)
      end
      uv.fs_close(file)
    end)
  end
end

-- 创建插件窗口的session
M.mks_plugin = function(session_file)
  local pluginwins =  M.options.pluginwins or {}
  for plugin, value in pairs(pluginwins) do
    if package.loaded[plugin] and value and value.ft and value.open and match_visible_win(value.ft) then
      local cmd = string.format("lua require('project_session.config').options.pluginwins[\"%s\"].open()", plugin)
      append(session_file, cmd)
    end
  end
end

return M
