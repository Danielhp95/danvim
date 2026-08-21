local p = require("danvim.palette")

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Ember chrome — the statusline and buffer list speak the same language as the │
-- │ tmux status bar (tmux/tmux.conf) and the starship prompt                     │
-- │ (starship/default.nix). Three rules, shared across all three tools:          │
-- │                                                                              │
-- │  1. Everything is a pill: cap_l … cap_r, floating one space apart on a       │
-- │     transparent bar. The caps are *foreground* glyphs on the canvas colour,  │
-- │     never a background — anything that re-backgrounds a cap cell shears the  │
-- │     bubble open (tmux learned this the hard way; see the                     │
-- │     window-status-activity-style note in tmux.conf).                         │
-- │  2. The bar heats up along ash → accentDim → accent → accentBright, chained  │
-- │     with `arrow`. tmux bookends its bar with the session slab and the clock; │
-- │     starship with the directory and the clock; here it is the mode and the   │
-- │     cursor position.                                                         │
-- │  3. Context sits in graphite (`surface`) so the coral stays the one thing    │
-- │     your eye lands on.                                                       │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- Glyph vocabulary, shared verbatim with tmux and starship. Written as \u{}
-- escapes rather than literal bytes: Neovim's LuaJIT accepts Lua 5.2 escapes,
-- and a codepoint documents itself where a private-use glyph is both invisible
-- in a diff and prone to being silently mangled in transit.
local g = {
	cap_l = "\u{E0B6}", -- ple-left_half_circle_thick  — opens a pill
	cap_r = "\u{E0B4}", -- ple-right_half_circle_thick — closes a pill
	arrow = "\u{E0B0}", -- pl-right_hard_divider       — one step of the heat ramp

	git = "\u{F02A2}", -- starship git_branch, tmux status-right
	added = "\u{F0415}", -- starship untracked
	modified = "\u{F0238}", -- starship modified
	removed = "\u{F01B4}", -- starship deleted
	maximized = "\u{F0293}", -- tmux window_zoomed_flag
	recording = "\u{F044A}", -- md-record

	diag_error = "\u{F015A}",
	diag_warn = "\u{F002A}",
	diag_info = "\u{F02FD}",
	diag_hint = "\u{F0336}",
}

-- The dormant alternates (dracula, onedark, catppuccin, nightfox) were dropped
-- in the 2026-08 dead-weight pass — ember has been the only colorscheme loaded
-- since it landed, and each dormant one was still a clone lazy had to manage.
-- They were `lazy = true` one-liners; re-add one here if you want to try it.
local ColorSchemes = {
	"nvim-tree/nvim-web-devicons",
}

local BufferLine = {
	"akinsho/bufferline.nvim",
	-- No room for a buffer bar inside browser text areas
	cond = not vim.g.started_by_firenvim,
	config = function(_, opts)
		-- The buffer list and tmux's window list are the same mental object, so
		-- they get the same pill. Bufferline can't be handed the round caps
		-- directly: given a table, `separator_style` yields a *single* separator
		-- chosen by focus state rather than a left/right pair (ui.lua's
		-- get_separator — the manual is wrong about this), and only the named
		-- "slant"-family styles route through the per-state separator_selected /
		-- separator_visible / separator highlights this design needs. So keep the
		-- style name and swap the characters underneath it.
		--
		-- Order is { right, left }: get_separator returns `chars[1], chars[2]` and
		-- the caller destructures that as `local right_sep, left_sep = …`.
		require("bufferline.constants").sep_chars.slope = { g.cap_r, g.cap_l }
		require("bufferline").setup(opts)

		-- Close the gap bufferline leaves between the opening cap and the pill.
		--
		-- ui.lua's add_indicator does `local symbol, highlight = padding, nil` and
		-- then returns early for every slant-family separator_style — before the
		-- lines that actually work out the highlight. So each buffer gets a pad
		-- with no highlight at all, which inherits the run before it: the opening
		-- cap, whose background must be the canvas for the cap to read as round.
		-- The result is one canvas-coloured column wedged inside every pill.
		--
		-- Neither end is reachable from config (add_indicator is a module local,
		-- and `padding` is aliased at load time), but the tabline is ultimately
		-- just a statusline string, so the pad can be re-highlighted on the way
		-- out. If bufferline ever fixes this upstream the substitution simply
		-- re-applies the group the pad already has.
		local render = _G.nvim_bufferline
		local pill_of = { [""] = "BufferLineBackground", Visible = "BufferLineBufferVisible" }
		_G.nvim_bufferline = function()
			local ok, out = pcall(render)
			if not ok or type(out) ~= "string" then
				return render()
			end
			out = out:gsub("%%#BufferLineSeparator(%a*)#(" .. g.cap_l .. ") ", function(state, cap)
				return ("%%#BufferLineSeparator%s#%s%%#%s# "):format(
					state,
					cap,
					pill_of[state] or ("BufferLineBuffer" .. state)
				)
			end)
			-- Air between tab pills. tabpages.lua renders cap·name·cap with
			-- nothing between neighbours, so adjacent tab pills sit cap against
			-- cap; one canvas cell before every opening cap restores the
			-- one-space float every other pill gets. Before the *first* tab it
			-- lands on the %= fill and is invisible. (The buffer gsub above
			-- can't collide with this one: its pattern anchors on
			-- BufferLineSeparator right after the #, and tabs use
			-- BufferLineTabSeparator.)
			return (
				out:gsub(
					"%%#BufferLineTabSeparator(%a*)#" .. g.cap_l,
					"%%#BufferLineFill# %%#BufferLineTabSeparator%1#" .. g.cap_l
				)
			)
		end
	end,
	opts = {
		options = {
			separator_style = "slope",
			-- The index, like tmux's #I.
			numbers = "ordinal",
			-- No `indicator` here on purpose: ui.lua's add_indicator early-returns
			-- a bare pad for every slant-family separator_style, and `slope` is
			-- what the round caps ride on. The active buffer is marked by the
			-- coral label on buffer_selected below instead.

			-- Show where the file actually is, not just its basename. `:~:.` gives
			-- a path relative to :pwd when the file is under it, and a ~-relative
			-- one otherwise, so the common case stays short.
			name_formatter = function(buf)
				local path = vim.fn.fnamemodify(buf.path, ":~:.")
				if path == "" then
					return buf.name
				end
				-- Over-long paths lose leading components one at a time, exactly
				-- like starship's directory pill and with the same `…/` marker —
				-- rather than `pathshorten`, which crushes every component to a
				-- single letter and turns danvim/lua/danvim/plugins into d/l/d/p.
				local parts = vim.split(path, "/", { plain = true })
				while #parts > 2 and vim.fn.strchars(path) > 28 do
					table.remove(parts, 1)
					path = "…/" .. table.concat(parts, "/")
				end
				return path
			end,
			max_name_length = 32,
			max_prefix_length = 20,
			modified_icon = g.modified,
			-- Remove close icons as I never use them. The tab-list one must go
			-- via show_close_icon: close_icon = "" only empties the glyph, and
			-- ui.lua still pads the empty cell into a two-space blob hanging
			-- off the last tab pill.
			buffer_close_icon = "",
			show_close_icon = false,
		},
		-- Every pill is graphite; state is carried by depth, text colour and the
		-- coral indicator rather than by a saturated fill.
		--
		-- This is where the buffer list stops being a literal copy of tmux's
		-- window row, and deliberately. tmux marks one active window inside a bar
		-- it shares with everything else; here the row is nothing *but* buffers,
		-- so the same coral fill covers far more of the screen and dominates it.
		-- It also makes filetype icons impossible: nothing legible sits on a
		-- saturated coral (a palette-hued icon lands at 1.2:1, the default cream
		-- at 1.9:1), whereas on graphite the same icons read around 4.4:1. The
		-- palette logic is unchanged — coral still marks the active thing — it is
		-- just rationed to a glyph and the label instead of the whole slab.
		highlights = {
			-- The canvas the pills float on.
			fill = { bg = p.bg },

			-- Inactive — the deepest, quietest pill.
			-- NOTE: the inactive buffer's text group is `background`, not `buffer`.
			background = { fg = p.fgDim, bg = p.surface },
			numbers = { fg = p.muted, bg = p.surface },
			modified = { fg = p.gold, bg = p.surface },
			duplicate = { fg = p.muted, bg = p.surface, italic = true },
			separator = { fg = p.surface, bg = p.bg },
			-- The close icon is blanked above, but bufferline still emits its cell.
			-- Left at the theme default it carries a *different* background and
			-- punches a hole straight through the pill, one column before the
			-- closing cap. It has to inherit whatever the pill is sitting on.
			close_button = { fg = p.surface, bg = p.surface },

			-- Open in another split — the brightest pill, top of the surface ramp.
			buffer_visible = { fg = p.fgSoft, bg = p.divider },
			numbers_visible = { fg = p.fgDim, bg = p.divider },
			modified_visible = { fg = p.gold, bg = p.divider },
			duplicate_visible = { fg = p.fgDim, bg = p.divider, italic = true },
			separator_visible = { fg = p.divider, bg = p.bg },
			close_button_visible = { fg = p.divider, bg = p.divider },

			-- The current buffer — coral, bold, and nothing else. No underline and
			-- no fill: with every pill graphite, hue alone is enough to pick it out,
			-- and it keeps the coral rationed the way palette.nix asks for.
			buffer_selected = { fg = p.accent, bg = p.border, bold = true, italic = false },
			numbers_selected = { fg = p.accentDim, bg = p.border },
			modified_selected = { fg = p.gold, bg = p.border },
			duplicate_selected = { fg = p.accentDim, bg = p.border, italic = true },
			separator_selected = { fg = p.border, bg = p.bg },
			close_button_selected = { fg = p.border, bg = p.border },

			-- The tab list, top right. Same grammar as the buffers — a graphite
			-- pill at rest, and the current tab wears exactly the current
			-- buffer's colours, so "which tab" and "which buffer" are the same
			-- question answered in the same coral. The round caps come free:
			-- tabpages.lua routes tabs through the same slope sep_chars swapped
			-- above.
			--
			-- One step further up the surface ramp than the buffer pills
			-- (surface -> border, border -> divider), and only here: a tab pill is
			-- one or two characters wide, so where a 30-column buffer label gets
			-- its edges for free, a lone "2" at 1.17:1 against the canvas had
			-- nothing left to read as a pill at all. The selected tab's label rises
			-- with it — accent on divider is 3.08:1, and accentBright buys the step
			-- back (3.89:1) without leaving the coral.
			tab = { fg = p.fgDim, bg = p.border },
			tab_separator = { fg = p.border, bg = p.bg },
			tab_selected = { fg = p.accentBright, bg = p.divider, bold = true },
			tab_separator_selected = { fg = p.divider, bg = p.bg },

			trunc_marker = { fg = p.fgDim, bg = p.bg },
		},
	},
}

-- ── lualine ──────────────────────────────────────────────────────────────────

-- The mode slab is the one piece of state nvim shares with the other two tools.
-- Two of these are exact cross-tool rhymes: VISUAL is gold because tmux paints
-- its copy-mode badge gold (same act, selecting text), and COMMAND is the hot
-- coral because that is what tmux paints its session slab while the prefix is
-- held (same act, waiting on a key).
local function slab(bg)
	return { fg = p.bg, bg = bg, gui = "bold" }
end

-- Sections b/c/x/y are the *canvas*: they must match the buffer background so
-- each pill's caps render as fg-on-transparent. This is load-bearing —
-- lualine drops a separator outright when the two backgrounds it joins are
-- equal, which is exactly what makes a pill's caps appear against the canvas
-- and vanish between two touching graphite pills (see the git pill below).
local canvas = { fg = p.fgDim, bg = p.bg }

local theme = {
	normal = { a = slab(p.accent), b = canvas, c = canvas },
	insert = { a = slab(p.olive) },
	visual = { a = slab(p.gold) },
	replace = { a = slab(p.error) },
	command = { a = slab(p.accentBright) },
	terminal = { a = slab(p.sage) },
	inactive = { a = canvas, b = canvas, c = canvas },
}

-- A graphite context pill.
local pill = { bg = p.surface, fg = p.fgSoft }
local caps = { left = g.cap_l, right = g.cap_r }

-- One cell of canvas. Pills need air between them or their touching caps
-- collapse into each other (see `canvas` above); this is tmux's
-- `window-status-separator " "`.
local function spacer(cond, sep)
	return {
		function()
			return " "
		end,
		cond = cond,
		separator = sep,
		color = { bg = p.bg },
		padding = 0,
	}
end

-- One step of the heat ramp: no text, just a colour the neighbouring arrows can
-- transition through. `draw_empty` keeps lualine from discarding a component
-- that renders nothing, which is the whole point of these.
--
-- Always chain these with a `right` separator, on *both* ends of the bar. The
-- arrow is right-pointing, so its filled body has to be the colour of the
-- segment on its left and its corners the colour of the segment on its right —
-- what tmux writes literally as `#[fg=<previous>]#[bg=<next>]`. lualine's
-- `right` separator resolves to exactly that (fg = own bg, bg = the following
-- component's bg). Its `left` separator is the mirror image, meant for
-- left-pointing glyphs; using it here paints each arrow in the *next* colour
-- over the *previous* one and the whole ramp reads inside out.
local function ramp(bg, sep)
	return {
		function()
			return ""
		end,
		draw_empty = true,
		padding = 0,
		color = { bg = bg },
		separator = sep,
		cond = function()
			-- The ramp is only 2 cells, but a narrow split has nothing to spare.
			-- Dropping it leaves the slab's single arrow behind, which still reads
			-- as a (very short) flame trail rather than breaking the language.
			return vim.api.nvim_win_get_width(0) >= 80
		end,
	}
end

local function is_maximized()
	return vim.t.maximized ~= nil and vim.t.maximized ~= false
end

-- cmdheight=0 (options.lua) eats nvim's own "recording @q" message, so the bar
-- has to carry it. A filled slab rather than a graphite pill: this is a live
-- mode you are *in*, like the mode slab, not a fact about the buffer — and the
-- one thing worth interrupting the coral's rationing for, because a macro left
-- recording silently swallows every key you type next.
local function recording_register()
	return vim.fn.reg_recording()
end

local function is_recording()
	return recording_register() ~= ""
end

local LuaLine = {
	"nvim-lualine/lualine.nvim",
	-- laststatus=0 in firenvim; lualine would force the statusline back on
	cond = not vim.g.started_by_firenvim,
	opts = {
		options = {
			icons_enabled = true,
			theme = theme,
			-- Every pill carries its own caps, so nothing is inherited here.
			-- lualine only synthesizes a section-boundary separator for components
			-- whose own `separator` is not a table, and none of ours qualify.
			component_separators = "",
			section_separators = { left = "", right = "" },
			globalstatus = false,
		},
		sections = {
			-- Left bookend: the hot slab, then the flame trail cooling off the back
			-- of it. Same shape as starship's directory and tmux's session slab.
			lualine_a = {
				-- Two components, one slab: they share section a's colour, so the
				-- boundary between them joins equal backgrounds and lualine draws
				-- nothing there. Asymmetric padding keeps them one space apart
				-- rather than two.
				{ "%{&spell ? 'SPELL' : ''}", separator = { left = g.cap_l }, padding = { left = 1, right = 0 } },
				{ "mode", separator = { right = g.arrow } },
				ramp(p.accentDim, { right = g.arrow }),
				ramp(p.ash, { right = g.arrow }),
			},
			lualine_b = {
				spacer(),
				-- Recording sits first, closest to the mode slab, because it reads
				-- as an extension of the mode: both answer "what will my next
				-- keystroke do?".
				{
					function()
						return g.recording .. " " .. recording_register()
					end,
					cond = is_recording,
					color = slab(p.accentBright),
					separator = caps,
				},
				spacer(is_recording),
				-- Zoomed is gold, because that is what tmux paints a zoomed window.
				{
					function()
						return g.maximized
					end,
					cond = is_maximized,
					color = { fg = p.bg, bg = p.gold, gui = "bold" },
					separator = caps,
				},
				spacer(is_maximized),
				-- Git is one pill split across two components, like starship's:
				-- both carry a full set of caps, and the two facing each other in
				-- the middle cancel out because they'd join equal backgrounds. So
				-- the pill closes correctly whether or not the diff half is there.
				{
					"branch",
					icon = { g.git, color = { fg = p.accentDim } },
					color = pill,
					separator = caps,
				},
				{
					"diff",
					symbols = { added = g.added .. " ", modified = g.modified .. " ", removed = g.removed .. " " },
					diff_color = {
						added = { fg = p.olive, bg = p.surface },
						modified = { fg = p.gold, bg = p.surface },
						removed = { fg = p.error, bg = p.surface },
					},
					color = pill,
					separator = caps,
				},
				spacer(),
				{
					"diagnostics",
					symbols = {
						error = g.diag_error .. " ",
						warn = g.diag_warn .. " ",
						info = g.diag_info .. " ",
						hint = g.diag_hint .. " ",
					},
					-- Straight off palette.nix's semantics: error = failure, gold =
					-- needs-attention-not-broken, steel = neutral metadata, sage =
					-- suggestion.
					diagnostics_color = {
						error = { fg = p.error, bg = p.surface },
						warn = { fg = p.gold, bg = p.surface },
						info = { fg = p.steel, bg = p.surface },
						hint = { fg = p.sage, bg = p.surface },
					},
					color = pill,
					separator = caps,
				},
			},
			-- The filename is content, not chrome: it rides bare on the canvas so
			-- the bar isn't wall-to-wall pills, and so the one variable-width
			-- element in it isn't fighting a fixed shape.
			lualine_c = {
				{ "filename", color = { fg = p.fgSoft, bg = p.bg } },
			},
			lualine_x = {
				{ "filetype", color = pill, separator = caps },
				-- Opens the ramp. See the note on ramp() for why this side chains
				-- with `right` separators rather than `left` ones.
				spacer(nil, { right = g.arrow }),
			},
			-- Right bookend: the ramp heating back up into the position slab.
			-- Identical to starship's clock and tmux's clock.
			lualine_y = {
				ramp(p.ash, { right = g.arrow }),
				ramp(p.accentDim, { right = g.arrow }),
			},
			-- Explicitly coral rather than the theme's per-mode colour: lualine
			-- mirrors section z onto section a, and this bookend should stay put
			-- while the mode slab changes, exactly like the clock at the other end
			-- of the tmux bar.
			lualine_z = {
				-- No leading separator here: the last ramp step already draws the
				-- arrow that hands off into this slab.
				{
					"progress",
					color = slab(p.accent),
					cond = function()
						return vim.api.nvim_win_get_width(0) >= 60
					end,
				},
				{ "location", color = slab(p.accent), separator = { right = g.cap_r } },
			},
		},
		-- Inactive splits recede into graphite, like an inactive tmux window.
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {
				{ "filename", color = { fg = p.fgDim, bg = p.surface }, separator = caps },
			},
			lualine_x = {
				{ "location", color = { fg = p.fgDim, bg = p.surface }, separator = caps },
			},
			lualine_y = {},
			lualine_z = {},
		},
		tabline = {},
		extensions = {},
	},
	config = function(_, opts)
		require("lualine").setup(opts)

		-- lualine's refresh events don't cover the recording register, so the
		-- pill would otherwise only appear on the next unrelated redraw. Scheduled
		-- because RecordingLeave fires *before* reg_recording() clears — refreshing
		-- inline would repaint the pill one last time and leave it up until
		-- something else moved.
		vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
			group = vim.api.nvim_create_augroup("danvim_lualine_recording", { clear = true }),
			callback = function()
				vim.schedule(function()
					require("lualine").refresh()
				end)
			end,
		})
	end,
}

local deviconsAutoColors = {
	"rachartier/tiny-devicons-auto-colors.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	event = "VeryLazy",
	config = function()
		-- Snap every file-type icon to the nearest Ember hue. Without this the
		-- icons are the loudest palette violation in the editor: they ship with
		-- vendor brand colours that belong to no theme at all.
		-- `ash` is deliberately absent: palette.nix marks it decorative-only at
		-- 3:1 against the background, which is fine for a flame trail and not
		-- fine for a glyph you are meant to identify at a glance.
		require("tiny-devicons-auto-colors").setup({
			colors = {
				p.fg,
				p.fgSoft,
				p.fgDim,
				p.accent,
				p.accentBright,
				p.accentDim,
				p.olive,
				p.gold,
				p.steel,
				p.mauve,
				p.sage,
				p.error,
			},
		})
	end,
}

-- Replaced markview.nvim 2026-08-19 after profiling. markview cost 9.4ms of every
-- BufEnter into a markdown buffer (0.003ms on every other buffer, and nothing on
-- CursorMoved/TextChanged) -- measured at 5.8ms even in a bare harness, 10-13ms
-- inside this config. render-markdown does the same job at 0.008-0.024ms, i.e.
-- indistinguishable from having no plugin attached at all.
--
-- The thing that made the swap safe: markview was NOT what rendered our LaTeX.
-- snacks.image already renders equations as real typeset images (tectonic -> magick,
-- see snacks.lua `convert.magick.math`), and markview was laying 191 unicode-conceal
-- extmarks over the same 23 equations in academical_reviews/artint_2024/review.md.
-- Dropping markview removes that duplication rather than losing a feature -- hence
-- `latex.enabled = false` below, so render-markdown does not re-create it.
local RenderMarkdown = {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"echasnovski/mini.icons", -- auto-detected first, then nvim-web-devicons
	},
	opts = {
		file_types = { "markdown" },
		-- snacks.image owns equations. Leaving this on would render them twice:
		-- once as latex2text unicode here, once as an image there.
		latex = { enabled = false },
	},
}

local ColorRefs = {
	"dhernandez/color-refs.nvim",
	event = { "BufReadPost", "BufNewFile" },
	opts = {},
}

return {
	ColorSchemes,
	LuaLine,
	BufferLine,
	deviconsAutoColors,
	RenderMarkdown,
	ColorRefs,
}
