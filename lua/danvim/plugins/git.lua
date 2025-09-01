return {
  'tpope/vim-fugitive',
  { 'lewis6991/gitsigns.nvim', opts = {} },
  { 'sindrets/diffview.nvim', opts = {
    view = {
      merge_tool = {
        layout = 'diff3_mixed',
      },
    },
  } },
  {
    'rbong/vim-flog',
    lazy = true,
    cmd = { 'Flog', 'Flogsplit', 'Floggit' },
    dependencies = {
      'tpope/vim-fugitive',
    },
  },
  {
    'ruifm/gitlinker.nvim',
    dependencies = {
      'ojroques/vim-oscyank',
      'nvim-lua/plenary.nvim',
    },
    opts = {},
  },
  {
    'oribarilan/lensline.nvim',
    event = 'LspAattach',
    opts = {
      providers = {
        {
          name = "references",
          enabled = true,     -- enable references provider
          quiet_lsp = true,   -- suppress noisy LSP log messages (e.g., Pyright reference spam)
        },
        {
          name = "last_author",
          enabled = true,         -- enabled by default with caching optimization
          cache_max_files = 50,   -- maximum number of files to cache blame data for (default: 50)
        },
        {
          name = 'complexity',
          enabled = true,
          min_level = 'L', -- only show L and XL complexity (default)
        },
      },
    },
  },
}
