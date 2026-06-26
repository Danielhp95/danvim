-- [[ Setting options ]]
-- This file configures various Neovim options for an optimized editor experience.
-- See `:help vim.o`

vim.filetype.add({ pattern = { [".*/hyprland.*%.conf"] = "hyprlang" } }) -- Add custom filetype detection for Hyprland configuration files.
vim.o.winborder = "rounded" -- Rounded border for all floating windows
vim.o.foldenable = false -- Disable folding by default.
vim.o.completeopt = "menu,menuone,noselect" -- Configure completion options for better interaction with completion menus.
vim.o.swapfile = false -- Disable swap files to prevent extra files being written in the directory.
vim.o.timeoutlen = 100 -- Adjust key sequence timeout length for mapping sequences.
vim.o.wrap = false -- Disable line wrapping globally.
vim.o.grepprg = "rg --vimgrep --no-heading --smart-case" -- Configure grep program for efficient searches.
vim.o.grepformat = "%f:%l:%c:%m,%f:%l:%m" -- Define grep format.
vim.o.relativenumber = true -- Display relative line numbers for easier navigation.
vim.o.autoread = true -- Automatically reload file if it is changed outside of Neovim.
vim.o.showcmd = true -- Show command inputs in the status line.
vim.o.showmatch = true -- Highlight matching parentheses or symbols.
vim.o.ignorecase = true -- Ignore case in searches unless a capital letter is used.
vim.o.smartcase = true -- Override `ignorecase` for case-sensitive searches with capital letters.
vim.o.inccommand = "split" -- Show effects of commands incrementally.
vim.o.incsearch = true -- Enable incremental searches.
vim.o.tabstop = 2 -- Set tabstop to 2 spaces.
vim.o.shiftwidth = 2 -- Indent by 2 spaces for each shift.
vim.o.cursorline = true -- Highlight the line where the cursor is located.
vim.o.autoindent = true -- Enable automatic indentation based on the current line.
vim.o.copyindent = true -- Copy structure from existing lines for smart indentation.
vim.o.splitbelow = false -- Open horizontal splits above the current window.
vim.o.splitright = true -- Open vertical splits to the right of the current window.
vim.o.number = true -- Display absolute line numbers.
vim.o.undofile = true -- Persist undo history to a file.
vim.o.hidden = true -- Allow switching buffers without saving the current buffer.
vim.o.list = true -- Show whitespace characters.
vim.o.background = "dark" -- Enable dark background for better contrast.
vim.o.backspace = "indent,eol,start" -- Specify backspace behavior.
vim.o.undolevels = 1000000 -- Configure maximum undo levels.
vim.o.undoreload = 1000000 -- Configure maximum reload levels.
vim.opt.jumpoptions = "stack,view" -- Enable enhanced jump options for the jump list.
vim.o.splitkeep = "screen" -- Keep screen stable when splits open/close (0.9+).
vim.o.smoothscroll = true -- Smooth scrolling for wrapped lines (0.10+).
vim.o.foldmethod = "indent" -- Use indentation-based folding by default.
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- Use Tree-sitter-based folding expressions.
vim.o.foldnestmax = 10 -- Set maximum fold nesting limit.
vim.o.foldlevel = 10 -- Set initial fold level.
vim.o.scrolloff = 3 -- Keep 3 lines visible above and below the cursor when scrolling.
vim.o.sidescrolloff = 5 -- Keep 5 columns visible left and right of the cursor when scrolling horizontally.
vim.o.listchars = "tab:  ,trail:●,nbsp:○" -- Define special characters for whitespace indicators.
vim.o.clipboard = "unnamed,unnamedplus" -- Use the system clipboard for all copy-paste operations.
vim.o.formatoptions = "tcqj" -- Set formatting options for text handling.
vim.o.encoding = "utf-8" -- Configure default text encoding to UTF-8.
vim.o.fileencodings = "utf-8" -- Configure fallback encodings.
vim.o.bomb = false -- Do not write a UTF-8 BOM.
vim.o.binary = false -- Keep normal text-mode buffer behavior (EOL handling intact).
vim.o.matchpairs = "(:),{:},[:],<:>" -- Specify matching pairs for easier navigation.
vim.o.expandtab = true -- Replace tabs with spaces.
vim.o.wildmode = "list:longest,list:full" -- Display autocompletion suggestions in a user-friendly way.
vim.o.modeline = true -- Enable modelines for file-specific settings.
vim.o.conceallevel = 1 -- Show concealed text with low visibility.
vim.o.showmode = false -- Hide mode in status line (managed by plugins like lualine).
vim.o.laststatus = 2 -- Use a global status line across all windows.
vim.o.cmdheight = 1 -- Reserve one line below statusline for commands and messages.
vim.o.fillchars =
	"eob: ,fold: ,diff:╱,msgsep:─,vert:│,horiz:─,horizup:╴,horizdown:╶,vertleft:╴,vertright:╶" -- Define fill characters for UI items.
vim.o.diffopt = "internal,filler,closeoff,linematch:40,iwhite"
-- The `diffopt` options explained:
-- internal: Use Neovim's internal diff library for better performance and integration.
-- filler: Show filler lines when displaying `diff` to maintain proper alignment between buffers.
-- closeoff: Automatically close the `diff` mode state for buffers when changes are resolved or not found.
-- linematch:40: Perform finer line matching by analyzing adjacent lines (up to 40 lines) to improve diff accuracy.
-- iwhite: Ignore whitespace differences to focus on actual content changes.

-- Experimental UI2: floating cmdline and messages
require('vim._core.ui2').enable({
  enable = true,
  msg = {
    targets = {
      [''] = 'msg',
      empty = 'cmd',
      bufwrite = 'msg',
      confirm = 'cmd',
      emsg = 'pager',
      echo = 'msg',
      echomsg = 'msg',
      echoerr = 'pager',
      completion = 'cmd',
      list_cmd = 'pager',
      lua_error = 'pager',
      lua_print = 'msg',
      progress = 'pager',
      rpc_error = 'pager',
      quickfix = 'msg',
      search_cmd = 'cmd',
      search_count = 'cmd',
      shell_cmd = 'pager',
      shell_err = 'pager',
      shell_out = 'pager',
      shell_ret = 'msg',
      undo = 'msg',
      verbose = 'pager',
      wildlist = 'cmd',
      wmsg = 'msg',
      typed_cmd = 'cmd',
    },
    cmd = {
      height = 0.5,
    },
    dialog = {
      height = 0.5,
    },
    msg = {
      height = 0.3,
      timeout = 5000,
    },
    pager = {
      height = 0.5,
    },
  },
})
local ui2 = require("vim._core.ui2")
local msgs = require("vim._core.ui2.messages")
local orig_set_pos = msgs.set_pos
msgs.set_pos = function(tgt)
	orig_set_pos(tgt)
	if (tgt == "msg" or tgt == nil) and vim.api.nvim_win_is_valid(ui2.wins.msg) then
		pcall(vim.api.nvim_win_set_config, ui2.wins.msg, {
			relative = "editor",
			anchor = "NE",
			row = 1,
			col = vim.o.columns - 1,
			border = "rounded",
		})
	end
end
