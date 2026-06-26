return {
	{
		"mikavilpas/yazi.nvim",
		event = "VeryLazy",
		opts = {
			-- if you want to open yazi instead of netrw, see below for more info
			open_for_directories = false,
			keymaps = {
				show_help = "<f1>",
				["<c-g>"] = function()
					require('danvim.yazi_fuzzy_open').fuzzy_open()
				end,
				replace_in_directory = false, -- explicit unset for other code
			},
		},
	},
	{
		"A7Lavinraj/fyler.nvim",
		dependencies = { "nvim-mini/mini.icons" },
		branch = "stable",
		opts = {
			default_explorer = true, -- replace netrw
			-- Key mappings
			mappings = {
				["q"] = "CloseView",
				["<CR>"] = "Select",
				["<C-t>"] = "SelectTab",
				["|"] = "SelectVSplit",
				["-"] = "SelectSplit",
				["^"] = "GotoParent",
				["="] = "GotoCwd",
				["."] = "GotoNode",
				["#"] = "CollapseAll",
				["<BS>"] = "CollapseNode",
			},
		},
	},
}
