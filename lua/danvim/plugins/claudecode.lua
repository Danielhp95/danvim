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
	keys = {
		{ "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", desc = "[f]ocus Claude" },
		{ "<leader>cr", "<cmd>ClaudeCode --resume<cr>", desc = "[r]esume session" },
		{ "<leader>cC", "<cmd>ClaudeCode --continue<cr>", desc = "[C]ontinue last session" },
		{ "<leader>cm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select [m]odel" },
		{ "<leader>cx", "<cmd>ClaudeCodeStop<cr>", desc = "Stop / e[x]it server" },
		-- Add files to context
		{ "<leader>cA", "<cmd>ClaudeCodeAdd %<cr>", desc = "[A]dd current file to context" },
		{
			"<leader>ca",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "[a]dd file from explorer to context",
			ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "fyler" },
		},
		-- Send visually selected code to the chat window (and let Claude edit it)
		{ "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "[s]end selection to Claude" },
		-- Accept / reject Claude's proposed diffs
		{ "<leader>cy", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "[y]es, accept diff" },
		{ "<leader>cn", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "[n]o, deny diff" },
	},
}
