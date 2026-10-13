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
}
