-- [[ Setting options ]]
-- This file configures various Neovim options for an optimized editor experience.
-- See `:help vim.o`

local icons = require("danvim.icons")

vim.filetype.add({ pattern = { [".*/hyprland.*%.conf"] = "hyprlang" } }) -- Add custom filetype detection for Hyprland configuration files.
vim.o.updatetime = 250 -- CursorHold/swap latency; default 4000ms delays gitsigns blame & friends.
-- THIS IS THE ONLY PLACE TO SET IT. Everything else defers to 'winborder' when
-- it isn't given an explicit border, so don't reintroduce per-plugin values:
--   * blink.cmp — menu/documentation/signature all default `border = nil`,
--     documented as falling back to vim.o.winborder on 0.11+.
--   * vim.diagnostic floats — vim.lsp.util.open_floating_preview resolves
--     `opts.border or vim.o.winborder`.
--   * the ui2 cmdline/message windows — ui2 leaves the msg window's border nil,
--     so it inherits too; the set_config call below only repositions it.
-- The one exception is tabterm's `ui.border` in plugins/terminal.lua, which is
-- third-party and has to be kept in sync by hand.
--
-- Note this sets the border *shape* only. blink remaps FloatBorder away via
-- winhighlight, so its border *colour* needs its own groups — see the
-- BlinkCmp*Border overrides in plugins/colorschemes.lua.
vim.o.winborder = "rounded"
vim.o.foldenable = false -- Disable folding by default.
vim.o.completeopt = "menu,menuone,noselect" -- Configure completion options for better interaction with completion menus.
vim.o.swapfile = false -- Disable swap files to prevent extra files being written in the directory.
-- vim.o.shell = vim.fn.executable("zsh") == 1 and "zsh" or vim.o.shell -- Use zsh for :terminal regardless of $SHELL (e.g. nix develop overwrites it with bash).
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
vim.o.number = true -- Display absolute line number on the current line
vim.o.undofile = true -- Persist undo history to a file.
vim.o.hidden = true -- Allow switching buffers without saving the current buffer.
vim.o.list = true -- Show whitespace characters.
vim.o.background = "dark" -- Enable dark background for better contrast.
vim.o.backspace = "indent,eol,start" -- Specify backspace behavior.
vim.o.undolevels = 1000 -- Maximum undo levels (default). Higher values keep every change of a long session in RAM.
vim.o.undoreload = 10000 -- Maximum lines to save for undo on buffer reload (default).
vim.opt.shortmess:append("u") -- Silence "back N lines"/undo-redo messages (0.12+).
vim.opt.jumpoptions = "stack,view" -- Enable enhanced jump options for the jump list.
vim.o.splitkeep = "screen" -- Keep screen stable when splits open/close (0.9+).
vim.o.smoothscroll = true -- Smooth scrolling for wrapped lines (0.10+).
vim.o.foldmethod = "indent" -- Use indentation-based folding by default.
vim.wo.foldexpr = vim.treesitter.foldexpr -- Use Tree-sitter-based folding expressions.
vim.o.foldnestmax = 10 -- Set maximum fold nesting limit.
vim.o.foldlevel = 10 -- Set initial fold level.
vim.o.scrolloff = 3 -- Keep 3 lines visible above and below the cursor when scrolling.
vim.o.scrolloffpad = 0 -- Disable vertical centering of the cursor at end-of-file (0.12+).
vim.o.sidescrolloff = 5 -- Keep 5 columns visible left and right of the cursor when scrolling horizontally.
vim.o.listchars = "tab:  ,trail:\u{00B7},nbsp:○" -- Whitespace indicators; trailing spaces as a quiet middle dot.
vim.o.clipboard = "unnamed,unnamedplus" -- Use the system clipboard for all copy-paste operations.
vim.o.formatoptions = "tcqj" -- Set formatting options for text handling.
vim.o.encoding = "utf-8" -- Configure default text encoding to UTF-8.
vim.o.fileencodings = "utf-8" -- Configure fallback encodings.
vim.o.bomb = false -- Do not write a UTF-8 BOM.
vim.o.binary = false -- Keep normal text-mode buffer behavior (EOL handling intact).
vim.o.matchpairs = "(:),{:},[:],<:>" -- Specify matching pairs for easier navigation.
-- Pin the spell dictionary to a stable, writable path. Without this, `zg`
-- writes to the first writable spell/ dir on the runtimepath — with wrapRc
-- that was a random lazy.nvim plugin checkout, dirtying its git tree.
vim.o.spellfile = vim.fn.stdpath("data") .. "/spell/en.utf-8.add"
vim.o.expandtab = true -- Replace tabs with spaces.
vim.o.wildmode = "list:longest,list:full" -- Display autocompletion suggestions in a user-friendly way.
vim.o.modeline = true -- Enable modelines for file-specific settings.
vim.o.conceallevel = 1 -- Show concealed text with low visibility.
vim.o.showmode = false -- Hide mode in status line (managed by plugins like lualine).
vim.o.laststatus = 2 -- Use a global status line across all windows.
-- 0, not 1: the cmdline lives in a floating window (plugins/cmdline.lua), so
-- reserving a row below the statusline would just leave a permanent gap.
-- tiny-cmdline forces this to 0 at runtime anyway; setting it here avoids the
-- two fighting on startup. It temporarily bumps to 1 during a search.
vim.o.cmdheight = 0
vim.o.fillchars =
	"eob: ,fold: ,diff:╱,msgsep:─,vert:│,horiz:─,horizup:╴,horizdown:╶,vertleft:╴,vertright:╶" -- Define fill characters for UI items.
-- Fold markers in the statuscolumn (snacks draws closed folds only).
vim.opt.fillchars:append({ foldopen = icons.fold.open, foldclose = icons.fold.close })
vim.o.diffopt = "internal,filler,closeoff,linematch:40,iwhite"
-- The `diffopt` options explained:
-- internal: Use Neovim's internal diff library for better performance and integration.
-- filler: Show filler lines when displaying `diff` to maintain proper alignment between buffers.
-- closeoff: Automatically close the `diff` mode state for buffers when changes are resolved or not found.
-- linematch:40: Perform finer line matching by analyzing adjacent lines (up to 40 lines) to improve diff accuracy.
-- iwhite: Ignore whitespace differences to focus on actual content changes.

-- [[ Diagnostics ]]
-- Inline virtual_text everywhere, plus full virtual_lines on the cursor line.
-- `overflow = "wrap"` wraps lines wider than the window onto extra rows (0.12+).
-- The gutter sign and the inline prefix use the statusline's icons (icons.lua);
-- their colours come from the theme's DiagnosticSign*/DiagnosticVirtualText* groups.
vim.diagnostic.config({
	severity_sort = true,
	signs = { text = icons.diagnostic_by_severity },
	virtual_text = {
		current_line = false,
		prefix = function(diagnostic)
			return icons.diagnostic_by_severity[diagnostic.severity]
		end,
	},
	virtual_lines = { current_line = true, overflow = "wrap" },
})
vim.o.messagesopt = "hit-enter,history:500,timeout:3000,maxheight:50" -- timeout in ms; maxheight in % of 'lines' for the cmdline target
-- Experimental UI2: floating cmdline and messages
require('vim._core.ui2').enable({
  enable = true,
  msg = {
    targets = {
      -- 'default' is the key for "any kind not listed below". The old extui API
      -- spelled it [''], which this table used to use — but ui2 now treats a ''
      -- key as a Lua pattern matched against string message IDs, and '' matches
      -- everything, so it hijacked unrelated messages at random.
      default = 'msg',
      empty = 'cmd',
      bufwrite = 'msg',
      confirm = 'cmd',
      -- NOT 'pager': the pager is a real window and ui2 focuses it
      -- (nvim_set_current_win), so a routine "E486: Pattern not found" from a
      -- failed search yanked the cursor out of the buffer until you pressed q.
      -- Multi-line errors worth reading (echoerr/lua_error/rpc_error) still go there.
      emsg = 'msg',
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
    dialog = {
      height = 0.5,
    },
    msg = {
      height = 0.3,
    },
    pager = {
      height = 0.5,
    },
  },
})
local ui2 = require("vim._core.ui2")
local msgs = require("vim._core.ui2.messages")
local orig_set_pos = msgs.set_pos
msgs.set_pos = function(tgt, focus)
	orig_set_pos(tgt, focus)
	if (tgt == "msg" or tgt == nil) and vim.api.nvim_win_is_valid(ui2.wins.msg) then
		pcall(vim.api.nvim_win_set_config, ui2.wins.msg, {
			relative = "editor",
			anchor = "NE",
			row = 1,
			col = vim.o.columns - 1,
		})
	end
end
