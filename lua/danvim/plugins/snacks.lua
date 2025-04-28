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
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    zen = { enabled = true, toggles = { dim = false } },
  },
}
