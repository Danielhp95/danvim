-- [[ Setting options ]]
-- See `:help vim.o`

-- TODO: Do we still need this? or is this built-in?
vim.filetype.add {
  pattern = { ['.*/hyprland.*%.conf'] = 'hyprlang' },
}

vim.g.nofoldenable = true
vim.g.completeopt = 'menu,menuone,noselect'
vim.g.noswapfile = true
vim.g.timeoutlen = 100
vim.g.nowrap = true

vim.o.grepprg = 'rg --vimgrep --no-heading --smart-case'
vim.o.grepformat = '%f:%l:%c:%m,%f:%l:%m'
vim.o.relativenumber = true
vim.o.autoread = true
vim.o.showcmd = true
vim.o.showmatch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = 'split'
vim.o.incsearch = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.cursorline = true
vim.o.wrap = true
vim.o.autoindent = true
vim.o.copyindent = true
vim.o.splitbelow = false
vim.o.splitright = true
vim.o.number = true
-- This breaks nvim by making the file title show up everytime there's an addition!!!
-- title = true
vim.o.undofile = true
vim.o.hidden = true
vim.o.list = true
vim.o.background = 'dark'
vim.o.backspace = 'indent,eol,start'
vim.o.undolevels = 1000000
vim.o.undoreload = 1000000
vim.opt.jumpoptions = "stack,view"
vim.o.foldmethod = 'indent'
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"  -- If we use foldmethod='expr'
vim.o.foldnestmax = 10
vim.o.foldlevel = 10
vim.o.scrolloff = 3
vim.o.sidescrolloff = 5
vim.o.listchars = 'tab:  ,trail:●,nbsp:○'
vim.o.clipboard = 'unnamed,unnamedplus'
vim.o.formatoptions = 'tcqj'
vim.o.encoding = 'utf-8'
vim.o.fileencodings = 'utf-8'
vim.o.bomb = true
vim.o.binary = true
vim.o.matchpairs = '(:),{:},[:],<:>'
vim.o.expandtab = true
vim.o.wildmode = 'list:longest,list:full'
vim.o.modeline = true
vim.o.conceallevel = 1

-- Most useful options for neovim
vim.o.showmode = false -- Don't show mode, since we have lualine
vim.o.laststatus = 2 -- Show status line on all
vim.o.fillchars = 'eob: ,fold: ,diff:╱,msgsep:─,vert:│,horiz:─,horizup:╴,horizdown:╶,vertleft:╴,vertright:╶' -- Better fillchars for neovim
