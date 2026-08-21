local wk = require("which-key")

-- Terminal mode: double-tap Ctrl+L to exit (allows programs to use Ctrl+L normally)
local terminal_exit_state = {
	pending = false,
	timeout_id = nil,
}

vim.keymap.set("t", "<C-l>", function()
	if terminal_exit_state.pending then
		-- Second press - exit terminal mode
		terminal_exit_state.pending = false
		if terminal_exit_state.timeout_id then
			vim.fn.timer_stop(terminal_exit_state.timeout_id)
			terminal_exit_state.timeout_id = nil
		end
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
	else
		-- First press - set pending flag and start timeout
		terminal_exit_state.pending = true
		if terminal_exit_state.timeout_id then
			vim.fn.timer_stop(terminal_exit_state.timeout_id)
		end
		terminal_exit_state.timeout_id = vim.fn.timer_start(500, function()
			terminal_exit_state.pending = false
			terminal_exit_state.timeout_id = nil
		end)
	end
end)

vim.keymap.set("n", "<leader>q", function()
	local qf_exists = false
	for _, win in pairs(vim.fn.getwininfo()) do
		if win.quickfix == 1 then
			qf_exists = true
			break
		end
	end
	if qf_exists then
		vim.cmd("cclose")
	else
		vim.cmd("copen")
	end
end, { desc = "Toggle quickfix list" })

-- Miscelaneous small quality of life stuff
wk.add({
	{ "<C-Down>", "<cmd>resize +1<cr>", desc = "Continuous window vertical resize" },
	{ "<C-Left>", "<cmd>vertical resize +1<cr>", desc = "Continuous window horizontal resize" },
	{ "<C-Right>", "<cmd>vertical resize -1<cr>", desc = "Continuous window horizontal resize" },
	{ "<C-Up>", "<cmd>resize -1<cr>", desc = "Continuous window vertical resize" },
	{ "<leader>z", ":Maximize<CR>", desc = "Toggle [z]oom for current window" },
	{ "<C-s><C-s>", "<cmd>w<cr>", desc = "[s]ave buffer" },
	{ "<leader>nw", group = "[n]o" },
	{ "<leader>nwh", "<cmd>noh<cr>", desc = "[h]ighlight" },
	{ "<leader>nww", "<cmd>set wrap!<cr>", desc = "line [w]rap" },
	{
		"<leader>yB",
		'<cmd>let @+ = expand("%:p")<CR>:echo "Yanked path: " . expand("%:p")<cr>',
		desc = "[y]ank [B]uffer absolute path",
	},
	{
		"<leader>yb",
		'<cmd>let @+ = expand("%:.")<CR>:echo "Yanked path: " . expand("%:.")<cr>',
		desc = "[y]ank [b]uffer relative path to cwd",
	},
	{ "H", "<cmd>tabp<cr>", desc = "Previous tab" },
	{ "L", "<cmd>tabn<cr>", desc = "Next tab" },
	{ "gf", "<cmd>e <cfile><cr>", desc = "[g]o to [f]ile under cursor even if not existing" },
	{ "gp", "`[v`]", desc = "[g]o to and visually select last [p]asted text" },
	{ "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle [u]ndotree" },
	{ "<leader>tc", "<cmd>TSContextToggle<cr>", desc = "[t]oggle treesitter [c]ontext" },
	{ "<leader>C", "<cmd>ColorRefs<cr>", desc = "Toggle [C]olour swatches (color-refs)" },
	{
		"<leader>vi",
		"<cmd>vnew term://ipython -i %<cr>",
		desc = "[v]ertical split with [i]python sourcing current buffer",
	},
	{ "<leader>sf", ":source %<cr>", desc = "[s]ource current [f]ile" },
})

-- Quickfix list
wk.add({
	{ "]q", "<cmd>cnext<CR>", desc = "[n]next item quickfix list" },
	{ "[q", "<cmd>cprev<CR>", desc = "[p]rev item quickfix list" },
})

-- AI (codecompanion.nvim, pointed at the local ollama server). Actual keymaps
-- live in the plugin spec (lua/danvim/plugins/codecompanion.lua); this just
-- labels the which-key group.
--
-- The old "[a]vante" label and its <leader>as -> AvanteStop mapping lived here
-- until codecompanion took the group over. AvanteStop had been dead since the
-- avante spec was commented out (plugins/avante.lua returns {} and the package
-- is commented out in flake.nix), so the mapping only ever produced
-- "E492: Not an editor command".
wk.add({
	{ "<leader>a", group = "[a]I" },
})

-- Claude Code (coder/claudecode.nvim). Actual keymaps live in the plugin spec
-- (lua/danvim/plugins/claudecode.lua); this just labels the which-key group.
wk.add({
	{ "<leader>c", group = "[c]laude code" },
	{ "<leader>c", group = "[c]laude code", mode = "v" },
})

-- Git
wk.add({
	{ "<leader>g", group = "[g]it" },
	{ "<leader>gB", "<cmd>Gitsigns blame<cr>", desc = "[b]lame all buffer" },
	{ "<leader>gS", "<cmd>Gtabedit :<cr>", desc = "Git [S]tatus new tab" },
	{ "<leader>ga", "<cmd>Git add %:p<cr>", desc = "Git [a]dd file" },
	{ "<leader>gb", "<cmd>Gitsigns blame_line<cr>", desc = "[b]lame current line" },
	{ "<leader>gc", "<cmd>Git commit<cr>", desc = "Git [c]ommit" },
	{ "<leader>gp", "<cmd>Git push<cr>", desc = "Git [p]ush" },
	{ "<leader>gd", group = "[d]iff" },
	{
		"<leader>gdc",
		"<cmd>DiffviewClose<cr>|<cmd>tabprevious<cr>",
		desc = "[c]lose diff merger and go to previous tab",
	},
	{ "<leader>gh", group = "[h]unks" },
	{ "<leader>ghS", "<cmd>lua require('gitsigns').stage_hunk()<CR>", desc = "[S]tage hunk under cursor" },
	{ "<leader>ghr", "<cmd>lua require('gitsigns').reset_hunk()<CR>", desc = "[r]eset hunk under cursor" },
	{ "<leader>gha", "<cmd>Gitsigns stage_hunk<CR>", desc = "St[a]ge hunk" },
	{ "<leader>ghn", "<cmd>lua require('gitsigns').next_hunk({wrap = true})<CR>", desc = "[n]ext hunk" },
	{ "<leader>ghp", "<cmd>lua require('gitsigns').prev_hunk({wrap = true})<CR>", desc = "[p]revious hunk" },
	{ "]g", "<cmd>lua require('gitsigns').next_hunk({wrap = true})<CR>", desc = "[n]ext hunk" },
	{ "[g", "<cmd>lua require('gitsigns').prev_hunk({wrap = true})<CR>", desc = "[p]revious hunk" },
	{ "<leader>ghs", "<cmd>lua require('gitsigns').preview_hunk()<CR>", desc = "[s]how hunk diff" },
	{ "<leader>ghu", "<cmd>Gitsigns undo_stage_hunk<CR>", desc = "[U]ndo stage hunk" },
	{ "<leader>gl", group = "[l]og" },
	{ "<leader>gld", "<cmd>Gclog<cr>", desc = "Load all [d]iffs of this file for each commit" },
	{ "<leader>glr", "<cmd>0Gclog<cr>", desc = "Load all [r]evisions of this file for each commit that affects it" },
	{ "<leader>gr", "<cmd>Gread<cr>", desc = "[r]evert to latest git version" },
	{ "<leader>gs", "<cmd>Git<cr>", desc = "Git [s]tatus half screen" },
	{ "<leader>gt", "<cmd>Gitsigns toggle_signs<cr>", desc = "[t]oggle gitsigns" },
	{ "<leader>gd", group = "[g]it diff", mode = "v" },
	{ "<leader>gdf", "<cmd>DiffviewFileHistory %<cr>", desc = "[d]iff history for current [f]ile" },
	{ "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "[d]iff view [o]pen (jumps to first conflict)" },
	{ "<leader>gdfb", "<cmd>CodeDiff file<cr>", desc = "[d]iff current [f]ile against [b]ranch" },
	{ "<leader>gdfm", "<cmd>CodeDiff file master<cr>", desc = "[d]iff current [f]ile against [m]aster" },
	{ "<leader>gdm", "<cmd>CodeDiff master<cr>", desc = "[d]iff against [m]aster" },
	{ "<leader>gdh", "<cmd>CodeDiff HEAD<cr>", desc = "[d]iff against [h]ead" },
	{ "<leader>gdr", "<cmd>DiffviewRefresh<cr>", desc = "[r]efresh git merge state" },
	{ "<leader>gdw", "<cmd>windo diffthis<cr>", desc = "[d]iff all files in [w]indow" },
	{ "<leader>gdd", ":'<,'>DiffviewFileHistory<cr>", desc = "[d]iff of changes for selected lines", mode = "v" },
	{ "<leader>gdd", ":'<,'>DiffviewFileHistory<cr>", desc = "[d]iff of changes for selected lines", mode = "v" },
})

-- Octo (GitHub issues/PRs/reviews). Actual keymaps live in the plugin spec
-- (lua/danvim/plugins/octo.lua); this just labels the which-key group.
wk.add({
	{ "<leader>o", group = "[o]cto" },
	{ "<leader>oc", group = "[c]omments" },
})

-- Pickers (snacks.picker)
wk.add({
	{ "<leader>t", group = "Pickers" },
	{ "<leader>tS", '<cmd>lua require("snacks").picker.lsp_workspace_symbols()<CR>', desc = "Workspace lsp [S]ymbols" },
	{ "<leader>ts", '<cmd>lua require("snacks").picker.lsp_symbols()<CR>', desc = "buffer lsp [s]ymbols" },
	{ "<leader>tb", '<cmd>lua require("snacks").picker.buffers()<CR>', desc = "[b]uffers" },
	{
		"<leader>td",
		'<cmd>lua require("snacks").picker.files({ cwd = "~/nix_config" })<cr>',
		desc = "Open NIX config [d]irectory",
	},
	{ "<leader>tf", '<cmd>lua require("snacks").picker.files()<CR>', desc = "Find [f]iles" },
	{ "<leader>tg", '<cmd>lua require("snacks").picker.grep()<cr>', desc = "Live [g]rep" },
	{ "<leader>tw", '<cmd>lua require("snacks").picker.grep_word()<CR>', desc = "Live [g]rep" },
	{ "<leader>tG", '<cmd>lua require("snacks").picker.git_branches()<CR>', desc = "[G]it branches" },
	{ "<leader>tl", '<cmd>lua require("snacks").picker.lsp_config()<CR>', desc = "[G]it branches" },
	{ "<leader>th", '<cmd>lua require("snacks").picker.help()<CR>', desc = "NVIM [h]elp" },
	{ "<leader>tk", '<cmd>lua require("snacks").picker.keymaps()<CR>', desc = "[k]eymaps" },
	{ "<leader>to", '<cmd>lua require("snacks").picker.smart()<CR>', desc = "Last [o]pened files" },
	{ "<leader>tr", '<cmd>lua require("snacks").picker.resume()<cr>', desc = "[r]esume last search" },
	{ "<leader>tm", '<cmd>lua require("snacks").picker.marks()<cr>', desc = "[m]arks " },
	-- Same as <leader>Sp; kept here because <leader>t is the picker namespace
	{ "<leader>tt", '<cmd>lua require("snacks").picker.pickers()<CR>', desc = "All pickers" },
	{ "<c-f>", '<cmd>lua require("snacks").picker.grep_buffers()<cr>', desc = "Search open [b]uffers" },
})

-- Snacks
Print_last_notification = function()
	local hist = require("snacks.notifier").get_history()
	local notification = hist[#hist] -- Most recent notification
	-- Check if the notification exists and contains a message
	local msg = "No notifications yet"
	if notification and notification.msg then
		-- Extract the message from the notification, removing any surrounding quotes
		-- (single, double, or backticks) for clean display
		msg = notification.msg:match("^[\"'`]?(.+?)[\"'`]?$") or notification.msg
	end
	print(msg)
end
wk.add({
	{ "<leader>S", group = "[S]nacks" },
	{ "<leader>Sp", "<cmd>lua require('snacks').picker.pickers()<CR>", desc = "Snacks [p]ickers" },
	{ "<leader>Sn", "<cmd>lua require('snacks').picker.notifications()<CR>", desc = "Snacks [n]notifications" },
	{ "<leader>SN", "<cmd>lua Print_last_notification()<CR>", desc = "Print last <S>nacks <N>otification" },
})

-- Snacks images (render plots/PDFs/video frames inline in docs)
wk.add({
	{ "<leader>Si", group = "[S]nacks [i]mages" },
	-- Toggle logic lives in snacks.lua (SnacksImageToggle) because it must patch
	-- the renderer's discovery pass to make the flag actually take effect.
	{ "<leader>Sit", "<cmd>SnacksImageToggle<CR>", desc = "[t]oggle inline images" },
	{ "<leader>Sih", "<cmd>lua Snacks.image.hover()<CR>", desc = "[h]over image at cursor" },
	{
		"<leader>Sir",
		function()
			local buf = vim.api.nvim_get_current_buf()
			require("snacks.image.placement").clean(buf)
			require("snacks.image.doc").attach(buf)
		end,
		desc = "[r]efresh inline images (buffer)",
	},
	{
		"<leader>Sic",
		function()
			require("snacks.image.placement").clean(vim.api.nvim_get_current_buf())
		end,
		desc = "[c]lear inline images (buffer)",
	},
	{ "<leader>SiH", "<cmd>checkhealth snacks<CR>", desc = "image [H]ealth / terminal support" },
})

-- Spelling
wk.add({
	{ "<leader>s", group = "[s]pelling" },
	{ "<leader>sa", "zg", desc = "[a]dd to dictionary" },
	{ "<leader>sn", "]s", desc = "[n]ext spelling error" },
	{ "<leader>sp", "[s", desc = "[p]revious spelling error" },
	{
		"<leader>ss",
		'<cmd>lua require("snacks").picker.spelling()<cr>',
		desc = "[s]uggestion",
	},
	{ "<leader>st", "<cmd>set spell!<cr>", desc = "[t]oggle spell check" },
})

-- Diagnostics
wk.add({
	{ "<leader>d", group = "[d]iagnostics" },
	{ "<leader>dP", "<cmd>Trouble diagnostics toggle <CR>", desc = "all [P]roject diagnostics" },
	{ "<leader>db", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "[b]uffer diagnostics" },
	{
		"<leader>dn",
		function()
			vim.diagnostic.jump({ count = 1, float = true })
		end,
		desc = "[n]ext diagnostic",
	},
	{
		"<leader>dp",
		function()
			vim.diagnostic.jump({ count = -1, float = true })
		end,
		desc = "[p]revious diagnostic",
	},
	{ "<leader>ds", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "[s]how diagnostic under cursor" },
})

-- LSP
wk.add({
	{ "<leader>l", group = "[l]sp" },
	{
		"<leader>lD",
		"<cmd>lua require('snacks').picker.lsp_definitions()<CR>",
		desc = "Go to [D]efinition",
	},
	{ "<leader>lI", "<cmd>checkhealth vim.lsp<cr>", desc = "[I]nformation about LSPs" },
	{ "<leader>lR", ":LspRestart ", desc = "[R]estart LSP" },
	{ "<leader>ld", "<cmd>Lspsaga peek_definition<CR>", desc = "Peek [d]efinition" },
	{ "<leader>lf", "<cmd>lua require('conform').format()<cr>", desc = "[F]ormat file" },
	{
		"<leader>lh",
		"<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>",
		desc = "Toggle lsp [h]ints",
	},
	{
		"<leader>li",
		"<cmd>lua require('snacks').picker.lsp_implementations()<CR>",
		desc = "Go to [i]mplementation",
	},
	{ "<leader>ln", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Re[n]ame" },
	{ "<leader>lr", "<cmd>Trouble lsp_references<cr>", desc = "Show [r]eferences" },
	{
		"<leader>lt",
		"<cmd>lua require('snacks').picker.lsp_type_definitions()<CR>",
		desc = "Go to [t]ype definition",
	},
	{ "<leader>le", "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "Go to d[e]claration" },
	{ "<leader>lk", "<cmd>lua vim.lsp.buf.signature_help()<CR>", desc = "Signature help ([k]) " },
	{ "<leader>lH", group = "[H]ierarchy" },
	{ "<leader>lHi", "<cmd>lua vim.lsp.buf.incoming_calls()<CR>", desc = "[i]ncoming calls" },
	{ "<leader>lHo", "<cmd>lua vim.lsp.buf.outgoing_calls()<CR>", desc = "[o]utgoing calls" },
	{ "<leader>lHs", "<cmd>lua vim.lsp.buf.typehierarchy('supertypes')<CR>", desc = "[s]upertypes" },
	{ "<leader>lHd", "<cmd>lua vim.lsp.buf.typehierarchy('subtypes')<CR>", desc = "subtypes ([d]erived)" },
	{ "<leader>lc", "<cmd>lua	require('tiny-code-action').code_action()<CR>", desc = "[c]ode actions" },
	{ "<leader>l", group = "LSP", mode = "v" },
	{ "<leader>lc", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "[c]ode actions", mode = "v" },
})

-- File managers
wk.add({
	{ "<leader>-", "<cmd>Yazi<cr>", desc = "File manager open in current dir" },
	{ "<leader><c-up>", "<cmd>Yazi toggle<cr>", desc = "Resume last yazi session" },
	{ "<leader>_", "<cmd>Yazi cwd<cr>", desc = "Open the file manager in nvim's working directory" },
})

-- Debugger
-- NOTE: commented out — the <leader>b / <space>b group was shadowing
-- dart-nvim's buffer-local "open run in browser" binding in the Dart window.
-- TODO: look at set_exception_breakpoint. Looks pretty sweet
--[==[
wk.add({
	{ "<leader>b", group = "De[b]ugger" },
	{
		"<leader>bB",
		"<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
		desc = "[B]reakpoint with condition",
	},
	{ "<leader>bT", "<cmd>DapViewToggle<cr>", desc = "[T]oggle debugger UI" },
	{ "<leader>bb", "<cmd>DapToggleBreakpoint<cr>", desc = "[b]reakpoint toggle current line" },
	{ "<leader>bc", "<cmd>DapContinue<cr>", desc = "Start / [c]ontinue debugger" },
	{ "<leader>bd", "<cmd>lua require'dap'.down()<CR>", desc = "[d]own stacktrace" },
	{ "<leader>be", "<cmd>DapViewWatch<cr>", desc = "[e]valuate / watch expression" },
	{ "<leader>bi", "<cmd>lua require'dap'.terminate()<cr>", desc = "[i]nterrupt debugger session" },
	{ "<leader>bl", group = "[l]ist" },
	-- BROKEN if revived: telescope (and telescope-dap) were removed from this
	-- config. snacks.picker has no DAP sources, so these five need either
	-- nvim-dap-view's own listings or a hand-rolled picker.
	{ "<leader>blC", "<cmd>Telescope dap configurations<cr>", desc = "[C]onfigurations" },
	{ "<leader>blb", "<cmd>Telescope dap list_breakpoints<cr>", desc = "[b]reakpoints" },
	{ "<leader>blc", "<cmd>Telescope dap commands<cr>", desc = "[c]ommands" },
	{ "<leader>blf", "<cmd>Telescope dap frames<cr>", desc = "[f]rames" },
	{ "<leader>blv", "<cmd>Telescope dap variables<cr>", desc = "[v]ariables" },
	{ "<leader>bn", "<cmd>lua require'dap'.step_over({askForTargets = true})<CR>", desc = "Step over ([n]ext)" },
	{ "<leader>bo", "<cmd>lua require'dap'.step_out()<CR>", desc = "Step [o]ut" },
	{ "<leader>bs", "<cmd>lua require'dap'.step_into()<CR>", desc = "[s]tep into" },
	{ "<leader>bt", "<cmd>DapViewToggle<cr>", desc = "[t]oggle debugger UI" },
	{ "<leader>bu", "<cmd>lua require'dap'.up()<CR>", desc = "[u]p stacktrace" },
	--- visual
	{ "<leader>b", group = "de[b]ugger", mode = "v" },
	{ "<leader>be", "<cmd>DapViewWatch<cr>", desc = "[e]valuate / watch expression", mode = "v" },
})
]==]

-- Terminal (terminals.nvim: up to 10 persistent slots with a tab-style header;
-- <C-S-j>/<C-S-k> cycle terminals, <M-0>…<M-9> jump to a slot — see
-- plugins/terminal.lua)
-- wk.add({
	-- { "<leader><leader>", group = "[t]erminal" },
-- })

-- pandoc
wk.add({
	{
		"<leader><leader>p",
		"<cmd>!pandoc -t beamer --pdf-engine=xelatex ~/nix_config/pandoc/pandoc_header --output=%:r.pdf<cr>",
		desc = "[p]andoc file into PDF presentation",
	},
})

vim.keymap.set({ "x", "o", "n" }, "<BS>", function()
	vim.treesitter.select("child", vim.v.count1)
end, { desc = "Select child node" })

vim.keymap.set({ "x", "o", "n" }, "<CR>", function()
	vim.treesitter.select("parent", vim.v.count1)
end, { desc = "Select parent node" })

vim.keymap.set({ "x", "o", "n" }, "<C-BS>", function()
	vim.treesitter.select("prev", vim.v.count1)
end, { desc = "Select previous node" })

vim.keymap.set({ "x", "o", "n" }, "<C-CR>", function()
	vim.treesitter.select("next", vim.v.count1)
end, { desc = "Select next node" })
