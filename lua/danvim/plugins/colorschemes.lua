return {
	{
		"ember-theme/nvim",
		config = function()
			require("ember").setup({
				on_highlights = function(hl, theme)
					local syn = theme.syn

					-- Bold visual selection (the ColorScheme autocmd in aucmds.lua
					-- can fire too late for the startup colorscheme)
					hl["Visual"] = { bg = theme.ui.visual, bold = true }

					-- Parameters get their own color (mauve — otherwise unused in syntax)
					hl["@variable.parameter"] = { fg = syn.mauve, italic = true }

					-- self/cls/this distinct from keywords: rose instead of coral
					hl["@variable.builtin"] = { fg = syn.rose, italic = true }
					-- self/cls in a method signature (python captures these as parameter.builtin)
					hl["@variable.parameter.builtin"] = { fg = syn.rose, italic = true }
					hl["@module.builtin"] = { fg = syn.rose, italic = true }
					hl["@lsp.typemod.variable.defaultLibrary"] = { fg = syn.rose, italic = true }

					-- self/cls/this inside method bodies — pyright/ty emit selfParameter
					-- and clsParameter token types; rust-analyzer emits selfKeyword
					hl["@lsp.type.selfParameter"] = { link = "@variable.builtin" }
					hl["@lsp.type.clsParameter"] = { link = "@variable.builtin" }
					hl["@lsp.type.selfKeyword"] = { link = "@variable.builtin" }

					-- Scroll position indicators in coral, so "where am I in this list"
					-- reads at a glance. Both default to a muted #585550 that all but
					-- vanishes against the menu.
					--
					-- Set as `bg`, not `fg`: both thumbs are drawn as empty cells (blink's
					-- is a floating window with winhighlight=Normal:BlinkCmpScrollBarThumb),
					-- so there is no text for a foreground color to land on.
					--
					-- PmenuThumb covers Neovim's own popup menus — wildmenu, native
					-- ins-completion, anything not going through blink.
					--
					-- BlinkCmpScrollBarThumb defaults to linking at PmenuThumb, so it would
					-- inherit the coral anyway; it stays explicit so the menu doesn't
					-- quietly depend on blink's default link surviving. It covers both the
					-- insert-mode completion menu and the cmdline/search bar, since blink
					-- resolves cmdline.completion.* by falling back to completion.*.
					--
					-- blink only draws its scrollbar track when the menu border is
					-- 'none'/'padded'. 'winborder' is "rounded" again (options.lua), so the
					-- track is NOT drawn and the thumb paints straight onto the right border
					-- column. PmenuSbar is left at its dim theme default either way: it only
					-- shows on borderless menus, and a bright track would swallow the thumb.
					local thumb = { bg = syn.coral }
					hl["PmenuThumb"] = thumb
					hl["BlinkCmpScrollBarThumb"] = thumb

					-- Float border colour ('winborder' = "rounded", options.lua). Banked
					-- coral: mid-ramp, warm enough to belong to the palette without
					-- borrowing the hero coral that the thumb and accents already use.
					--
					-- The floor here is contrast, not taste. Kitty rasterizes ╭╮╰╯ itself as
					-- antialiased arcs rather than taking them from the font, so a border
					-- within a few percent lightness of the buffer loses its partial-coverage
					-- pixels and every corner degrades into a chamfer — which is exactly what
					-- the theme's own base3 (#2e2d2a on #1c1b19) did. Anything substituted
					-- here wants to stay well clear of the background for that reason.
					local border = "#b8654c"

					-- `bg` must follow the *buffer*, not the float, for the arc to read as
					-- the outer edge of the menu. A border cell is still a full rectangular
					-- cell: the area outside the ╭ curve gets painted with that cell's
					-- background, so with the theme's default (bg = NormalFloat = #151412)
					-- every rounded corner sits in a dark square that juts out past the
					-- curve. Matching Normal instead makes that leftover area identical to
					-- the surrounding buffer, so only the arc itself shows.
					--
					-- bg = "NONE" does NOT work here — it falls back to the float's own
					-- background rather than going transparent, i.e. straight back to the
					-- dark corners. Same trap if the theme's `transparent` option is ever
					-- turned on, since that makes theme.ui.bg == "NONE".
					local float_border = { fg = border, bg = theme.ui.bg }
					hl["FloatBorder"] = float_border

					-- blink does NOT read FloatBorder. Each of its windows sets a
					-- winhighlight that remaps it away — 'FloatBorder:BlinkCmpMenuBorder' for
					-- the menu, and the Doc/SignatureHelp equivalents — and those groups
					-- default to `Pmenu` and `NormalFloat` respectively (highlights.lua in
					-- blink.cmp). So without these three the completion menu keeps a
					-- Pmenu-coloured border no matter what FloatBorder says, which is exactly
					-- how the border looked unchanged while every other float updated.
					--
					-- Safe to define: blink sets its own links with `default = true`, so an
					-- explicit definition here wins and survives its ColorScheme autocmd.
					hl["BlinkCmpMenuBorder"] = float_border
					hl["BlinkCmpDocBorder"] = float_border
					hl["BlinkCmpSignatureHelpBorder"] = float_border

					-- Kept for 'winborder' = "shadow"; inert for every other style.
					-- `blend` is the intensity knob: 0 = solid, 100 = invisible.
					hl["FloatShadow"] = { bg = border, blend = 80 }
					hl["FloatShadowThrough"] = { bg = border, blend = 85 }
				end,
			})
			vim.cmd.colorscheme("ember")

			-- Search highlight overrides: gray background, keep the
			-- underlying foreground (no fg), bold the matched text.
			local search = { fg = "NONE", bg = "#4c4b49", bold = true }
			for _, group in ipairs({ "Search", "IncSearch", "CurSearch" }) do
				vim.api.nvim_set_hl(0, group, search)
			end
		end,
	},
	{ "serhez/teide.nvim", lazy = true },
	{ "initsyscall/themeInitNvim", lazy = true },
}
