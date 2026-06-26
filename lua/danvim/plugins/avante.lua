return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	opts = {
		behaviour = { -- See if we want this!
			enable_cursor_planning_mode = true,
		},
		completion = { -- We are using blink
			enable = false,
		},
		provider = "claude-code",
		selector = {
			provider = "telescope",
		},
		providers = {
			copilot = {
				-- model = "claude-opus-4.6", -- Available: gpt-4o, claude-sonnet-4, etc.
				model = "gpt-4.1", -- Available: gpt-4o, claude-sonnet-4, etc.
			},
			ollama = {
				model = "qwen3-coder:30b",
				is_env_set = require("avante.providers.ollama").check_endpoint_alive,
			},
		},
		-- ACP agents run an external CLI as a subprocess. claude-code here drives
		-- the real Claude Code binary, so it reuses your `claude /login` Max-sub
		-- credentials. No API key needed (and you want ANTHROPIC_API_KEY UNSET in
		-- your shell, otherwise Claude Code bills the API instead of the sub).
		acp_providers = {
			["claude-code"] = {
				-- Must be on PATH. See notes for installing it declaratively on Nix.
				-- Quick/dirty alternative: command = "npx", args = { "@zed-industries/claude-code-acp" }
				command = "claude-agent-acp",
				args = {},
				env = {
					NODE_NO_WARNINGS = "1",
					-- Tells claude-agent-acp where the `claude` binary is. Without this
					-- the wrapper can't reach the Max-sub login from `claude /login` and
					-- falls back to expecting ANTHROPIC_API_KEY → "configuration error".
					ACP_PATH_TO_CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude"),
					ACP_PERMISSION_MODE = "bypassPermissions",
					ANTHROPIC_MODEL = "claude-sonnet-4-6",
				},
			},
			["claude-code-opus"] = {
				command = "claude-agent-acp",
				args = {},
				env = {
					NODE_NO_WARNINGS = "1",
					ACP_PATH_TO_CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude"),
					ACP_PERMISSION_MODE = "bypassPermissions",
					ANTHROPIC_MODEL = "claude-opus-4-8",
				},
			},
		},
	},
	keys = {
		{
			-- Dart vibe
			"<leader>av",
			function()
				-- Get current buffer file path before opening avante
				local current_file = vim.fn.expand("%:p")
				-- Start a new chat session
				require("avante.api").ask()
				-- Get the sidebar and add files to context
				vim.defer_fn(function()
					local sidebar = require("avante").get()
					if sidebar then
						-- Add dart_vibe.md
						local dart_vibe_path = vim.fn.expand("~/sai/dart_vibe.md") -- NOTE: only works inside of SAI docker
						sidebar.file_selector:add_selected_file(dart_vibe_path)
						-- Add current buffer file if it exists
						if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
							sidebar.file_selector:add_selected_file(current_file)
						end
					end
				end, 100)
			end,
			desc = "Avante: dart vibe session",
		},
		{
			-- Add current file to sidebar
			"<leader>aA",
			function()
				local current_file = vim.fn.expand("%:p")
				-- Get the sidebar and add files to context
				vim.defer_fn(function()
					local sidebar = require("avante").get()
					if sidebar then
						if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
							sidebar.file_selector:add_selected_file(current_file)
						end
					end
				end, 100)
			end,
			desc = "Avante: add current file",
		},
		{
			-- Switch to the Claude Code ACP provider (Max subscription)
			"<leader>ap",
			function()
				require("avante.api").switch_provider("claude-code")
			end,
			desc = "Avante: switch to claude-code (Sonnet 4.6)",
		},
		{
			"<leader>aP",
			function()
				require("avante.api").switch_provider("claude-code-opus")
			end,
			desc = "Avante: switch to claude-code (Opus 4.8)",
		},
	},
	-- Nix-cats builds the avante_lib native component via the avante-nvim
	-- package, so the upstream `make` build step is not needed here.
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"echasnovski/mini.pick", -- for file_selector provider mini.pick
		"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
		-- "ibhagwan/fzf-lua", -- for file_selector provider fzf
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		"zbirenbaum/copilot.lua", -- for providers='copilot'
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
				},
			},
		},
	},
}
