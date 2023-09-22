# project_session.nvim

**project_session.nvim**是一个管理项目session的插件

## 安装

### [lazy](https://github.com/folke/lazy.nvim)

```lua
{
  "follow1123/project_session.nvim",
  config = function()
    require("project_session").setup()
  end
}
```

## 配置

### 默认配置
```lua
{
  dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"), --sessions 保存路径
  options = { "buffers", "curdir", "tabpages", "winsize" }, -- 保存选项，参考vim.opt.sessionoptions
  patterns = { "cargo.toml", "package.json", "makefile", "lua", "lazy-lock.json", ".git" }, -- 根据这些文件判断是项目的根目录
  -- 插件窗口配置
  pluginwins = {
    ["nvim-tree"] = { -- nvim-tree插件配置
      ft = "NvimTree", -- nvim-tree窗口buffer的文件类型
      open = function() -- 打开nvim-tree窗口的方式，这个方法会直接在session文件内调用
        vim.schedule(function ()
          local winnr = vim.fn.winnr() -- 保存光标位置
          require("nvim-tree.api").tree.focus()
          vim.cmd((winnr + 1) .. "wincmd w") -- 恢复光标
        end)
      end
    }
  }
}
```

### [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua)配置

```lua
require("nvim-tree").setup {
  sync_root_with_cwd = true,
  respect_buf_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false
  },
  -- ... 其他
}
```

### Telescope集成

```lua
require("telescope").load_extension("projects")
```

#### Telescope最近项目选择窗口

```lua
require("telescope").extensions.projects.recent_projects()
```

#### Telescope集成窗口的按键映射

* `<M-d>` 删除当前的项目
* `<M-y>` 复制当前项目路径到系统剪贴板
* `<M-k>` 显示当前项目路径，(终端窗口比较小时路径会被挡住)

## API

* 保存当前项目

> 只会保存已存在session的项目，由于使用nvim打开的项目种类很多，没必要将所有打开的项目都保存。  
> 目前只有使用`ProjectAdd`命令添加的项目才会保存

```lua
require("project_session").save()
```

* 加载最近的一个项目

```lua
require("project_session").load_last()
```

## Command

* 添加当前项目到项目列表

```lua
ProjectAdd
```
## 参考插件

> 整合了以下两个插件的部分功能

* [persistence.nvim](https://github.com/folke/persistence.nvim)
* [project.nvim](https://github.com/ahmedkhalf/project.nvim)
