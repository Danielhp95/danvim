-- Base colourscheme for the "tokyonight" family: folke/tokyonight.nvim, with
-- its whole palette replaced by ours.
--
-- tokyonight computes its derived colours (diff.*, bg_visual, bg_search,
-- border_highlight, the float/popup/sidebar backgrounds, error/warning/info/
-- hint, black) and sets the blend base (Util.bg) BEFORE it calls on_colors.
-- So the palette goes in as a *style*: colors/init.lua resolves a style
-- through Util.mod, which returns package.loaded["tokyonight.colors.<style>"]
-- when it is set. Seeding that module makes every derived colour and every
-- blend come out of the plugin's own formulas, applied to our slots.
-- on_colors is left with the three derived keys we want to differ.

local chrome = require("danvim.theme.chrome")

local M = {}

-- The style name our palette is registered under. vim.g.colors_name becomes
-- "tokyonight-danvim"; the stock styles stay untouched.
M.style = "danvim"

-- tokyonight's Util.blend, so `blue7` can be derived before the plugin loads.
local function blend(fg, alpha, bg)
	local function channel(i)
		local f = tonumber(fg:sub(2 * i, 2 * i + 1), 16)
		local b = tonumber(bg:sub(2 * i, 2 * i + 1), 16)
		return math.floor(math.min(math.max(0, alpha * f + (1 - alpha) * b), 255) + 0.5)
	end
	return string.format("#%02x%02x%02x", channel(1), channel(2), channel(3))
end

--- Our slots as a tokyonight base Palette (the shape of colors/storm.lua).
---@param p danvim.Palette
function M.base(p)
	return {
		-- surfaces
		bg = p.bg, -- Normal; must be p.bg (statusline caps, float corners)
		bg_dark = p.bgDeep, -- floats, popups, sidebars, statusline
		bg_dark1 = p.bgDeep,
		bg_highlight = p.surface, -- CursorLine
		fg_gutter = p.border, -- line numbers, indent guides, LSP reference bg
		terminal_black = p.divider, -- ghost text, unused code, inline-code bg
		-- text
		fg = p.fg,
		fg_dark = p.fgSoft, -- messages, brackets, sidebar text
		dark5 = p.fgDim,
		dark3 = p.muted, -- NonText, ignored files
		comment = p.muted,
		-- accent family
		magenta = p.accent, -- statements, conditionals, `function`
		-- @keyword. The accent too, not mauve: the rose is brighter than the
		-- accent, and keywords would be the loudest thing in a buffer.
		purple = p.accent,
		magenta2 = p.mauveBright, -- jump labels, picker selection mark
		blue0 = p.ash, -- feeds bg_visual (40% on bg) and bg_search
		-- blue
		blue = p.steel, -- functions, titles, directories
		blue2 = p.steel, -- feeds `info`
		blue5 = p.steelBright, -- operators, delimiters
		blue7 = blend(p.steel, 0.35, p.bg), -- feeds diff.text / diff.change
		-- cyan / teal
		-- p.cyan and p.orange: two hues Tokyo Night's syntax needs that the 25
		-- slots do not name (palette.lua requires them for this family).
		blue1 = p.cyan, -- types, specials, builtin functions
		blue6 = p.sageBright, -- regexps
		cyan = p.sage, -- preprocessor, attributes
		teal = p.sage, -- feeds `hint`; links
		green1 = p.sage, -- properties, fields
		-- the rest, hue for hue
		green = p.olive, -- strings
		green2 = p.olive, -- feeds diff.add
		yellow = p.gold, -- parameters; feeds `warning`
		orange = p.orange, -- constants, numbers
		red = p.error,
		red1 = p.error, -- feeds `error` and diff.delete
		git = { add = p.olive, change = p.gold, delete = p.error },
	}
end

--- Derived keys whose stock formula is not what the palette means. Everything
--- else tokyonight derives (diff.*, bg_visual, bg_search, the float/popup/
--- sidebar backgrounds, error/warning/info/hint/todo, rainbow) already came
--- out of our slots, because the base palette is ours.
---@param c table tokyonight's ColorScheme
---@param p danvim.Palette
function M.on_colors(c, p)
	c.black = p.bgDeep -- stock: bg at 80% over black
	c.border = p.bgDeep -- window separators
	c.border_highlight = p.accentDim -- every plugin's float border, as FloatBorder
end

--- Tuning that only applies on top of tokyonight, then the shared chrome.
---@param hl table
---@param p danvim.Palette
function M.on_highlights(hl, p)
	-- Inlay hints keep tokyonight's tinted background but not its 2.6:1 text.
	-- Not `steel` as under ember: functions are steel here. Italic, because
	-- fgDim is itself close to steel.
	if type(hl.LspInlayHint) == "table" then
		hl.LspInlayHint = vim.tbl_extend("force", hl.LspInlayHint, { fg = p.fgDim, italic = true })
	end

	-- Line numbers: tokyonight uses fg_gutter, which here is `border` and
	-- nearly invisible as text. fg_gutter itself stays dim for indent guides.
	local line_nr = { fg = blend(p.muted, 0.4, p.divider) }
	hl.LineNr = line_nr
	hl.LineNrAbove = line_nr
	hl.LineNrBelow = line_nr

	-- Builtin types are a blend of cyan toward bg upstream, which lands on
	-- steel: `int` would look like a function call.
	local builtin_type = { fg = p.cyan, italic = true }
	hl["@type.builtin"] = builtin_type
	hl["@lsp.typemod.type.defaultLibrary"] = builtin_type
	hl["@lsp.typemod.typeAlias.defaultLibrary"] = builtin_type

	-- Groups Neovim defines that tokyonight does not: left alone they keep the
	-- builtin colourscheme's pastel green / cyan / red.
	hl.Added = { fg = p.olive }
	hl.Changed = { fg = p.gold }
	hl.Removed = { fg = p.error }
	hl.DiagnosticOk = { fg = p.olive }
	hl.OkMsg = { fg = p.olive }

	-- Whatever tokyonight draws in a float's border row (borders, titles,
	-- footers) it paints on the float background. chrome.highlights puts
	-- FloatBorder on the buffer background so rounded corners have no dark
	-- square behind them; the rest of the row has to agree.
	for name, spec in pairs(hl) do
		if type(spec) == "table" then
			if spec.bg == p.bgDeep and (name:find("Border") or name:find("Title$") or name:find("Footer$")) then
				spec.bg = p.bg
			end
			-- Jump and pick labels (flash, leap, the snacks window picker) sit
			-- on magenta2, a neon pink upstream and a pale rose here: light
			-- text on it is unreadable.
			if spec.bg == p.mauveBright then
				spec.fg = p.bg
			end
		end
	end

	chrome.highlights(hl, p)
end

---@param p danvim.Palette
function M.load(p)
	package.loaded["tokyonight.colors." .. M.style] = M.base(p)

	require("tokyonight").setup({
		style = M.style,
		-- chrome.terminal assigns the palette's own 16 instead.
		terminal_colors = false,
		on_colors = function(c)
			M.on_colors(c, p)
		end,
		on_highlights = function(hl)
			M.on_highlights(hl, p)
		end,
	})
	chrome.keep_terminal(p)
	-- colors/tokyonight.lua loads the style given to setup().
	vim.cmd.colorscheme("tokyonight")
end

return M
