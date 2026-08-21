-- Replaces marco-souza/present.nvim (2 stars, last commit 2025-12-06). Same
-- job, but maintained and it reads adoc/org as well as markdown. The command
-- is :Presenting rather than :Present.

-- Slide geometry. Upstream hardcodes a 60-column slide window that is
-- `lines - 5` tall, i.e. a tall narrow strip: phone-shaped, not screen-shaped.
-- Everything below replaces that with a frame whose aspect ratio matches the
-- monitor being presented on.
local geometry = {
	-- Fraction of the screen the slide frame takes up. The leftover margin is
	-- what makes it read as a slide sitting on a backdrop rather than as the
	-- whole terminal.
	scale = 0.94,
	-- Slide aspect ratio as width/height *in pixels*, e.g. 16 / 9.
	--
	-- nil means "derive it from the terminal", which is the useful default: a
	-- fullscreen terminal already has the aspect ratio of the monitor it is on,
	-- so a box scaled down from the grid inherits it -- 16:9 on the desktop
	-- monitors, 16:10 on the laptop panel, without knowing which is which. Set
	-- this explicitly only when presenting from a terminal that is *not*
	-- fullscreen, since then the grid no longer stands in for the screen.
	aspect = nil,
	-- Pixel height / pixel width of one terminal cell. Only consulted when
	-- `aspect` is set, to convert a pixel ratio into a cell ratio.
	cell_aspect = 2.1,
	-- Left gutter between the frame border and the text, in columns (0-9; it is
	-- implemented with 'foldcolumn', which is what caps it at 9).
	pad_x = 3,
	border = "rounded",
}

---Size and position of the slide frame, in cells, including its border.
local function frame()
	local cols = vim.o.columns
	local rows = math.max(vim.o.lines - vim.o.cmdheight, 1)

	-- Columns per row needed to hit the target aspect ratio.
	local ratio = geometry.aspect and (geometry.aspect * geometry.cell_aspect) or (cols / rows)

	local width = math.floor(cols * geometry.scale)
	local height = math.floor(width / ratio)
	local max_height = math.floor(rows * geometry.scale)
	if height > max_height then
		height = max_height
		width = math.floor(height * ratio)
	end

	-- Below this there is no room for a border plus a line of text.
	width = math.max(math.min(width, cols), 3)
	height = math.max(math.min(height, rows), 3)

	return {
		width = width,
		height = height,
		col = math.floor((cols - width) / 2),
		row = math.floor((rows - height) / 2),
		cols = cols,
		rows = rows,
	}
end

local function win_configs()
	local f = frame()
	-- With a border, row/col/width/height describe the *content* area and the
	-- border is drawn just outside it, so inset by one on every side.
	local edge = (geometry.border and geometry.border ~= "none") and 1 or 0

	return {
		-- Full-screen backdrop, purely to hide the buffer being presented.
		background = {
			style = "minimal",
			relative = "editor",
			focusable = false,
			width = f.cols,
			height = f.rows,
			row = 0,
			col = 0,
			zindex = 1,
		},
		slide = {
			style = "minimal",
			relative = "editor",
			border = geometry.border,
			width = f.width - 2 * edge,
			height = f.height - 2 * edge,
			row = f.row + edge,
			col = f.col + edge,
			zindex = 10,
		},
		-- Slide counter, on the first row below the frame (clamped onto the last
		-- screen row if the frame reaches the bottom).
		footer = {
			style = "minimal",
			relative = "editor",
			width = f.width,
			height = 1,
			row = math.min(f.row + f.height, f.rows - 1),
			col = f.col,
			focusable = false,
			zindex = 2,
		},
	}
end

local function apply_geometry()
	local state = _G.Presenting and _G.Presenting._state
	if not state then
		return
	end
	local wins = { state.background_win, state.slide_win, state.footer_win }
	for _, win in ipairs(wins) do
		if not (win and vim.api.nvim_win_is_valid(win)) then
			return
		end
	end

	local configs = win_configs()
	vim.api.nvim_win_set_config(state.background_win, configs.background)
	vim.api.nvim_win_set_config(state.footer_win, configs.footer)
	vim.api.nvim_win_set_config(state.slide_win, configs.slide)

	-- After set_config, not before: `style = "minimal"` resets these every time.
	-- The backdrop borrows Normal so it disappears into the colourscheme, while
	-- the slide keeps NormalFloat and reads as a surface lifted off it.
	vim.wo[state.background_win].winhighlight = "NormalFloat:Normal"
	vim.wo[state.slide_win].foldcolumn = tostring(math.min(math.max(geometry.pad_x, 0), 9))
	vim.wo[state.slide_win].wrap = true
	vim.wo[state.slide_win].linebreak = true
end

return {
	"sotte/presenting.nvim",
	cmd = "Presenting",
	config = function()
		local presenting = require("presenting")
		presenting.setup {}

		-- The geometry lives in a local `H` table upstream, so it cannot be
		-- configured or overridden -- but every caller reaches these two through
		-- the module table (`toggle` dispatches to `start`, the WinResized
		-- autocmd calls `resize`), so replacing them here is enough.
		local start = presenting.start
		presenting.start = function(...)
			start(...)
			apply_geometry()
		end
		presenting.resize = apply_geometry
	end,
}
