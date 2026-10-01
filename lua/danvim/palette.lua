-- The palette every piece of danvim chrome is painted from.
--
-- Built by nix_config, the selected palette arrives through the nixCats
-- wrapper: ~/nix_config/danvim.nix overrides this package with an
-- `extra.palette` built from palette.nix, read here as
-- `nixCats.extra("palette")`. A palette change is then a rebuild of the wrapper
-- only; nothing in this repo is edited.
--
-- Without that override (`nix run ./danvim`, the non-nix mock in
-- nixCatsUtils, anyone using the public repo) `extra` is empty and the
-- embedded Ember table below is used.
--
-- Shape, whichever source it came from:
--   25 colour slots, '#rrggbb', named exactly as in palette.nix;
--   `orange` and `cyan`, two hues outside the slots that the tokyonight
--   family's syntax needs (required for that family, unused by ember);
--   ansi  = 16 colours, terminal slots 0-15 in order;
--   meta  = { name, slug, family }, family naming the base colourscheme
--           ("ember" | "tokyonight", see plugins/colorschemes.lua).
--
-- Slot semantics are shared with tmux/starship/zsh; see palette.nix.

---@class danvim.Palette
local ember = {
	-- Surfaces, darkest to lightest.
	bgDeep = "#141312", -- sidebars, sunken areas
	bg = "#1c1b19", -- default background; also the statusline "canvas"
	bgAlt = "#242320", -- cards, status bars, secondary surfaces
	surface = "#2a2825", -- hovered/selected rows; the graphite pill background
	border = "#3a342d",
	divider = "#4c4b49", -- thin separators drawn on top of surface

	-- Text.
	fg = "#d8d0c0",
	fgSoft = "#b8b0a0",
	fgDim = "#9a9288",
	muted = "#6e6a66", -- disabled text, bright-black

	-- Accent ramp, darkest to lightest: ash < accentDim < accent < accentBright.
	accent = "#e08060",
	accentBright = "#ff8f66",
	accentDim = "#b8654c",
	ash = "#8a5a3c", -- ramp tail; decorative only

	-- One semantic slot per hue.
	olive = "#8a9868",
	gold = "#c8b468",
	steel = "#ef7f38",
	mauve = "#988090",
	sage = "#7aa88a",
	error = "#e05252",

	-- Bright ANSI companions.
	oliveBright = "#acc66d",
	goldBright = "#e3cc75",
	steelBright = "#fb9c5f",
	mauveBright = "#c586b0",
	sageBright = "#84d19f",
}

-- stylua: ignore
ember.ansi = {
	ember.bg, ember.accent, ember.olive, ember.gold,
	ember.steel, ember.mauve, ember.sage, ember.fg,
	ember.muted, ember.accentBright, ember.oliveBright, ember.goldBright,
	ember.steelBright, ember.mauveBright, ember.sageBright, "#ffffff",
}
ember.meta = { name = "Ember", slug = "ember", family = "ember" }

local injected = nixCats.extra("palette")
if type(injected) ~= "table" or type(injected.bg) ~= "string" then
	return ember
end

-- A palette from nix is used whole, never merged with Ember slot by slot: a
-- half-violet, half-coral editor would hide a missing slot. A missing slot
-- fails here, at startup, with its name.
for slot in pairs(ember) do
	if injected[slot] == nil then
		error(("danvim.palette: nix palette %q has no `%s`"):format(
			vim.tbl_get(injected, "meta", "name") or "?", slot))
	end
end
-- Falling back here would be silent and ugly: types and constants in
-- near-white.
if injected.meta.family == "tokyonight" then
	for _, slot in ipairs({ "orange", "cyan" }) do
		if type(injected[slot]) ~= "string" then
			error(("danvim.palette: nix palette %q is of the tokyonight family and has no `%s`"):format(
				injected.meta.name or "?", slot))
		end
	end
end
return injected
