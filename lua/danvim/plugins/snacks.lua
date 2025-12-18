vim.g.snacks_animate = false -- Only this worked to remove snacks.animate
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    animate = { enabled = false }, -- Didn't work!
    dashboard = { enabled = false }, -- I don't want a dashboard when I open nvim
    terminal = { enabled = true },
    bigfile = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        buffers = {
          win = {
            keys = {
              ['<C-r>'] = { 'buf_delete', mode = { 'n', 'i' } },
            },
          },
        },
      },
      win = {
        input = {
          keys = {
            -- Map Ctrl+u to clear the input in picker
            ['<C-u>'] = { 'clear', mode = { 'i', 'n' } },
            -- ['<Esc>'] = { 'close', mode = { 'i', 'n' } },
          },
        },
      },
      layouts = {
        default = {
          layout = {
            backdrop = false,
            row = 1,
            width = 0.97,
            min_width = 80,
            height = 0.99,
            border = 'none',
            box = 'vertical',
            { win = 'preview', title = '{preview}', height = 0.6, border = true },
            {
              box = 'vertical',
              border = true,
              title = '{title} {live} {flags}',
              title_pos = 'center',
              { win = 'input', height = 1, border = 'bottom' },
              { win = 'list', border = 'none' },
            },
          },
        },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    zen = { enabled = true, toggles = { dim = false } },
  },
}
