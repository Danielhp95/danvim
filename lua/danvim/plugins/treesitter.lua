-- Highlight, edit, and navigate code
local Context = {
  'nvim-treesitter/nvim-treesitter-context',
  opts = {
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
    line_numbers = true,
    multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
    trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
    -- Separator between context and content. Should be a single character string, like '-'.
    -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
    separator = nil,
    zindex = 20, -- The Z-index of the context window
    on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
  },
}

-- causes compilation of treesitter with using lazy
-- nix package doesn't work with lazy
local Treesitter = {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    'nvim-treesitter/nvim-treesitter-refactor',
    'RRethy/nvim-treesitter-textsubjects',
    Context,
    'hiphish/rainbow-delimiters.nvim',
  },
  -- build = 'TSInstall',
  -- build = ':TSUpdate',
  config = function()
    require('nvim-treesitter.configs').setup {
      -- cannot be used when using nixpkgs nvim-treesitter
      -- Add languages to be installed here that you want installed for treesitter
      -- ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'typescript', 'vimdoc', 'vim' },

      -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
      auto_install = false,

      highlight = { enable = true }, -- TODO: what is this?
      rainbow = { enable = true }, -- Rainbow paranthesis for free!
      autotag = { enable = true }, -- TODO: What is this?
      indent = { enable = true }, -- TODO: What is this?
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<CR>',
          node_incremental = '<CR>',
          scope_incremental = '<S-CR>',
          node_decremental = '<BS>',
        },
      },
      refactor = {
        highlight_definitions = {
          enable = true,
          clear_on_cursor_move = true,
        },
        highlight_current_scope = { enable = false },
        smart_rename = { enable = false }, -- Not as powerful as LSP saga
      },
    }
  end,
}

return { Treesitter }
