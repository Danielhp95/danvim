return {
  'tpope/vim-fugitive',
  { 'lewis6991/gitsigns.nvim', opts = {} },
  { 'sindrets/diffview.nvim', opts = {
    view = {
      merge_tool = {
        layout = 'diff3_mixed',
      },
    },
    }
  },
  {
    'rbong/vim-flog',
    lazy = true,
    cmd = { 'Flog', 'Flogsplit', 'Floggit' },
    dependencies = {
      'tpope/vim-fugitive',
    },
  },
}
