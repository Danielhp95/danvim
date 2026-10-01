local p = require("danvim.palette")

-- One base colourscheme per palette family; the palette says which
-- (meta.family). `cond` keeps the others out of the session entirely: not
-- loaded and, where it is a git clone, not fetched.
--
-- No `priority` on purpose: the colourscheme keeps the place in lazy's start
-- order it has always had (snacks and lualine capture colours at their own
-- setup, so moving it changes what they see).
local family = p.meta.family

return {
	{
		"ember-theme/nvim",
		cond = family == "ember",
		config = function()
			require("danvim.theme.ember").load(p)
		end,
	},
	{
		-- In flake.nix as `tokyonight-nvim`; its pack dir is "tokyonight.nvim",
		-- which is the name lazy derives from this spec.
		"folke/tokyonight.nvim",
		cond = family == "tokyonight",
		config = function()
			require("danvim.theme.tokyonight").load(p)
		end,
	},
}
