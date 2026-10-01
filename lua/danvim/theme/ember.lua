-- Base colourscheme for the "ember" family: ember-theme/nvim, plus the syntax
-- tuning that only makes sense on top of it.

local chrome = require("danvim.theme.chrome")

local M = {}

-- Feed ember's own 21-key palette from ours, so the buffer follows palette.nix
-- by construction instead of by coincidence. Off: upstream's values, which
-- differ from palette.nix in a few places (a steel blue, an orange, the grey
-- ramp), so turning it on is a visible change.
M.drive_from_palette = false

--- ember's flat palette (bg, bg_alt, base0-8, fg, fg_alt + 8 accents).
---@param p danvim.Palette
function M.colors(p)
	return {
		bg = p.bg,
		bg_alt = p.bgAlt,
		base0 = p.bgDeep, -- float background
		base1 = p.bg,
		base2 = p.bgAlt, -- popup menu
		base3 = p.surface,
		base4 = p.border, -- selection, pmenu selection, borders
		base5 = p.divider,
		base6 = p.muted, -- comments
		base7 = p.fgDim, -- operators, doc comments
		base8 = p.fgSoft,
		fg = p.fg,
		fg_alt = p.fgSoft,
		coral = p.accent,
		orange = p.orange or p.steel, -- constants, numbers
		gold = p.gold,
		olive = p.olive,
		sage = p.sage,
		steel = p.steel, -- info, attributes, links
		rose = p.accentDim, -- diagnostics errors, terminal red
		mauve = p.mauve,
	}
end

---@param hl table
---@param p danvim.Palette
local function syntax(hl, p)
	if not M.drive_from_palette then
		-- Upstream's palette has drifted from palette.nix in two hues; rewrite
		-- them wherever they occur. (Dead once drive_from_palette is on.)
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
	end

	-- Parameters get mauve, which ember's syntax otherwise leaves unused.
	hl["@variable.parameter"] = { fg = p.mauve, italic = true }

	-- Inlay hints in the metadata slot: ember's default is 1.5:1 on the
	-- buffer, and nothing else in an ember buffer is steel.
	hl["LspInlayHint"] = { fg = p.steel }
end

---@param p danvim.Palette
function M.load(p)
	require("ember").setup({
		on_colors = M.drive_from_palette and function(colors)
			for key, value in pairs(M.colors(p)) do
				colors[key] = value
			end
		end or nil,
		on_highlights = function(hl)
			syntax(hl, p)
			chrome.highlights(hl, p)
		end,
	})
	chrome.keep_terminal(p)
	vim.cmd.colorscheme("ember")
end

return M
