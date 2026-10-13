-- sets the cwd to the parent of the buffer that has a .git or Makefile
-- Didn't quite work for some reason. Try again in future
-- vim.api.nvim_create_autocmd("BufEnter", {
-- 	callback = function(ctx)
-- 		local root = vim.fs.root(ctx.buf, {".git", "Makefile"})
-- 		if root then vim.uv.chdir(root) end
-- 	end,
-- })

return {
	-- Braced: without the braces this table has several list entries, so lazy
	-- reads the whole file as a list of specs and silently drops lean.nvim's own
	-- `event`/`opts`/`dependencies` -- lean then loaded at startup and its setup()
	-- (abbreviations, infoview, mappings) never ran.
	{
		"Julian/lean.nvim",
		event = { "BufReadPre *.lean", "BufNewFile *.lean" },

		dependencies = {
			-- optional dependencies:

			-- 'nvim-telescope/telescope.nvim', -- for Lean-specific pickers
			-- 'andymass/vim-matchup',          -- for enhanced % motion behavior
			-- 'andrewradev/switch.vim',        -- for switch support
			-- 'tomtom/tcomment_vim',           -- for commenting
		},

		---@type lean.Config
		opts = { -- see the manual for full configuration options
			mappings = true,
		},
	},
	{
		"folke/which-key.nvim",
		-- Eager: it creates the keymaps in keybindings.lua that belong to no plugin
		lazy = false,
		-- keybindings.lua adds to `spec` from many fragments; lazy would otherwise
		-- keep only the last one
		opts_extend = { "spec" },
		opts = { preset = "modern" },
	},
	-- lazy = false: its key in keybindings.lua would otherwise make it load on
	-- first press, and :Maximize would not exist until then
	{ "declancm/maximize.nvim", lazy = false, config = true },
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		dependencies = {
			"gregorias/nvim-surround-wk", -- which-key hints for nvim-surround
		},
		opts = {
			highlight = {
				duration = 0, -- Highlight always on
			},
		},
	},
	-- Was a nix `start` plugin with no spec; now in `opt` so it needs one
	{ "mbbill/undotree", cmd = "UndotreeToggle" },
	-- Better quickfix window; only useful once a quickfix buffer exists
	{ "kevinhwang91/nvim-bqf", ft = "qf" },
	-- vim.ui.select/input replacement; load before avante would pull it in
	{ "stevearc/dressing.nvim", event = "VeryLazy", opts = {} },
	{
		"esmuellert/codediff.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		cmd = "CodeDiff",
		init = function()
			-- On first use codediff downloads a native `codediff-watcher` binary into
			-- its own plugin directory. Under nix that directory is the read-only
			-- store, and the installer's mkdir raises E739 (which also leaves its
			-- "installing" flag stuck) instead of falling back to polling. Skipping
			-- the download makes it poll from the start.
			if require("nixCatsUtils").isNixCats then
				vim.env.CODEDIFF_WATCHER_NO_AUTO_INSTALL = "1"
			end
		end,
	},
	-- Kept commented for the <C-S> note below, which is the expensive part to
	-- rediscover. flash-nvim is no longer in flake.nix (it was shipping to `opt`
	-- while this spec was off), so un-commenting this alone makes lazy git-clone
	-- it — add it back to the `always` category if you want it nix-managed.
	-- {
	-- 	"folke/flash.nvim",
	-- 	event = "VeryLazy",
	-- 	---@type Flash.Config
	-- 	opts = {},
	-- 	keys = {
	-- 		{
	-- 			"S",
	-- 			mode = { "n", "x", "o" },
	-- 			function()
	-- 				require("flash").jump()
	-- 			end,
	-- 			desc = "Flash",
	-- 		},
	-- 		{
	-- 			-- Restricted to visual/operator-pending modes so it no longer
	-- 			-- shadows the normal-mode <C-s><C-s> "save buffer" chord
	-- 			-- (terminals deliver <C-S> identically to <C-s>).
	-- 			"<c-S>",
	-- 			mode = { "x", "o" },
	-- 			function()
	-- 				require("flash").treesitter()
	-- 			end,
	-- 			desc = "Flash Treesitter",
	-- 		},
	-- 		{
	-- 			"<c-s>",
	-- 			mode = { "c" },
	-- 			function()
	-- 				require("flash").toggle()
	-- 			end,
	-- 			desc = "Toggle Flash Search",
	-- 		},
	-- 	},
	-- },
}
