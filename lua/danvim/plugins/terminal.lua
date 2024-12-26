return {
  'voldikss/vim-floaterm',
  { 'akinsho/toggleterm.nvim', config = true },
  {
    'chomosuke/term-edit.nvim',
    config = function()
      require('term-edit').setup { prompt_end = '❯ ' }
    end,
  },
}
