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
						schema = {
							-- Qwen3-Coder-30B-A3B, the model
							-- non_home_manager_config/ollama.nix pulls. Pinned
							-- rather than left to the picker so a fresh session
							-- doesn't start on whatever ollama lists first.
							model = { default = "qwen3-coder:30b" },
							-- Match OLLAMA_CONTEXT_LENGTH on the server side.
							-- Measured free there: 64k costs nothing against 32k
							-- and leaves ~3GB of VRAM spare.
							num_ctx = { default = 65536 },
							-- The adapter otherwise probes the model for thinking
							-- support. qwen3-coder is not a reasoning model, and
							-- leaving this to auto-detection risks paying for a
							-- reasoning preamble on a model that has none.
							think = { default = false },
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
							-- default. Nothing consults this while the gate
							-- above is false; it is here so gy does the obvious
							-- thing if that gate is ever restored.
							allowed_in_yolo_mode = true,
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
						-- FIVE. Do not add a sixth without reading this.
						--
						-- qwen3-coder emits proper JSON tool calls while it is
						-- given roughly five tools or fewer. Past that it
						-- switches to its native XML form -- `<function=name>
						-- <parameter=x>` -- inside the message content. Ollama's
						-- qwen3-coder parser is supposed to pick that up and
						-- intermittently does not (ollama#17276, open); the call
						-- then arrives as ordinary prose with `tool_calls`
						-- empty. CodeCompanion continues a turn only when the
						-- response carries tool calls -- Chat:done runs them and
						-- auto_submit_success fires the next request, and that
						-- loop is the whole agent -- so a dropped call ends the
						-- turn mid-task and sits there until you press <CR>,
						-- which just re-rolls the sampling.
						--
						-- Measured against this exact config, same prompt, one
						-- tool removed at a time:
						--   7 tools  6 dropped calls in 21 requests
						--   5 tools  0 in 10
						-- block/goose hit the same wall at 11 tools and put the
						-- threshold at ~5 (goose#6883).
						--
						-- `skill` has to be resident: its system prompt IS the
						-- catalogue, and a catalogue the model never sees is a
						-- catalogue it never reaches for.
						--
						-- run_command earns its slot because most of the skills
						-- here are procedures that shell out -- dart-vibe drives
						-- the dart CLI, neovim-news-update walks git log.
						-- Without it a skill loads and then cannot be acted on.
						--
						-- insert_edit_into_file is the only tool here that
						-- writes; without it every "change this file" turns into
						-- the model narrating a patch at you.
						--
						-- Dropped to get under the threshold, and what covers
						-- them: file_search -> run_command with `rg --files` or
						-- `fd`; create_file -> run_command with a heredoc, since
						-- insert_edit_into_file errors on a path that does not
						-- exist yet rather than creating it. Pull either back in
						-- for one chat with `@create_file` -- which re-crosses
						-- the threshold for that chat, so expect the stalls back.
						--
						-- Nothing in this list prompts -- see the approval
						-- overrides above -- so trim it back to { "skill" } to
						-- keep chat read-only.
						default_tools = {
							"skill",
							"grep_search",
							"read_file",
							"run_command",
							"insert_edit_into_file",
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
	-- lazy.nvim would otherwise call setup(opts) for us; taking the config
	-- function over means also registering the recovery handler for the tool
	-- calls ollama drops on the floor. Its header explains the bug in full --
	-- in short, a dropped call ends the turn mid-task, and the five-tool cap
	-- above reduces how often that happens without eliminating it.
	config = function(_, opts)
		require("codecompanion").setup(opts)
		require("danvim.codecompanion_xml_tools").setup()
	end,
	keys = {
		{ "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "[a]I chat toggle" },
		{ "<leader>ac", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "AI [c]hat (new)" },
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
		{
			"<leader>ad",
			"<cmd>CodeCompanionChat Add<cr>",
			mode = "v",
			desc = "AI a[d]d selection to chat",
		},
	},
}
