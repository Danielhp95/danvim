local ColorSchemes = {
  'Mofiqul/dracula.nvim',
  'navarasu/onedark.nvim',
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
  dependencies = {
    'EdenEast/nightfox.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('onedark').setup { style = 'deep', toggle_style_key = '<C-q>' }
    -- vim.api.nvim_command("colorscheme carbonfox")
  end,
}

local BufferLine = {
  'akinsho/bufferline.nvim',
  opts = {
    options = {
      -- Remove close icons as I never use them
      separator_style = 'slope',
      buffer_close_icon = '',
      close_icon = '',
    },
  },
}

local function IsZoomedIn()
  if vim.t['simple-zoom'] == nil then
    return ''
  elseif vim.t['simple-zoom'] == 'zoom' then
    return '🔭'
  end
end

-- Status Bar
local LuaLine = {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'fasterius/simple-zoom.nvim',
  },
  opts = {
    options = {
      icons_enabled = true,
      theme = 'auto',
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
      globalstatus = false,
    },
    sections = {
      lualine_a = { "%{&spell ? 'SPELL' : ':3'}", 'mode', { IsZoomedIn } },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = { 'filename' },
      lualine_x = { 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = { 'filetype' },
      lualine_c = { 'filename' },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {},
    },
    tabline = {},
    extensions = {},
  },
}

local IndentLines = {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  show_start = false,
  show_end = false,
  opts = {
    indent = { char = '┊' },
  },
}

local deviconsAutoColors = {
  'rachartier/tiny-devicons-auto-colors.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  event = 'VeryLazy',
  config = function()
    require('tiny-devicons-auto-colors').setup()
  end,
}

local markview = {
  'OXY2DEV/markview.nvim',
  -- the README says it is not recommended to lazy load this, I don't know why
  lazy = false,
  preview = {
    filetypes = { 'markdown', 'Avante' },
    icon_provider = 'mini.icons',
  },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
    'echasnovski/mini.icons', -- Only one is needed, let's try both see which one I like best
  },
  config = {
    markdown = {
      list_items = {
        shift_width = 1,
      },
    },
  },
}

local render_markdown = {
  -- Make sure to set this up properly if you have lazy=true
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    file_types = { 'markdown', 'Avante' },
  },
  ft = { 'markdown', 'Avante' },
}

return {
  ColorSchemes,
  LuaLine,
  {
    'fasterius/simple-zoom.nvim',
    opts = {
      hide_tabline = false,
    },
    config = true,
  },
  IndentLines,
  BufferLine,
  { 'junegunn/goyo.vim' },
  deviconsAutoColors,
  markview,
}
