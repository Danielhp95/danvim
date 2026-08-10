local M = {}

local function get_parent_dir(path)
  return path:match("(.*/)") or path
end

M.fuzzy_open = function()
  -- 1. Get the yazi cwd. If yazi is already open in a floating window, get its cwd. If not, fallback to current Neovim cwd
  local yazi = require('yazi')
  local yazi_state = yazi.get_state and yazi.get_state() or nil
  local cwd = vim.uv.cwd()
  if yazi_state and yazi_state.cwd then
    cwd = yazi_state.cwd
  end

  -- Use snacks.picker for fuzzy file search in cwd. On selection, reopen yazi
  -- in the file's directory with the file preselected.
  local snacks = require('snacks')
  snacks.picker.files({
    cwd = cwd,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      -- Resolves the item to an absolute path regardless of how the finder
      -- reported it (relative to cwd, or already absolute).
      local path = snacks.picker.util.path(item)
      if not path then
        return
      end
      yazi.yazi({ cwd = get_parent_dir(path), preselect = path })
    end,
  })
end

return M
