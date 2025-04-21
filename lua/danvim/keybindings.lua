local wk = require 'which-key'

vim.keymap.set('t', '<ESC>', '<C-\\><C-n>')

-- Miscelaneous small quality of life stuff
wk.add {
  { '<C-Down>', '<cmd>resize +1<cr>', desc = 'Continuous window vertical resize' },
  { '<C-Left>', '<cmd>vertical resize +1<cr>', desc = 'Continuous window horizontal resize' },
  { '<C-Right>', '<cmd>vertical resize -1<cr>', desc = 'Continuous window horizontal resize' },
  { '<C-Up>', '<cmd>resize -1<cr>', desc = 'Continuous window vertical resize' },
  { '<C-s><C-s>', '<cmd>w<cr>', desc = '[s]ave buffer' },
  { '<leader>f', '<cmd> NeoZoomToggle<cr>', desc = '[f]ocuses on current window' },
  { '<leader>nw', group = '[n]o' },
  { '<leader>nwh', '<cmd>noh<cr>', desc = '[h]ighlight' },
  { '<leader>nww', '<cmd>set wrap!<cr>', desc = 'line [w]rap' },
  { '<leader>yB', '<cmd>let @" = expand("%")<CR>:echo "Yanked path: " . expand("%:p")<cr>', desc = '[y]ank [B]uffer absolute path' },
  { '<leader>yb', '<cmd>let @" = expand("%:p")<CR>:echo "Yanked path: " . expand("%:p")<cr>', desc = '[y]ank [b]uffer relative path to cwd' },
  { 'H', '<cmd>tabp<cr>', desc = 'Previous tab' },
  { 'L', '<cmd>tabn<cr>', desc = 'Next tab' },
  { 'gf', '<cmd>e <cfile><cr>', desc = '[g]o to [f]ile under cursor even if not existing' },
}

-- Git
wk.add {
  { '<leader>g', group = '[g]it' },
  { '<leader>gB', '<cmd>Gitsigns blame<cr>', desc = '[b]lame all buffer' },
  { '<leader>gS', '<cmd>Gtabedit :<cr>', desc = 'Git [S]tatus new tab' },
  { '<leader>ga', '<cmd>Git add %:p<cr>', desc = 'Git [a]dd file' },
  { '<leader>gb', '<cmd>Gitsigns blame_line<cr>', desc = '[b]lame current line' },
  { '<leader>gc', '<cmd>Git commit<cr>', desc = 'Git [c]ommit' },
  { '<leader>gd', group = '[d]iff' },
  { '<leader>gdc', '<cmd>DiffviewClose<cr>', desc = '[c]lose diff merger' },
  { '<leader>gdf', '<cmd>DiffviewFileHistory %<cr>', desc = '[d]iff history for current [f]ile' },
  { '<leader>gdo', '<cmd>DiffviewOpen<cr>', desc = '[o]pen new tab with diff merger' },
  { '<leader>gdr', '<cmd>DiffviewRefresh<cr>', desc = '[r]efresh git merge state' },
  { '<leader>gdw', '<cmd>windo diffthis<cr>', desc = '[d]iff all files in [w]indow' },
  { '<leader>gh', group = '[h]unks' },
  { '<leader>ghS', "<cmd>lua require('gitsigns').stage_hunk()<CR>", desc = '[S]tage hunk under cursor' },
  { '<leader>gha', '<cmd>Gitsigns stage_hunk<CR>', desc = 'St[a]ge hunk' },
  { '<leader>ghn', "<cmd>lua require('gitsigns').next_hunk({wrap = true})<CR>", desc = '[n]ext hunk' },
  { '<leader>ghp', "<cmd>lua require('gitsigns').prev_hunk({wrap = true})<CR>", desc = '[p]revious hunk' },
  { '<leader>ghs', "<cmd>lua require('gitsigns').preview_hunk()<CR>", desc = '[s]how hunk diff' },
  { '<leader>ghu', '<cmd>Gitsigns undo_stage_hunk<CR>', desc = '[U]ndo stage hunk' },
  { '<leader>gl', group = '[l]og' },
  { '<leader>gld', '<cmd>Gclog<cr>', desc = 'Load all [d]iffs of this file for each commit' },
  { '<leader>glr', '<cmd>0Gclog<cr>', desc = 'Load all [r]evisions of this file for each commit that affects it' },
  { '<leader>gr', '<cmd>Gread<cr>', desc = '[r]evert to latest git version' },
  { '<leader>gs', '<cmd>Git<cr>', desc = 'Git [s]tatus half screen' },
  { '<leader>gt', '<cmd>Gitsigns toggle_signs<cr>', desc = '[t]oggle gitsigns' },
  { '<leader>gd', group = '[g]it diff', mode = 'v' },
  { '<leader>gdd', ":'<,'>DiffviewFileHistory<cr>", desc = '[d]iff of changes for selected lines', mode = 'v' },
}

-- Telescope
wk.add {
  { '<leader>t', group = '[t]elescope' },
  { '<leader>tS', "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols({symbol_width = 50})<CR>", desc = 'Workspace lsp [S]ymbols' },
  { '<leader>tb', '<cmd>Telescope buffers<CR>', desc = '[b]uffers' },
  { '<leader>td', "<cmd>lua require'telescope.builtin'.find_files({cwd='~/nix_config'})<cr>", desc = 'Open NIX config [d]irectory' },
  { '<leader>tf', '<cmd>Telescope find_files<CR>', desc = 'Find [f]iles' },
  { '<leader>tg', "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", desc = 'Live [g]rep' },
  { '<leader>th', '<cmd>Telescope help_tags<CR>', desc = 'NVIM [h]elp' },
  { '<leader>tk', '<cmd>Telescope keymaps<CR>', desc = '[k]eymaps' },
  { '<leader>to', '<cmd>Telescope oldfiles<CR>', desc = 'Last [o]pened files' },
  { '<leader>tp', '<cmd>Telescope project<CR>', desc = '[p]rojects' },
  { '<leader>tr', '<cmd>Telescope resume<CR>', desc = '[r]esume last search' },
  { '<leader>tm', '<cmd>Telescope marks<CR>', desc = '[m]arks ' },
  { '<leader>ts', "<cmd>lua require('telescope.builtin').lsp_document_symbols({symbol_width = 50})<CR>", desc = 'Buffer lsp [s]ymbols' },
  { '<leader>tt', '<cmd>Telescope<CR>', desc = 'Default [t]elescope' },
  { '<leader>tv', "<cmd>lua require'telescope.builtin'.find_files({cwd='~/Documents/Obsidian Vault/'})<cr>", desc = 'Open Obsidian [v]ault' },
  { '/', "<cmd>lua require'telescope.builtin'.current_buffer_fuzzy_find({layout_strategy='vertical'})<cr>", desc = 'Search current file' },
}

-- Spelling
wk.add {
  { '<leader>s', group = '[s]pelling' },
  { '<leader>sa', 'zg', desc = '[a]dd to dictionary' },
  { '<leader>sn', ']s', desc = '[n]ext spelling error' },
  { '<leader>sp', '[s', desc = '[p]revious spelling error' },
  { '<leader>ss', "<cmd>lua require('telescope.builtin').spell_suggest(require('telescope.themes').get_cursor())<cr>", desc = '[s]uggestion' },
  { '<leader>st', '<cmd>set spell!<cr>', desc = '[t]oggle spell check' },
}

-- Diagnostics
wk.add {
  { '<leader>d', group = '[d]iagnostics' },
  { '<leader>dP', '<cmd>Trouble diagnostics toggle <CR>', desc = 'all [P]roject diagnostics' },
  { '<leader>db', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', desc = '[b]uffer diagnostics' },
  { '<leader>dn', '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', desc = '[n]ext diagnostic' },
  { '<leader>dp', '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', desc = '[p]revious diagnostic' },
  { '<leader>ds', '<cmd>lua vim.diagnostic.open_float()<CR>', desc = '[s]how diagnostic under cursor' },
}

-- LSP
local vertical_layout = "{layout_strategy='vertical', layout_config = {mirror = true}}"
wk.add {
  { '<C-k>', "<cmd>lua require('lsp_signature').toggle_float_win()<CR>", desc = 'Show signature help' },
  { '<leader>l', group = '[l]sp' },
  { '<leader>lD', "<cmd>lua vim.lsp.buf.definition({layout_strategy='vertical', layout_config = {mirror = true}})<CR>", desc = 'Go to [D]efinition' },
  { '<leader>lI', '<cmd>LspInfo<cr>', desc = '[I]nformation about LSPs' },
  { '<leader>lR', '<cmd>LspRestart<cr>', desc = '[R]estart LSP' },
  { '<leader>lc', '<cmd>Lspsaga code_action<cr>', desc = '[c]ode actions' },
  { '<leader>ld', '<cmd>Lspsaga peek_definition<CR>', desc = 'Peek [d]efinition' },
  { '<leader>lf', "<cmd>lua require('conform').format()<cr>", desc = '[F]ormat file' },
  { '<leader>lh', '<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>', desc = 'Toggle lsp [h]ints' },
  { '<leader>li', "<cmd>lua vim.lsp.buf.implementation({layout_strategy='vertical', layout_config = {mirror = true}})<CR>", desc = 'Go to [i]mplementation' },
  { '<leader>ll', '<cmd>LspLensToggle<cr>', desc = '[t]oggle codelens' },
  { '<leader>ln', '<cmd>Lspsaga rename<cr>', desc = 'Re[n]ame' },
  { '<leader>lo', '<cmd>Lspsaga outline<cr>', desc = '[o]utline code structure' },
  { '<leader>lr', '<cmd>Trouble lsp_references<cr>', desc = 'Show [r]eferences' },
  { 'K', "<cmd>lua vim.lsp.buf.hover({border = 'double'})<CR>", desc = 'Show do[k]umentation' },
  { '<leader>l', group = 'LSP', mode = 'v' },
  { '<leader>lc', '<cmd>lua vim.lsp.buf.code_action()<CR>', desc = '[c]ode actions', mode = 'v' },
}

-- File managers
wk.add {
  { '<leader>-', '<cmd>Yazi<cr>', desc = 'File manager open in current dir' },
  { '<leader><c-up>', '<cmd>Yazi toggle<cr>', desc = 'Resume last yazi session' },
  { '<leader>_', '<cmd>Yazi cwd<cr>', desc = "Open the file manager in nvim's working directory" },
  { '<leader>o', '<cmd>Oil --float<cr>', desc = "Oil file manager in current file's directory" },
}

-- Debugger
-- TODO: look at set_exception_breakpoint. Looks pretty sweet
wk.add {
  { '<leader>b', group = 'De[b]ugger' },
  { '<leader>bB', "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", desc = '[B]reakpoint with condition' },
  { '<leader>bT', "<cmd>lua require('dapui').toggle()<cr>", desc = '[T]oggle all debugger UIs' },
  { '<leader>bb', '<cmd>DapToggleBreakpoint<cr>', desc = '[b]reakpoint toggle current line' },
  { '<leader>bc', '<cmd>DapContinue<cr>', desc = 'Start / [c]ontinue debugger' },
  { '<leader>bd', "<cmd>lua require'dap'.down()<CR>", desc = '[d]own stacktrace' },
  { '<leader>be', "<cmd>lua require('dapui').eval()<cr>", desc = '[e]valuate expresion' },
  { '<leader>bi', "<cmd>lua require'dap'.terminate()<cr>", desc = '[i]nterrupt debugger session' },
  { '<leader>bl', group = '[l]ist' },
  { '<leader>blC', '<cmd>Telescope dap configurations<cr>', desc = '[C]onfigurations' },
  { '<leader>blb', '<cmd>Telescope dap list_breakpoints<cr>', desc = '[b]reakpoints' },
  { '<leader>blc', '<cmd>Telescope dap commands<cr>', desc = '[c]ommands' },
  { '<leader>blf', '<cmd>Telescope dap frames<cr>', desc = '[f]rames' },
  { '<leader>blv', '<cmd>Telescope dap variables<cr>', desc = '[v]ariables' },
  { '<leader>bn', "<cmd>lua require'dap'.step_over({askForTargets = true})<CR>", desc = 'Step over ([n]ext)' },
  { '<leader>bo', "<cmd>lua require'dap'.step_out()<CR>", desc = 'Step [o]ut' },
  { '<leader>bs', "<cmd>lua require'dap'.step_into()<CR>", desc = '[s]tep into' },
  { '<leader>bt', "<cmd>lua require('dapui').toggle(2)<cr>", desc = '[t]oggle debugger repl' },
  { '<leader>bu', "<cmd>lua require'dap'.up()<CR>", desc = '[u]p stacktrace' },
  --- visual
  { '<leader>b', group = 'de[b]ugger', mode = 'v' },
  { '<leader>be', "<cmd>lua require('dapui').eval()<cr>", desc = '[e]valuate expresion', mode = 'v' },
}

-- Terminal
wk.add {
  { '<leader><leader>', group = '[t]erminal' },
  { '<leader><leader>f', "<cmd>ToggleTerm direction='float'<cr>", desc = '[f]loating terminal' },
  { '<leader><leader>h', "<cmd>ToggleTerm direction='horizontal'<cr>", desc = '[h]orizontal terminal' },
  { '<leader><leader>s', '<cmd>ToggleTermSendCurrentLine<cr>', desc = '[s]end cursor line to terminal' },
  { '<leader><leader>t', '<cmd>ToggleTermToggleAll<cr>', desc = 'Toggle all [t]erminals' },
  { '<leader><leader>v', "<cmd>ToggleTerm direction='vertical' size=50<cr>", desc = '[v]ertical terminal' },
  { '<leader><leader>z', '<cmd>NeoZoomToggle<cr>', desc = '[z]oom current buffer' },
  { '<leader><leader>s', "<cmd>'<,'>ToggleTermSendVisualLines<cr>", desc = '[s]end visually selected lines to terminal', mode = 'v' },
}

-- Lua Development
wk.add {
  { '<leader>rr', ":'<,'>SnipRun<cr>", desc = '[r]un selected snippet', mode = 'v' },
}

-- pandoc
wk.add {
  {
    '<leader><leader>p',
    '<cmd>!pandoc -t beamer --pdf-engine=xelatex ~/nix_config/pandoc/pandoc_header --output=%:r.pdf<cr>',
    desc = '[p]andoc file into PDF presentation',
  },
}
