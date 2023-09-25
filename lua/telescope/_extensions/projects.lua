local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  return
end

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local Session = require("project_session.session")
local Project = require("project_session.project")


-- 创建一个telescope的finder用于显示项目信息
local function create_finder()
  local results = Project.recent_projects()

  local displayer = entry_display.create({
    separator = " ",
    items = {
      {
        width = 30,
      },
      {
        remaining = true,
      },
    },
  })

  local function make_display(entry)
    local value = Session.parse_session_file(entry.value)
    return displayer({
      vim.fn.fnamemodify(value, ":t"),
      { value, "Comment" }
    })
  end

  return finders.new_table({
    results = results,
    entry_maker = function(entry)
      return {
        display = make_display,
        name = entry,
        value = entry,
        ordinal = entry,
      }
    end,
  })
end

-- 加载项目，直接加载对应的session
local function load_project(prompt_bufnr)
  local selected_entry = state.get_selected_entry(prompt_bufnr)
  if selected_entry == nil then
    actions.close(prompt_bufnr)
    return
  end
  actions.close(prompt_bufnr)
  vim.cmd("silent! %bwipeout!") -- 强制清空当前的所有buffer
  Session.load_session(selected_entry.value)
end

-- 删除项目，直接删除对应的session
local function delete_project(prompt_bufnr)
  local selectedEntry = state.get_selected_entry(prompt_bufnr)
  if selectedEntry == nil then
    actions.close(prompt_bufnr)
    return
  end

  local choice = vim.fn.confirm("Delete '" ..  Session.parse_session_file(selectedEntry.value) .. "' from project list?", "&yes\n&no", 2)
  if choice == 1 then
    Project.delete_project(selectedEntry.value)

    local finder = create_finder()
    state.get_current_picker(prompt_bufnr):refresh(finder, {
      reset_prompt = true,
    })
  end
end

-- 复制项目路径
local function copy_path(prompt_bufnr)
  local selectedEntry = state.get_selected_entry(prompt_bufnr)
  if selectedEntry ~= nil then
    local value = Session.parse_session_file(selectedEntry.value)
    vim.fn.setreg("+", value)
  end
end

-- 打印项目路径
local function print_path(prompt_bufnr)
  local selectedEntry = state.get_selected_entry(prompt_bufnr)
  if selectedEntry ~= nil then
    local value = Session.parse_session_file(selectedEntry.value)
    vim.fn.input(value .. "\n\nPress ENTER or type command to continue")
  end
end

local function recent_projects(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Recent Projects",
    finder = create_finder(),
    previewer = false,
    sorter = telescope_config.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map("i", "<M-d>", delete_project)
      map("i", "<M-y>", copy_path)
      map("i", "<M-k>", print_path)
      local on_project_selected = function()
        load_project(prompt_bufnr)
      end
      actions.select_default:replace(on_project_selected)
      return true
    end,
  }):find()
end

return telescope.register_extension({
  exports = {
    recent_projects = recent_projects,
  },
})
