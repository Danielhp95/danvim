-- sets the cwd to the parent of the buffer that has a .git or Makefile
-- Didn't quite work for some reason. Try again in future
-- vim.api.nvim_create_autocmd("BufEnter", {
-- 	callback = function(ctx)
-- 		local root = vim.fs.root(ctx.buf, {".git", "Makefile"})
-- 		if root then vim.uv.chdir(root) end
-- 	end,
-- })

return {
	"folke/which-key.nvim",
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
	{
		"kylechui/nvim-surround",
		dependencies = {
			"gregorias/nvim-surround-wk", -- which-key hints for nvim-surround
		},
		opts = {
			highlight = {
				duration = 0, -- Highlight always on
			},
		},
	},
	{
		"esmuellert/codediff.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		cmd = "CodeDiff",
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {},
		keys = {
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				-- Restricted to visual/operator-pending modes so it no longer
				-- shadows the normal-mode <C-s><C-s> "save buffer" chord
				-- (terminals deliver <C-S> identically to <C-s>).
				"<c-S>",
				mode = { "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"<c-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},
}
