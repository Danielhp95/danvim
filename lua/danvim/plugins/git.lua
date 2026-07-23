return {
	{ "tpope/vim-fugitive", event = "VeryLazy" },
	{ -- Treesitter-powered Diff Syntax highlighting for Neovim
		"barrettruth/diffs.nvim",
		event = "VeryLazy",
		init = function()
			vim.g.diffs = {
				integrations = {
					fugitive = true,
					neogit = true,
					neojj = true,
					gitsigns = true,
				},
			}
		end,
	},
	{ "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, opts = {} },
	{
		"sindrets/diffview.nvim",
		cmd = {
			"DiffviewOpen",
			"DiffviewOpenConflicts",
			"DiffviewFileHistory",
			"DiffviewClose",
			"DiffviewRefresh",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewLog",
		},
		opts = {
			view = {
				merge_tool = {
					layout = "diff3_mixed",
				},
			},
			hooks = {
				-- During a merge, the "Changes" section of the file panel is
				-- noise (it duplicates the working tree diff); the only thing
				-- that matters is "Conflicts". Auto-collapse it.
				view_opened = function(view)
					local panel = view.panel
					if not panel or not panel.files or #panel.files.conflicting == 0 then
						return
					end

					vim.schedule(function()
						if not panel.winid or not vim.api.nvim_win_is_valid(panel.winid) then
							return
						end

						for i, line in ipairs(vim.api.nvim_buf_get_lines(panel.bufid, 0, -1, false)) do
							if line:match("^Changes ") then
								vim.api.nvim_win_call(panel.winid, function()
									vim.fn.foldclose(i)
								end)
								break
							end
						end
					end)
				end,
			},
		},
		config = function(_, opts)
			require("diffview").setup(opts)

			-- Like :DiffviewOpen, but if mid-merge, jumps straight to the
			-- first conflicted file instead of landing on whatever sorts first.
			vim.api.nvim_create_user_command("DiffviewOpenConflicts", function()
				local conflicted = vim.fn.systemlist("git diff --name-only --diff-filter=U")
				if vim.v.shell_error == 0 and conflicted[1] and conflicted[1] ~= "" then
					vim.cmd("DiffviewOpen --selected-file=" .. vim.fn.fnameescape(conflicted[1]))
				else
					vim.cmd("DiffviewOpen")
				end
			end, {})
		end,
	},
	{
		"rbong/vim-flog",
		lazy = true,
		cmd = { "Flog", "Flogsplit", "Floggit" },
		dependencies = {
			"tpope/vim-fugitive",
		},
	},
	{
		"ruifm/gitlinker.nvim",
		event = "VeryLazy",
		dependencies = {
			"ojroques/vim-oscyank",
			"nvim-lua/plenary.nvim",
		},
		opts = {},
	},
	{
		"oribarilan/lensline.nvim",
		event = "LspAttach",
		opts = {
			-- placement = 'inline',
			profiles = {
				{
					name = "default",
					providers = {
						{
							name = "references",
							enabled = true, -- enable references provider
							quiet_lsp = true, -- suppress noisy LSP log messages (e.g., Pyright reference spam)
						},
						{
							name = "last_author",
							enabled = true, -- enabled by default with caching optimization
							cache_max_files = 50, -- maximum number of files to cache blame data for (default: 50)
						},
						{
							name = "complexity",
							enabled = true,
							min_level = "L", -- only show L and XL complexity (default)
						},
					},
				},
			},
		},
	},
}
