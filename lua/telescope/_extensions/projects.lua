local ok, telescope = pcall(require, "telescope")

if not ok then return end

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local core = require("project_session.core")


---create finder to display project in telescope list
local function create_finder()
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 30, }, { remaining = true, }
    }
  })

  local function make_display(entry)
    ---@type Project
    local project = entry.value
    return displayer({
      project.name,
      { project.full_path, "Comment" }
    })
  end

  return finders.new_table({
    results = core.list_projects(),
    entry_maker = function(entry)
      return {
        display = make_display,
        name = entry.name,
        value = entry,
        ordinal = entry.full_path,
      }
    end,
  })
end

---load project
local function load_project(prompt_bufnr)
  local selected_entry = state.get_selected_entry()
  if selected_entry == nil then
    actions.close(prompt_bufnr)
    return
  end
  actions.close(prompt_bufnr)

  core.open_project(selected_entry.value)
end

---delete project
local function delete_project(prompt_bufnr)
  local selected_entry = state.get_selected_entry()
  if selected_entry == nil then
    actions.close(prompt_bufnr)
    return
  end

  ---@type Project
  local project = selected_entry.value

  local choice = vim.fn.confirm(
    string.format(
      "Delete '%s' from project list?", project.full_path), "&yes\n&no", 2)
  if choice ~= 1 then return end

  project:delete(true)

  local finder = create_finder()
  state.get_current_picker(prompt_bufnr):refresh(finder, {
    reset_prompt = true,
  })
end

---copy project absolute path
local function copy_path()
  local selected_entry = state.get_selected_entry()
  if selected_entry ~= nil then
    vim.fn.setreg("+", selected_entry.value.full_path)
  end
end

---print project absolute path in command line
local function print_path()
  local selected_entry = state.get_selected_entry()
  if selected_entry ~= nil then
    vim.fn.input(selected_entry.value.full_path ..
      "\n\nPress ENTER or type command to continue")
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
      actions.select_default:replace(function()
        load_project(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

return telescope.register_extension({
  exports = {
    recent_projects = recent_projects,
  },
})
