return {
	{
		"sassanh/terminals.nvim",
		-- load eagerly: setup() is what creates the global maps (<M-0>…<M-9>
		-- slot jumps, <M-m> layout cycle), so they must exist before any
		-- lazy-load trigger fires
		lazy = false,
		config = function()
			local terminals = require("terminals")

			-- terminals.nvim floats use relative="editor", where row 0 is the
			-- top of the *screen grid* — that includes the tabline, not just
			-- the window area below it. Layouts anchored at row = 0 sit on
			-- top of bufferline. Shrinking their height doesn't help since
			-- the anchor stays NW: the window shrinks from the bottom while
			-- the top edge stays glued over the tabline. Starting these one
			-- row down (and trimming height to match) clears the tabline
			-- instead.
			local function height_below_tabline()
				return vim.o.lines - 2
			end

			terminals.setup({
				keys = {
					-- defaults use macOS <D-…> (Cmd); remap to match the old
					-- floaterm setup on Linux
					toggle = "<leader><leader>f",
					cycle_layout = "<M-m>",
					-- cycle terminals, same as the old floaterm buffer maps
					go_right = "<C-S-j>",
					go_left = "<C-S-k>",
					move_right = "<M-S-j>",
					move_left = "<M-S-k>",
					focus = "<M-i>",
					unfocus = "<M-S-i>",
					leave = "<M-[>",
					toggle_reverse_search = "<M-/>",
					paste = "<C-S-v>",
					paste_in_place = "<C-S-p>",
					-- <M-0>…<M-9> jump to terminal slots (Alt instead of Cmd)
					modifier = "M",
				},
				layouts = {
					-- near-fullscreen
					{ width = "95%", height = "99%", row = 1 },
					-- left half
					{ width = "50%", height = height_below_tabline, row = 1, col = 0 },
					-- right half
					{ width = "50%", height = height_below_tabline, row = 1, col = "right" },
					-- bottom half (already clear of the tabline, anchored to the
					-- bottom edge instead)
					{ width = "100%", height = "50%", row = "bottom", col = 0 },
				},
				preserved_keys = {},
			})

			-- Coral border. terminals.nvim sets `winhighlight=Normal:WindowBorder`
			-- on *both* the border window and the terminal window, so defining
			-- WindowBorder would tint uncoloured shell output along with it.
			-- Repoint the border window alone at TerminalsBorder (colorschemes.lua).
			--
			-- Wrapping activate_terminal rather than setting it once: the border
			-- window is destroyed by close_terminal and rebuilt here, and every
			-- caller (toggle, slot jump, navigate, move) goes through the module
			-- table, so the wrapper catches each rebuild.
			local logic = require("terminals.logic")
			local activate_terminal = logic.activate_terminal
			logic.activate_terminal = function(...)
				local result = activate_terminal(...)
				if logic.border_window and vim.api.nvim_win_is_valid(logic.border_window) then
					vim.api.nvim_set_option_value(
						"winhighlight",
						"Normal:TerminalsBorder",
						{ win = logic.border_window }
					)
				end
				return result
			end
		end,
	},
}
