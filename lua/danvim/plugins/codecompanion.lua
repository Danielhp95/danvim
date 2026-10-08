-- olimorris/codecompanion.nvim — chat + inline editing against the local LLM.
--
-- Why this rather than reviving avante.nvim (whose spec is still commented out
-- in avante.lua): weight. Avante needs a native avante_lib build (hence the
-- `gnumake` entry in flake.nix) plus nui, dressing, img-clip, a file-selector
-- picker and copilot; it also carried an input-hint buffer leak this config had
-- to hand-patch. CodeCompanion needs plenary and treesitter, both of which are
-- already in the plugin set, and builds nothing.
--
-- The division of labour with claudecode.nvim (<leader>c) is deliberate:
--   <leader>c  Claude Code, the real CLI, for work worth spending the sub on
--   <leader>a  this, pointed at ollama on localhost, for everything else
-- Avante used to own <leader>a and no longer does, so nothing is clobbered.
--
-- API NOTE for future edits: this is written against codecompanion 19.x, which
-- renamed the top-level `strategies` key to `interactions`. `strategies` still
-- works -- config.lua shims it -- so a config written from older docs looks
-- fine while silently sitting on the deprecated path. Check `interactions` in
-- the packaged source before trusting any tutorial.
-- The model's identity (name, window, keep-alive) is written once, in
-- danvim.ollama, because the adapter schema below and the preload request that
-- loads the model must agree: a different num_ctx makes ollama restart an
-- already-loaded runner.
local ollama = require("danvim.ollama")
local profile = ollama.profile

return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	cmd = {
		"CodeCompanion",
		"CodeCompanionChat",
		"CodeCompanionActions",
		"CodeCompanionCmd",
	},
	opts = {
		adapters = {
			http = {
				-- Per-adapter overrides are keyed under `extend` and deep-merged
				-- onto the resolved adapter by adapters/shared.lua's
				-- apply_extend, so only the fields below are touched.
				extend = {
					ollama = {
						-- Qwen3-Coder writes its tool calls as XML text, and Ollama
						-- leaves some of them in the message content instead of
						-- tool_calls (ollama#18530). These two handlers recover them
						-- while the response streams, before the chat decides the
						-- turn is over; see danvim.qwen_xml / codecompanion_qwen_adapter.
						-- Closures, because lazy evaluates `opts` before the plugin is on
						-- the runtimepath. Keep the handler names FLAT (form_tools,
						-- chat_output): adding handlers.response/.request/.lifecycle makes
						-- CodeCompanion ignore every other flat handler of the stock
						-- ollama adapter.
						handlers = {
							form_tools = function(...)
								return require("danvim.codecompanion_qwen_adapter").form_tools(...)
							end,
							chat_output = function(...)
								return require("danvim.codecompanion_qwen_adapter").chat_output(...)
							end,
							-- The stock ollama adapter never tells the chat which call a
							-- tool result answers, so every earlier call gets a fake
							-- "did not complete" result on each turn of the loop. `tools` is
							-- merged into the stock namespace (format_tool_calls stays) and,
							-- unlike .response/.request/.lifecycle, does not switch the
							-- adapter to the nested handler format.
							tools = {
								output_response = function(...)
									return require("danvim.codecompanion_qwen_adapter").output_response(...)
								end,
							},
						},
						schema = {
							-- Pinned rather than left to the picker, so a fresh session does not
							-- start on whatever ollama lists first.
							model = { default = profile.model },
							-- Equal to OLLAMA_CONTEXT_LENGTH in nixos/ollama.nix, because a
							-- request with a different num_ctx makes ollama restart the runner.
							num_ctx = { default = profile.num_ctx },
							-- Qwen3.8 thinks by default (and the adapter would otherwise probe
							-- the model for it). Off: see danvim.ollama for why.
							think = { default = profile.think },
							-- The non-thinking preset (the tag bakes the thinking one). The first
							-- three are in the adapter's schema already; presence_penalty is not,
							-- so it is declared here and mapped onto the request options.
							temperature = { default = profile.sampling.temperature },
							top_p = { default = profile.sampling.top_p },
							top_k = { default = profile.sampling.top_k },
							presence_penalty = {
								mapping = "parameters.options",
								type = "number",
								optional = true,
								default = profile.sampling.presence_penalty,
							},
							-- Sent on every request, which also refreshes the unload timer, so the
							-- model stays loaded while the editor is in use (and the prompt cache
							-- with it). A Go duration WITH a unit: "-1" is rejected, "-1m" is forever.
							keep_alive = { default = profile.keep_alive },
							-- A runaway generation otherwise runs until the window is full. Not in
							-- the adapter's schema, so declared here and mapped onto the options.
							num_predict = {
								mapping = "parameters.options",
								type = "number",
								optional = true,
								default = 16384,
							},
						},
					},
				},
			},
		},

		-- The adapter resolves its endpoint from $OLLAMA_HOST, falling back to
		-- http://localhost:11434. That variable is deliberately NOT set in the
		-- shell here, so the fallback applies.
		--
		-- Do not "fix" this by exporting OLLAMA_HOST to match the systemd unit:
		-- the service sets OLLAMA_HOST=0.0.0.0:11434, which is a bind address
		-- with no scheme, and the adapter interpolates it straight into a URL.
		interactions = {
			chat = {
				adapter = "ollama",

				opts = {
					-- Absolute token counts (a value of 1 or more is taken as tokens,
					-- below 1 as a fraction of the model's window). The defaults, 0.65
					-- and 0.85, are fractions of the model's TRAINED window (262144
					-- for qwen3-coder), so they fired at ~170k and ~223k tokens against
					-- our 65536 and never did: ollama silently dropped the oldest
					-- messages instead, which can be the task itself. Sized so that
					-- trigger + one 8k tool result + a 16k reply still fits:
					-- first clear old tool results, then summarise.
					context_management = {
						editing = { trigger = 28000 },
						compaction = { trigger = 40000 },
					},
				},

				-- Claude-style skills, read straight out of ~/.claude/skills and
				-- ./.claude/skills so one set of files serves both Claude Code
				-- and this. The engine is danvim.codecompanion_skills; its header
				-- explains the three disclosure levels and why a tool beats a
				-- slash command alone (skills live outside the project root, so
				-- the built-in file tools cannot reach their bundled references).
				tools = {
					-- APPROVALS. Everything below runs unattended. Two separate
					-- gates exist per tool and both have to go:
					--   require_approval_before    the "Run the X tool?" prompt
					--   require_confirmation_after the accept/reject diff shown
					--                              after a file is rewritten
					-- run_command carries a third, require_cmd_approval, which
					-- scopes an "always accept" to one exact command string
					-- rather than to the tool; with the before-gate off it only
					-- matters if that gate is ever put back.
					--
					-- delete_file is deliberately NOT listed: it keeps both of
					-- its gates, and it is absent from default_tools below too.
					["run_command"] = {
						opts = {
							require_approval_before = false,
							require_cmd_approval = false,
							-- Yolo mode (gy in the chat buffer) blanket-approves
							-- tool calls, and run_command opts out of it by
							-- default (`protect = true`). Nothing consults this
							-- while the gate above is false; it is here so gy does
							-- the obvious thing if that gate is ever restored.
							-- (`protect` replaces the deprecated
							-- `allowed_in_yolo_mode`, which is `not protect`.)
							protect = false,
						},
					},
					-- The edit tools take a table rather than a boolean here:
					-- the orchestrator sees a non-boolean and hands off to the
					-- tool's own prompt_condition, which reads these two keys to
					-- tell an open buffer from a file on disk.
					["insert_edit_into_file"] = {
						opts = {
							require_approval_before = { buffer = false, file = false },
							require_confirmation_after = false,
						},
					},
					-- The flat, one-edit-per-call wrapper around the stock edit tool
					-- (danvim.codecompanion_tools). Same approval keys as above.
					["edit_file"] = {
						callback = function()
							return require("danvim.codecompanion_tools").edit_file()
						end,
						description = "Edit a file: replace one piece of its text with another",
						opts = {
							require_approval_before = { buffer = false, file = false },
							require_confirmation_after = false,
						},
					},
					["create_file"] = {
						opts = {
							require_approval_before = false,
							require_confirmation_after = false,
						},
					},
					-- Read-only, but both prompt by default in 19.x.
					["read_file"] = { opts = { require_approval_before = false } },
					["grep_search"] = { opts = { require_approval_before = false } },

					["skill"] = {
						callback = function()
							return require("danvim.codecompanion_skills").tool()
						end,
						description = "Load a user-written skill's instructions",
					},
					opts = {
						-- The default of 30000 tokens would let one tool result take
						-- almost half of a 64k window.
						max_output_tokens = 8000,

						-- Qwen-friendly tool prompt: the stock one asks for a sentence of
						-- preamble before every call and for "valid JSON", and the preamble is
						-- what makes the model skip the `<tool_call>` token Ollama's parser
						-- keys on (ollama#18530).
						system_prompt = {
							prompt = function(args)
								return require("danvim.codecompanion_tools").system_prompt(args)
							end,
						},

						-- FIVE tools, kept as a precaution rather than a rule.
						--
						-- Ollama's parser for qwen3-coder's XML tool calls loses some of them
						-- (two separate bugs, written up in danvim.qwen_xml), and fewer tools
						-- went with fewer losses here: 7 tools dropped 6 calls in 21 requests,
						-- 5 tools dropped none in 10. That control group is small (0/10 against
						-- 6/21 is p = 0.14), and the mechanism is unexplained: the Qwen3-Coder
						-- template only knows the XML format, so there is no JSON mode that
						-- more tools switch it out of. The adapter handlers above now recover
						-- the bug that leaks calls as prose; look for "[qwen_xml] recovered" in
						-- the CodeCompanion log (:checkhealth codecompanion prints its path) to
						-- see how often that happens before adding a tool back.
						--
						-- `skill` has to be resident: its system prompt IS the catalogue, and a
						-- catalogue the model never sees is a catalogue it never reaches for.
						--
						-- run_command earns its slot because most of the skills here are
						-- procedures that shell out -- dart-vibe drives the dart CLI,
						-- neovim-news-update walks git log. Without it a skill loads and then
						-- cannot be acted on.
						--
						-- edit_file is the only tool here that writes; without it every "change
						-- this file" turns into the model narrating a patch at you. It is the
						-- stock insert_edit_into_file with a flat schema (one edit per call):
						-- that tool's `edits` array of objects is the shape qwen3-coder writes
						-- malformed and Ollama then discards (ollama#18563), and its schema
						-- alone is ~2.5k tokens of every request.
						--
						-- Dropped to keep the list short, and what covers them: file_search ->
						-- run_command with `rg --files` or `fd`; create_file -> run_command with
						-- a heredoc, since the edit tools error on a path that does not exist
						-- yet rather than creating it. Pull either back in for one chat with
						-- `@create_file`.
						--
						-- Nothing in this list prompts -- see the approval overrides above -- so
						-- trim it back to { "skill" } to keep chat read-only.
						default_tools = {
							"skill",
							"grep_search",
							"read_file",
							"run_command",
							"edit_file",
						},
					},
				},

				-- The deterministic path. qwen3-coder:30b picks up a skill cue
				-- far less reliably than a frontier model does, so a skill can
				-- also be injected outright. Both routes below list skills
				-- marked disable-model-invocation, which the tool deliberately
				-- hides -- grill-with-docs is one.
				--
				-- slash_commands() gives every skill its own command, the way
				-- Claude Code does: `/grilling`, `/neovim-news-update`. It runs
				-- while this table is being built, i.e. at startup, so the
				-- command list is fixed until the next restart -- see its
				-- docstring for what that does and does not freeze. The scan is
				-- two readdirs and the first 60 lines of each SKILL.md.
				--
				-- `/skill` stays as the discovery path: it re-scans on every
				-- invocation, so it finds skills added since startup, and it
				-- shows the descriptions side by side when you know the job but
				-- not which skill covers it.
				slash_commands = vim.tbl_extend("error", require("danvim.codecompanion_skills").slash_commands(), {
					["skill"] = {
						callback = function(chat)
							require("danvim.codecompanion_skills").slash_command(chat)
						end,
						description = "Load a skill into the chat",
						opts = { contains_code = false },
					},
				}),
			},
			inline = { adapter = "ollama" },
			cmd = { adapter = "ollama" },
		},

		display = {
			chat = {
				window = {
					layout = "vertical",
					width = 0.35,
				},
			},
			-- The diff is a display setting for chat tools -- with
			-- require_confirmation_after off above, an edit lands before it
			-- would ever be drawn -- but for the inline strategy (<leader>ae)
			-- it IS the approval gate: inline has no require_* opts, it just
			-- shows the diff and waits for accept/reject. Off, so an inline
			-- edit is applied straight into the buffer and `u` is the undo.
			diff = {
				enabled = false,
			},
		},

		opts = {
			-- Local model, no per-token cost, so the usual "are you sure"
			-- friction buys nothing.
			send_code = true,
		},
	},
	-- Cheap triggers that exist from startup, before the plugin is loaded: the
	-- chat events (ChatCreated/ChatOpened), the command line (`:CodeCompanion ...`,
	-- which `<leader>ae` parks you on) and :CodeCompanionWarm.
	init = function()
		ollama.setup_triggers()
	end,
	-- lazy loads the plugin on the first CodeCompanion command and runs this
	-- synchronously before re-dispatching it, so the model starts loading while
	-- that command is still opening its window.
	config = function(_, opts)
		require("codecompanion").setup(opts)
		ollama.wrap_codecompanion()
		pcall(ollama.warm)
	end,
	keys = {
		{ "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "[a]I chat [t]oggle" },
		-- Context: the current file, or any file through the /file picker. Both act on
		-- the most recent chat, opening it (or a new one) first, so they work cold.
		{
			"<leader>ac",
			function()
				require("danvim.codecompanion_actions").add_current_file()
			end,
			desc = "[a]I add current file to [c]ontext",
		},
		{
			"<leader>aC",
			function()
				require("danvim.codecompanion_actions").add_file_picker()
			end,
			desc = "[a]I pick a file to add to [C]ontext",
		},
		{
			"<leader>al",
			function()
				require("danvim.codecompanion_actions").clear()
			end,
			desc = "[a]I c[l]ear the conversation",
		},
		-- The visual-range entry points. CodeCompanion, CodeCompanionChat and
		-- CodeCompanionActions all declare range = true, so a selection is
		-- passed through rather than silently dropped.
		{ "<leader>ap", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI action [p]alette" },
		{
			"<leader>ae",
			":CodeCompanion ",
			mode = "v",
			desc = "[A]I [e]dit selection",
			-- silent = false is load-bearing: this leaves you on the cmdline
			-- with `:'<,'>CodeCompanion ` pre-filled so you can type the
			-- instruction. A silent mapping would submit an empty prompt.
			silent = false,
		},
		-- The built-in "Explain code" prompt (alias `explain`) on the selection. The
		-- leading `:` in visual mode makes the cmdline start with `'<,'>`.
		{ "<leader>ax", ":CodeCompanion /explain<cr>", mode = "v", desc = "[a]I e[x]plain selection" },
		{
			"<leader>ad",
			"<cmd>CodeCompanionChat Add<cr>",
			mode = "v",
			desc = "AI a[d]d selection to chat",
		},
	},
}
