require('nixCatsUtils').setup {
  non_nix_value = true,
}

-- Set <space> as the leader key
-- See `:help mapleader`
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Skip unused builtin runtime plugins. Must be set BEFORE lazy.nvim's setup
-- below — lazy sources the rtp plugin files itself at the end of setup(), and
-- its own disabled_plugins list is inert because lazyCat sets
-- performance.rtp.reset = false. matchparen is intentionally kept.
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_tutor_mode_plugin = 1
-- netrw fully off: `nvim <dir>` no longer opens a listing (yazi covers it)
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = nixCats 'have_nerd_font'

-- NOTE: nixCats: You might want to move the lazy-lock.json file
local function getlockfilepath()
  if require('nixCatsUtils').isNixCats and type(require('nixCats').settings.unwrappedCfgPath) == 'string' then
    return require('nixCats').settings.unwrappedCfgPath .. '/lazy-lock.json'
  else
    return vim.fn.stdpath 'config' .. '/lazy-lock.json'
  end
end
local lazyOptions = {
  lockfile = getlockfilepath(),
  -- Config lives in the nix store (wrapRc) — nothing to watch for changes
  change_detection = { enabled = false, notify = false },
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
}

-- NOTE: nixCats: this the lazy wrapper. Use it like require('lazy').setup() but with an extra
-- argument, the path to lazy.nvim as downloaded by nix, or nil, before the normal arguments.
require('nixCatsUtils.lazyCat').setup(nixCats.pawsible { 'allPlugins', 'start', 'lazy.nvim' }, {
  { import = 'danvim.plugins' },
}, lazyOptions)

require 'danvim.options'
require 'danvim.aucmds'
require 'danvim.keybindings'
require 'danvim.builtin_plugins'
