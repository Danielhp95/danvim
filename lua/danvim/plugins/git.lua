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
	{ -- Review Pull requests in neovim
		"emrearmagan/atlas.nvim",
		-- lazy = false: its key in keybindings.lua would otherwise make it load on
		-- first press, and :Atlas would not exist until then
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- optional but recommended
			"esmuellert/codediff.nvim", -- optional (PullRequest diff)
			"dlyongemallo/diffview-plus.nvim",
		},
		opts = {
			ui = {
				picker = "auto",
			},

			providers = {
				github = {
					cache_ttl = 300,
				},
			},

			pulls = {
				diff = {
					lsp = {
						enabled = true,
					},
				},
				github = {
					views = {
						{
							name = "My PRs",
							key = "1",
							layout = "plain",
							search = "author:@me is:open sort:updated-desc",
						},
						{
							name = "Review requested",
							key = "2",
							layout = "compact",
							search = "is:open review-requested:@me",
						},
						{
							name = "Created by me",
							key = "3",
							layout = "grouped",
							search = "author:@me sort:updated-desc",
						},
					},

					bookmarks = {
						key = "S",
						label = "Search",
						items = {
							["Drafts"] = "is:pr is:draft author:@me",
							["Recently merged"] = "is:pr is:merged author:@me sort:updated-desc",
							["Needs my review"] = "is:open review-requested:@me",
						},
					},
				},
			},

			issues = {
				github = {
					views = {
						{
							name = "Assigned to me",
							key = "1",
							layout = "plain",
							search = "assignee:@me is:open",
						},
						{
							name = "Created by me",
							key = "2",
							layout = "compact",
							search = "author:@me is:open",
						},
						{
							name = "Mentioned",
							key = "3",
							layout = "plain",
							search = "mentions:@me is:open",
						},
					},

					bookmarks = {
						key = "S",
						label = "Search",
						items = {
							["Bugs"] = "is:issue is:open label:bug",
							["Recently closed"] = "is:issue is:closed author:@me sort:updated-desc",
						},
					},
				},
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		-- Explicit: gitsigns derives these from 'diffopt' via ipairs, but
		-- nightly's vim.opt.diffopt:get() returns a map, so it silently falls
		-- back to external `git diff`, which diff.external=difft hijacks.
		opts = { diff_opts = { internal = true, linematch = 40 } },
	},
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
	-- default keymaps — the fork exposes :GitLink instead, so the bindings in
	-- keybindings.lua are now explicit. <leader>gy is the same yank key ruifm's
	-- registered; the browse key moves off <leader>gb, which gitsigns blame_line
	-- already owns there and was silently fighting gitlinker for.
	{
		"linrongbin16/gitlinker.nvim",
		cmd = "GitLink",
		opts = {},
	},
}
