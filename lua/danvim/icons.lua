-- Nerd Font glyphs used by more than one place in danvim: the statusline
-- (plugins/style.lua), the diagnostic gutter and inline text (options.lua) and
-- the debugger signs (plugins/dap.lua). Each icon is defined once here so the
-- gutter, the inline diagnostics and the statusline always agree.
--
-- Written as \u{} escapes, same as style.lua's glyph table: a private-use glyph
-- is invisible in a diff and easily mangled in transit, a codepoint is not.
-- Colour does not live here. The glyphs are single-colour, and each one takes
-- its colour from a highlight group (Diagnostic*, Dap* in plugins/colorschemes.lua).

local S = vim.diagnostic.severity

local M = {}

-- md-close_circle, md-alert, md-information, md-lightbulb_outline
M.diagnostic = {
	error = "\u{F015A}",
	warn = "\u{F002A}",
	info = "\u{F02FD}",
	hint = "\u{F0336}",
}

-- The same four, keyed the way vim.diagnostic.config() wants them.
M.diagnostic_by_severity = {
	[S.ERROR] = M.diagnostic.error,
	[S.WARN] = M.diagnostic.warn,
	[S.INFO] = M.diagnostic.info,
	[S.HINT] = M.diagnostic.hint,
}

-- codicons, so the five nvim-dap signs read as one family
M.dap = {
	breakpoint = "\u{EA71}", -- cod-circle_filled
	condition = "\u{EAA7}", -- cod-debug_breakpoint_conditional
	log_point = "\u{EAAB}", -- cod-debug_breakpoint_log
	stopped = "\u{EB8B}", -- cod-debug_stackframe_active
	rejected = "\u{EB8C}", -- cod-debug_breakpoint_unsupported
}

M.fold = {
	open = "\u{EAB4}", -- cod-chevron_down
	close = "\u{EAB6}", -- cod-chevron_right
}

return M
