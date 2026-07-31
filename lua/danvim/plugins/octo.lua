-- pwntester/octo.nvim — GitHub issues/PRs/reviews as Neovim buffers, backed by `gh`.
-- `gh` is provided via nix (flake.nix lspsAndRuntimeDeps) — run `gh auth login`
-- once outside Neovim to authenticate.
return {
	"pwntester/octo.nvim",
	cmd = "Octo",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"folke/snacks.nvim", -- picker backend: snacks is the primary picker in this config
	},
	opts = {
		picker = "snacks",
		use_local_fs = true, -- edit the actual files on disk during a review, not read-only GitHub blobs
	},
	keys = {
		{ "<leader>oi", "<cmd>Octo issue list<cr>", desc = "[i]ssue list" },
		{ "<leader>oI", "<cmd>Octo issue create<cr>", desc = "[I]ssue create" },
		{ "<leader>op", "<cmd>Octo pr list<cr>", desc = "[p]r list" },
		{ "<leader>oP", "<cmd>Octo pr create<cr>", desc = "[P]r create" },
		{ "<leader>oo", "<cmd>Octo pr checkout<cr>", desc = "check[o]ut pr" },
		{ "<leader>or", "<cmd>Octo review start<cr>", desc = "[r]eview start" },
		{ "<leader>oR", "<cmd>Octo review resume<cr>", desc = "[R]eview resume" },
		{ "<leader>on", "<cmd>Octo notification list<cr>", desc = "[n]otifications" },
		-- Comments: context-aware, act on the issue/PR/review-thread/diff under cursor.
		{ "<leader>oca", "<cmd>Octo comment add<cr>", desc = "[a]dd comment" },
		{ "<leader>ocs", "<cmd>Octo comment suggest<cr>", desc = "add [s]uggestion (review diff)" },
		{ "<leader>ocr", "<cmd>Octo comment reply<cr>", desc = "[r]eply to comment" },
		{ "<leader>ocd", "<cmd>Octo comment delete<cr>", desc = "[d]elete comment" },
		{ "<leader>oce", "<cmd>Octo comment edits<cr>", desc = "[e]dit history" },
		{ "<leader>ocu", "<cmd>Octo comment url<cr>", desc = "copy [u]rl" },
		{ "<leader>ocR", "<cmd>Octo comment reference<cr>", desc = "[R]eference in new issue" },
	},
}
