-- Chrome that holds under every base colourscheme.
--
-- Written against the palette only: nothing here reads a field of ember's
-- `theme` or tokyonight's `colors`, so the same function is handed to either
-- theme's on_highlights hook. Syntax tuning that only makes sense for one
-- theme lives next to that theme (theme/ember.lua, theme/tokyonight.lua).

local M = {}

---@param hl table<string, table|string> the theme's highlight table, edited in place
---@param p danvim.Palette
function M.highlights(hl, p)
	-- Bold visual selection, on whatever background the theme gave it. (The
	-- ColorScheme autocmd in aucmds.lua can fire too late at startup.)
	if type(hl.Visual) == "table" then
		hl.Visual = vim.tbl_extend("force", hl.Visual, { bold = true })
	end

	-- self/cls/this: the banked accent, italic. In the accent family because
	-- self is keyword-adjacent, and deliberately not the theme's red: the
	-- palette's one red is `error`, which means failure and nothing else.
	local self_like = { fg = p.accentDim, italic = true }
	hl["@variable.builtin"] = self_like
	hl["@variable.parameter.builtin"] = self_like
	hl["@module.builtin"] = self_like
	hl["@lsp.typemod.variable.defaultLibrary"] = self_like
	hl["@lsp.type.selfParameter"] = { link = "@variable.builtin" }
	hl["@lsp.type.clsParameter"] = { link = "@variable.builtin" }
	hl["@lsp.type.selfKeyword"] = { link = "@variable.builtin" }

	-- Scroll thumbs in the accent. `bg`, not `fg`: both are drawn as empty
	-- cells. BlinkCmpScrollBarThumb stays explicit so the menu does not depend
	-- on blink's default link to PmenuThumb.
	local thumb = { bg = p.accent }
	hl.PmenuThumb = thumb
	hl.BlinkCmpScrollBarThumb = thumb

	-- terminals.nvim draws its border as text in a window of its own
	-- (terminal.lua points that window's Normal at this group).
	hl.TerminalsBorder = { fg = p.accent }

	-- Float borders ('winborder' = "rounded"): the banked accent. The floor is
	-- contrast: kitty rasterises the arcs itself, and a border within a few
	-- percent of the buffer's lightness loses its corners. `bg` is the
	-- *buffer* background, so the cell area outside the arc matches what is
	-- around it; this is why p.bg must be the theme's Normal bg.
	local float_border = { fg = p.accentDim, bg = p.bg }
	hl.FloatBorder = float_border
	-- blink remaps FloatBorder to these in each of its windows.
	hl.BlinkCmpMenuBorder = float_border
	hl.BlinkCmpDocBorder = float_border
	hl.BlinkCmpSignatureHelpBorder = float_border

	-- nvim-dap signs. A breakpoint is the conventional red dot, so it takes
	-- the palette's terminal red (ansi 1): the accent in Ember, a real red in
	-- a palette whose accent is not red. "Stopped here" is an accent role.
	hl.DapBreakpoint = { fg = p.ansi[2] }
	hl.DapBreakpointCondition = { fg = p.gold }
	hl.DapLogPoint = { fg = p.sage }
	hl.DapBreakpointRejected = { fg = p.muted }
	hl.DapStopped = { fg = p.accentBright }
	hl.DapStoppedLine = { bg = p.surface }

	-- Only drawn with 'winborder' = "shadow".
	hl.FloatShadow = { bg = p.accentDim, blend = 80 }
	hl.FloatShadowThrough = { bg = p.accentDim, blend = 85 }

	-- Search: keep each match's own foreground, bold it, lift the background.
	local search = { fg = "NONE", bg = p.divider, bold = true }
	hl.Search = search
	hl.IncSearch = search
	hl.CurSearch = search
end

--- :terminal renders through these, not through syntax colours. Straight from
--- the palette's ansi list, so a shell inside nvim matches the same shell in
--- kitty/ghostty slot for slot.
---@param p danvim.Palette
function M.terminal(p)
	for i, color in ipairs(p.ansi) do
		vim.g["terminal_color_" .. (i - 1)] = color
	end
end

--- Re-assert the terminal colours after any later :colorscheme, since both
--- themes write their own 16 on load.
---@param p danvim.Palette
function M.keep_terminal(p)
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("danvim_palette_terminal", { clear = true }),
		callback = function()
			M.terminal(p)
		end,
	})
end

return M
