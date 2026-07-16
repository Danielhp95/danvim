local M = {}

local function get_parent_dir(path)
  return path:match("(.*/)") or path
end

M.fuzzy_open = function()
  -- 1. Get the yazi cwd. If yazi is already open in a floating window, get its cwd. If not, fallback to current Neovim cwd
  local yazi = require('yazi')
  local yazi_state = yazi.get_state and yazi.get_state() or nil
  local cwd = vim.loop.cwd()
  if yazi_state and yazi_state.cwd then
    cwd = yazi_state.cwd
  end

  -- Use telescope for fuzzy file search in cwd
  require('telescope.builtin').find_files({
    cwd = cwd,
    attach_mappings = function(_, map)
      -- On selection, open yazi in the file's directory with file preselected
      local actions = require('telescope.actions')
      actions.select_default:replace(function(prompt_bufnr)
        local entry = require('telescope.actions.state').get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and entry.path then
          local parent = get_parent_dir(entry.path)
          yazi.yazi({ cwd = parent, preselect = entry.path })
        elseif entry and entry.value then
          local abs = cwd .. "/" .. entry.value
          local parent = get_parent_dir(abs)
          yazi.yazi({ cwd = parent, preselect = abs })
        end
      end)
      return true
    end,
  })
end

return M

