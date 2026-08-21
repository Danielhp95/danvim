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
		-- Maintained fork of sindrets/diffview.nvim (dead since 2024-06-13).
		-- The name matters beyond cosmetics: nixCats' dev.path resolver looks up
		-- pack/myNeovimPackages/opt/<spec name>, so leaving this as
		-- "sindrets/diffview.nvim" makes lazy miss the nix package and silently
		-- git-clone the dead upstream instead. Commands, opts and the module
		-- name (`require("diffview")`) are unchanged by the fork.
		"dlyongemallo/diffview-plus.nvim",
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
	-- Maintained fork of ruifm/gitlinker.nvim (last commit 2024-05-02). Not in
	-- nixpkgs (which still packages ruifm's), so this one is lazy-cloned rather
	-- than nix-managed.
	--
	-- Three things went away with the fork: plenary (it spawns via uv directly),
	-- vim-oscyank (Neovim ships vim.ui.clipboard.osc52 since 0.10), and the
	-- default keymaps — the fork exposes :GitLink instead, so the bindings below
	-- are now explicit. <leader>gy is the same yank key ruifm's registered; the
	-- browse key moves off <leader>gb, which gitsigns blame_line already owns in
	-- keybindings.lua and was silently fighting gitlinker for.
	{
		"linrongbin16/gitlinker.nvim",
		cmd = "GitLink",
		opts = {},
		keys = {
			{ "<leader>gy", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "[y]ank git permalink" },
			{ "<leader>gY", "<cmd>GitLink!<cr>", mode = { "n", "v" }, desc = "[Y] open git permalink" },
		},
	},
}
