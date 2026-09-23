local p = require("danvim.palette")

return {
	{
		"ember-theme/nvim",
		config = function()
			require("ember").setup({
				on_highlights = function(hl, theme)
					local syn = theme.syn

					-- The upstream theme's palette has drifted from palette.nix, which
					-- is what tmux, starship, zsh and the terminals all render from.
					-- Two hues are off:
					--
					--   * sage is a shade colder here than the palette's.
					--   * rose does not exist in the system palette at all any more —
					--     tmux dropped it when its colours were generated from
					--     palette.nix, so nvim was the only thing still emitting it.
					--
					-- Rewriting them here rather than per-group catches every use,
					-- including groups this config never names.
					local drift = {
						["#80a090"] = p.sage,
						["#b07878"] = p.accentDim,
					}
					for _, spec in pairs(hl) do
						if type(spec) == "table" then
							for _, key in ipairs({ "fg", "bg", "sp" }) do
								local corrected = type(spec[key]) == "string" and drift[spec[key]:lower()]
								if corrected then
									spec[key] = corrected
								end
							end
						end
					end

					-- Bold visual selection (the ColorScheme autocmd in aucmds.lua
					-- can fire too late for the startup colorscheme)
					hl["Visual"] = { bg = theme.ui.visual, bold = true }

					-- Parameters get their own color (mauve — otherwise unused in syntax)
					hl["@variable.parameter"] = { fg = syn.mauve, italic = true }

					-- self/cls/this distinct from keywords. Banked coral rather than
					-- the hero coral the keywords themselves use: self *is*
					-- keyword-adjacent, so staying in the accent family reads
					-- correctly, and mauve is already spoken for above.
					hl["@variable.builtin"] = { fg = p.accentDim, italic = true }
					-- self/cls in a method signature (python captures these as parameter.builtin)
					hl["@variable.parameter.builtin"] = { fg = p.accentDim, italic = true }
					hl["@module.builtin"] = { fg = p.accentDim, italic = true }
					hl["@lsp.typemod.variable.defaultLibrary"] = { fg = p.accentDim, italic = true }

					-- self/cls/this inside method bodies — pyright/ty emit selfParameter
					-- and clsParameter token types; rust-analyzer emits selfKeyword
					hl["@lsp.type.selfParameter"] = { link = "@variable.builtin" }
					hl["@lsp.type.clsParameter"] = { link = "@variable.builtin" }
					hl["@lsp.type.selfKeyword"] = { link = "@variable.builtin" }

					-- Inlay hints. The theme leaves them on #3e3c38, which is 1.5:1
					-- against the buffer — legible only if you already know what it says.
					-- steel is palette.nix's neutral-metadata slot (paths, options, info)
					-- and a type hint is precisely that, so it lands at 4.6:1 without
					-- competing with the code it annotates — and its hue alone marks it
					-- as not-source, since nothing else in the buffer is steel.
					hl["LspInlayHint"] = { fg = p.steel }

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

					-- terminals.nvim's border is not a real 'border': it draws ╭─╮│╰╯ as
					-- *text* in a dedicated window sitting behind the terminal, and points
					-- both that window and the terminal window at `Normal:WindowBorder`.
					-- Colouring WindowBorder would therefore repaint every line of
					-- uncoloured shell output coral too, so the border window gets a group
					-- of its own (terminal.lua rewrites its winhighlight to this).
					--
					-- Same coral as PmenuThumb above — as fg, since here it really is text.
					-- The tab headers drawn into that window ride along with it.
					hl["TerminalsBorder"] = { fg = syn.coral }

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
					local border = p.accentDim

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

					-- nvim-dap signs (plugins/dap.lua). Coral for a plain breakpoint,
					-- gold for a conditional one (needs-attention), sage for a
					-- logpoint, muted for one the adapter rejected. The line
					-- execution is stopped on gets the hotter coral plus a graphite
					-- tint across the whole line.
					hl["DapBreakpoint"] = { fg = p.accent }
					hl["DapBreakpointCondition"] = { fg = p.gold }
					hl["DapLogPoint"] = { fg = p.sage }
					hl["DapBreakpointRejected"] = { fg = p.muted }
					hl["DapStopped"] = { fg = p.accentBright }
					hl["DapStoppedLine"] = { bg = p.surface }

					-- Kept for 'winborder' = "shadow"; inert for every other style.
					-- `blend` is the intensity knob: 0 = solid, 100 = invisible.
					hl["FloatShadow"] = { bg = border, blend = 80 }
					hl["FloatShadowThrough"] = { bg = border, blend = 85 }
				end,
			})
			vim.cmd.colorscheme("ember")

			-- Search highlight overrides: gray background, keep the
			-- underlying foreground (no fg), bold the matched text.
			local search = { fg = "NONE", bg = p.divider, bold = true }
			for _, group in ipairs({ "Search", "IncSearch", "CurSearch" }) do
				vim.api.nvim_set_hl(0, group, search)
			end

			-- :terminal renders through these, not through the theme's syntax
			-- colours, so without them a shell inside nvim disagrees with the same
			-- shell one keystroke away in kitty/ghostty. Same 16 slots, same order,
			-- same palette.nix values the terminals themselves are set from.
			local term = {
				p.bg,
				p.accent,
				p.olive,
				p.gold,
				p.steel,
				p.mauve,
				p.sage,
				p.fg,
				p.muted,
				p.accentBright,
				p.oliveBright,
				p.goldBright,
				p.steelBright,
				p.mauveBright,
				p.sageBright,
				"#ffffff",
			}
			for i, color in ipairs(term) do
				vim.g["terminal_color_" .. (i - 1)] = color
			end
		end,
	},
}
