-- coder/claudecode.nvim — drives the real `claude` CLI in an embedded terminal
-- over the same WebSocket protocol the official IDE extensions use.
--
-- Why this *and* avante.nvim:
--   avante talks to Claude via ACP (claude-agent-acp). That reuses your Max-sub
--   login, but the ACP bridge can't forward interactive commands to the
--   underlying CLI — you can't switch models or invoke skills mid-session.
--   claudecode.nvim instead runs the genuine `claude` binary in a terminal, so
--   you get the full interactive experience (/model, /skills, slash commands,
--   etc.) while Neovim feeds it selections, files, and diffs.
--
-- Auth: `claude` (the claude-code package) is on PATH via nix. Running it in a
-- terminal uses your normal `claude /login` Max-sub credentials — keep
-- ANTHROPIC_API_KEY UNSET so it doesn't fall back to API billing.
--
-- Keymaps live under <leader>c ([c]laude) so they sit alongside avante's
-- <leader>a group instead of clobbering it.
return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeSelectModel",
		"ClaudeCodeAdd",
		"ClaudeCodeSend",
		"ClaudeCodeTreeAdd",
		"ClaudeCodeStatus",
		"ClaudeCodeStart",
		"ClaudeCodeStop",
		"ClaudeCodeOpen",
		"ClaudeCodeClose",
		"ClaudeCodeDiffAccept",
		"ClaudeCodeDiffDeny",
		"ClaudeCodeCloseAllDiffs",
	},
	opts = {
		-- `claude` resolved from PATH (provided by the claude-code nix package).
		terminal_cmd = nil,
		auto_start = true,
		terminal = {
			provider = "snacks", -- snacks.nvim is a startup plugin in this config
			split_side = "right",
			split_width_percentage = 0.35,
			auto_close = true,
		},
		diff_opts = {
			layout = "vertical",
			auto_resize_terminal = true,
		},
	},
}
