-- color-refs.nvim — swatches on colour *references*, not only colour literals.
--
-- The reason this exists: palette.lua defines every colour once and the rest of
-- the config only ever writes `p.accent`, so a normal colourizer puts swatches
-- on exactly one file and none on the twenty that consume it. `modules` below
-- is what closes that gap — it lets the plugin read the palette table out of the
-- running Neovim to resolve `p.<name>` at each use site.
--
-- Sourced from a working copy rather than from nix while it is being written
-- (`dev = true` + an absolute `dir`, so lazy does not look for it under
-- pack/myNeovimPackages/opt and does not fall back to git-cloning it). Once it
-- is pushed, swap `dir`/`dev` for the GitHub spec and add it to flake.nix
-- alongside the other plugins.

return {
	{
		"color-refs.nvim",
		dir = vim.fn.expand("~/Projects/color-refs.nvim"),
		dev = true,
		event = { "BufReadPost", "BufNewFile" },
		cmd = "ColorRefs",
		opts = {
			modules = { "danvim.palette" },
		},
	},
}
