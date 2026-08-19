-- The "Ember" palette — warm graphite with a coral spark.
--
-- SOURCE OF TRUTH IS ~/nix_config/palette.nix. This file is a hand-kept mirror,
-- not a generated one: danvim is a standalone flake (flake.nix sets
-- `luaPath = "${./.}"`), so nothing under danvim/ can reach a path above it.
-- Keep the two in sync by hand — palette.nix already carries the same
-- arrangement for kitty/kitty.conf, ghostty/default.nix and hyprland.lua, and
-- lists this file among its consumers.
--
-- Attribute names match palette.nix exactly, so a value can be traced across
-- the two files by name alone. Values here carry the leading '#' that Neovim
-- highlight definitions want.
--
-- Semantics are load-bearing and shared with tmux/starship/zsh — see the
-- comments in palette.nix. In short: one semantic slot per hue, coral is the
-- rationed hero, gold means needs-attention-not-broken, error means failure
-- only and never rides on hue alone.

return {
	-- Surfaces, darkest to lightest.
	bgDeep = "#141312", -- sidebars, sunken areas
	bg = "#1c1b19", -- default background; also the statusline "canvas"
	bgAlt = "#242320", -- cards, status bars, secondary surfaces
	surface = "#2a2825", -- hovered/selected rows; the graphite pill background
	border = "#3a342d",
	divider = "#4c4b49", -- thin separators drawn on top of surface

	-- Text.
	fg = "#d8d0c0",
	fgSoft = "#b8b0a0", -- secondary text one step above fgDim (branch names, window titles)
	fgDim = "#9a9288",
	muted = "#6e6a66", -- disabled text, bright-black

	-- Accent — the coral. accentBright is a real lightness step above accent
	-- (7.5:1 vs 6.1:1 on bg), not a saturation push, so the "hotter" variant
	-- survives red-green colour-blindness.
	accent = "#e08060",
	accentBright = "#ff8f66",
	accentDim = "#b8654c",
	ash = "#8a5a3c", -- burnt-umber ramp tail (flame trails); decorative only — 3:1 on bg

	-- Secondary hues, shared with the terminal palette. olive = strings/success,
	-- gold = emphasis-and-attention (ration it: at 8.4:1 it outshines accent),
	-- steel = quiet metadata (inlay hints, info diagnostics, ANSI blue slot),
	-- mauve = language structure, sage = injected/dynamic values, error =
	-- failures only. "steel" is a historical name — the slot held a steel blue
	-- until 2026-08, when it became magma orange; the name stays because every
	-- consumer and palette.nix reference it. Magma is near-equiluminant with
	-- accent (1.05:1), so never use it to contrast against coral.
	olive = "#8a9868",
	gold = "#c8b468",
	steel = "#ef7f38",
	mauve = "#988090",
	sage = "#7aa88a",
	error = "#e05252",

	-- Bright ANSI companions (color9-14 in terminal palettes) — same hue as
	-- their normal counterpart above, lightened + saturated the way
	-- accentBright steps up from accent. Terminal-only; not used elsewhere,
	-- and in particular not by the statusline.
	oliveBright = "#acc66d",
	goldBright = "#e3cc75",
	steelBright = "#fb9c5f",
	mauveBright = "#c586b0",
	sageBright = "#84d19f",
}
