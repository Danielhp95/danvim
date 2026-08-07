-- Top-centred floating cmdline. Replaces noice.nvim, which was kept for this
-- one feature until it became untenable: noice drives the cmdline through
-- `ext_cmdline`/`vim.ui_attach`, and so does `vim._core.ui2` (options.lua), so
-- both owned the cmdline at once. Upstream calls that combination unsupported
-- (neovim#38916); noice#1201 is the same bug, open and unanswered.
--
-- tiny-cmdline takes the opposite approach: it repositions ui2's *own* cmd
-- window via nvim_win_set_config on the FileType hook ui2 documents for that
-- purpose -- the same trick options.lua already uses on ui2's msg window. So
-- this is still the real cmdline: live incsearch, inccommand, wildmenu,
-- history and q: all keep working, and there is only ever one cmdline.
return {
	"rachartier/tiny-cmdline.nvim",
	event = "VeryLazy",
	opts = {
		-- Matches noice's `command_palette` preset geometry (row 3, centred,
		-- min_width 60) so the prompt lands where it always has.
		position = { x = "50%", y = 3 },
		width = { value = 60, min = 60, max = 80 },

		-- noice had `bottom_search = false`, i.e. `/` and `?` were centred with
		-- everything else. Empty list keeps that. Trade-off: the plugin bumps
		-- cmdheight to 1 during a search for stable IncSearch rendering, so the
		-- layout shifts by a row. Set back to { "/", "?" } to pin search to the
		-- bottom and avoid the shift.
		native_types = {},

		-- Border titles, carrying over the icon vocabulary from noice's
		-- `cmdline.format`. Patterns are matched against getcmdline(), which
		-- excludes the leading ':' -- so these are unanchored, unlike noice's.
		-- First match wins; the last entry is the fallback.
		title = {
			enabled = true,
			pos = "center",
			formats = {
				{ type = ":", pattern = { "^%s*lua%s+", "^%s*lua%s*=", "^%s*=" }, title = " 🌙 Lua " },
				{ type = ":", pattern = "^%s*!", title = " 💲 Shell " },
				{ type = ":", pattern = "^%s*he?l?p?%s+", title = " ❓ Help " },
				{ type = "/", title = " 🔍 Search " },
				{ type = "?", title = " 🔎 Search " },
				{ type = "=", title = " Expression " },
				{ title = " CmdLine " },
			},
		},

		-- Keeps blink.cmp's cmdline completion menu glued to the window after
		-- it moves; without this the menu renders at the old position.
		on_reposition = function()
			require("tiny-cmdline").adapters.blink()
		end,
	},
}
