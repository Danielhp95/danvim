-- Toggle the signature help window for the call the cursor sits inside.
-- Used from normal mode, where blink's own keymap table never reaches: blink
-- only auto-hides the window on InsertLeave and its CursorMoved handler bails
-- out outside of insert mode, so a window opened from normal mode would
-- otherwise hang around over an unrelated line. Hence the one-shot teardown.
local function toggle_signature()
	local cmp = require("blink.cmp")
	if cmp.is_signature_visible() then
		return cmp.hide_signature()
	end
	cmp.show_signature()
	vim.api.nvim_create_autocmd({ "CursorMoved", "BufLeave" }, {
		once = true,
		callback = function()
			require("blink.cmp").hide_signature()
		end,
	})
end

return {
	{
		"saghen/blink.cmp",
		-- LspAttach, not just InsertEnter: signature help is useless if it only
		-- arrives once you have already started typing, and every buffer that can
		-- produce a signature is by definition one an LSP attached to.
		event = { "InsertEnter", "CmdlineEnter", "LspAttach" },
		-- Normal-mode half of <C-k>; the insert-mode half lives in opts.keymap
		-- below. Going through lazy's `keys` also loads blink when the session
		-- has not entered insert mode yet.
		keys = {
			{
				"<C-k>",
				toggle_signature,
				mode = "n",
				desc = "Toggle LSP signature help for enclosing call",
			},
		},
		dependencies = {
			"rafamadriz/friendly-snippets",
			"moyiz/blink-emoji.nvim",
			"xzbdmw/colorful-menu.nvim",
			"fang2hou/blink-copilot",
			"archie-judd/blink-cmp-words",
			"daliusd/blink-cmp-fuzzy-path", -- Fuzzy searches paths recursively
			"mikavilpas/blink-ripgrep.nvim",
			"ribru17/blink-cmp-spell", -- Spell suggestions from Neovim's spellcheck
			"MahanRahmati/blink-nerdfont.nvim", -- Nerd Font icon completion (trigger ":")
			"bydlw98/blink-cmp-env", -- Environment variable ($VAR) completion
		},

		version = "v1.*",

		-- Hide Copilot ghost suggestions when blink.cmp menu opens
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "BlinkCmpMenuOpen",
				callback = function()
					if vim.g.copilot_enabled ~= false then
						local ok, copilot = pcall(require, "copilot.suggestion")
						if ok then
							copilot.dismiss()
							vim.b.copilot_suggestion_hidden = true
						end
					end
				end,
			})
			vim.api.nvim_create_autocmd("User", {
				pattern = "BlinkCmpMenuClose",
				callback = function()
					vim.b.copilot_suggestion_hidden = false
				end,
			})
		end,

		-- Same as lazy's default handler, plus the signature help reformatting
		-- (which patches a blink internal, so it has to run after setup)
		config = function(_, opts)
			require("blink.cmp").setup(opts)
			require("danvim.blink_signature").setup()
		end,

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- Keep blink out of dressing.nvim's vim.ui.input prompts.
			--
			-- blink already refuses to complete in prompt buffers -- its own
			-- enabled() ends in `vim.bo.buftype ~= 'prompt'` -- but dressing builds
			-- its input as buftype=nofile, so that guard never recognises it.
			-- blink then attaches on InsertEnter and installs the insert-mode <CR>
			-- below (select_and_accept) as a buffer-local map on the prompt. As
			-- soon as you type a few words its menu opens (the buffer/words
			-- sources match ordinary prose), and Enter selects a completion item
			-- instead of submitting. Dressing's own submit is still underneath as
			-- the fallback, reachable only with the menu closed (<C-e>, then <CR>).
			--
			-- This bit every vim.ui.input prompt, not one plugin: it surfaced as
			-- <leader>ae (codecompanion.lua) doing nothing, because Enter on a bare
			-- `:'<,'>CodeCompanion ` opens this prompt for the instruction.
			--
			-- Returning false here stops the keymap being installed at all: blink
			-- only applies it on InsertEnter when enabled() is true. The macro,
			-- vim.b.completion and real buftype=prompt checks in blink's enabled()
			-- still run on top of this.
			enabled = function()
				return vim.bo.filetype ~= "DressingInput"
			end,
			keymap = {
				["<CR>"] = { "select_and_accept", "fallback" },
				["<C-CR>"] = {
					function(cmp)
						if cmp.is_visible() then
							return cmp.select_and_accept()
						else
							return cmp.show()
						end
					end,
					"fallback",
				},
				["<C-j>"] = { "select_next" },
				-- Menu open: cycle upwards. Otherwise toggle the signature help
				-- window, matching <C-k> in normal mode (see `keys` above).
				["<C-k>"] = {
					function(cmp)
						if cmp.is_visible() then
							return cmp.select_prev()
						end
						if cmp.is_signature_visible() then
							return cmp.hide_signature()
						end
						return cmp.show_signature()
					end,
				},
				-- Jump half a page (25 items) in completion menu
				["<a-u>"] = { "scroll_documentation_up", "fallback" },
				["<a-d>"] = { "scroll_documentation_down", "fallback" },
				["<C-u>"] = {
					function(cmp)
						return cmp.select_prev({ count = 25 })
					end,
					"fallback",
				},
				["<C-d>"] = {
					function(cmp)
						return cmp.select_next({ count = 25 })
					end,
					"fallback",
				},
				["<C-e>"] = {
					function(cmp)
						if cmp.is_visible() then
							return cmp.hide()
						else
							return cmp.show()
						end
					end,
				},
				["<Tab>"] = {
					function(cmp)
						if cmp.snippet_active() then
							return cmp.accept()
						else
							return cmp.select_and_accept()
						end
					end,
					"snippet_forward",
					"fallback",
				},
				["<S-Tab>"] = { "snippet_backward", "fallback" },
				-- Quick select with Alt+1-9
				["<A-1>"] = {
					function(cmp)
						cmp.accept({ index = 1 })
					end,
				},
				["<A-2>"] = {
					function(cmp)
						cmp.accept({ index = 2 })
					end,
				},
				["<A-3>"] = {
					function(cmp)
						cmp.accept({ index = 3 })
					end,
				},
				["<A-4>"] = {
					function(cmp)
						cmp.accept({ index = 4 })
					end,
				},
				["<A-5>"] = {
					function(cmp)
						cmp.accept({ index = 5 })
					end,
				},
				["<A-6>"] = {
					function(cmp)
						cmp.accept({ index = 6 })
					end,
				},
				["<A-7>"] = {
					function(cmp)
						cmp.accept({ index = 7 })
					end,
				},
				["<A-8>"] = {
					function(cmp)
						cmp.accept({ index = 8 })
					end,
				},
				["<A-9>"] = {
					function(cmp)
						cmp.accept({ index = 9 })
					end,
				},
			},
			-- Prioritize exact matches in fuzzy sorting
			fuzzy = {
				sorts = {
					"exact",
					"score",
					-- Tie-break: sink _private/__dunder members below public ones
					-- (matters mostly for python's `self.` / module completions).
					-- Only runs on equal fuzzy score, so typing `_` still
					-- surfaces them.
					function(a, b)
						local a_priv = a.label:sub(1, 1) == "_"
						local b_priv = b.label:sub(1, 1) == "_"
						if a_priv ~= b_priv then
							return b_priv
						end
					end,
					"sort_text",
				},
			},
			sources = {
				-- Code buffers get code sources only; prose/config-only sources
				-- (emoji, nerdfont, dictionary, spell, env) are added per filetype
				-- so they stop polluting code completions.
				-- NOTE: we no longer have 'git' because it just got in the way
				default = {
					"lazydev",
					"fuzzy-path",
					"lsp",
					"copilot",
					"snippets",
					"buffer",
					"ripgrep",
				},
				per_filetype = {
					markdown = { inherit_defaults = true, "emoji", "nerdfont", "dictionary", "spell" },
					gitcommit = { inherit_defaults = true, "emoji", "spell" },
					text = { inherit_defaults = true, "dictionary", "spell" },
					tex = { inherit_defaults = true, "dictionary", "spell" },
					sh = { inherit_defaults = true, "env" },
					bash = { inherit_defaults = true, "env" },
					zsh = { inherit_defaults = true, "env" },
					nu = { inherit_defaults = true, "env" },
				},
				providers = {
					["fuzzy-path"] = {
						name = "Fuzzy Path",
						module = "blink-cmp-fuzzy-path",
						score_offset = 0,
						opts = {
							filetypes = {
								"markdown",
								"json",
								"python",
								"nix",
								"csv",
								"txt",
								"yaml",
							}, -- optional
						},
					},
					ripgrep = {
						module = "blink-ripgrep",
						name = "Ripgrep",
						-- Project words are a fallback, not a rival to the LSP:
						-- rank them below and only for longer keywords
						score_offset = -3,
						min_keyword_length = 4,
						-- see the full configuration below for all available options
						---@module "blink-ripgrep"
						---@type blink-ripgrep.Options
						opts = {
							backend = {
								use = "gitgrep-or-ripgrep",
							},
						},
					},
					lsp = {
						async = true,
					},
					copilot = {
						name = "copilot",
						module = "blink-copilot",
						-- 0, not 100: with 100 copilot always outranked the LSP and
						-- its guesses buried real symbols at the top of the menu
						score_offset = 0,
						async = true,
						opts = {
							max_completions = 2,
						},
					},
					emoji = {
						module = "blink-emoji",
						name = "Emoji",
						score_offset = 15, -- Tune by preference
						opts = { insert = true }, -- Insert emoji (default) or complete its name
					},
					nerdfont = {
						module = "blink-nerdfont",
						name = "Nerd Fonts",
						score_offset = 15, -- Tune by preference
						opts = { insert = true }, -- Insert icon (default) or complete its name
					},
					spell = {
						module = "blink-cmp-spell",
						name = "Spell",
						-- Only show spell suggestions when 'spell' is set; see opts below
						opts = {},
					},
					env = {
						module = "blink-cmp-env",
						name = "Env",
						opts = {
							item_kind = require("blink.cmp.types").CompletionItemKind.Variable,
							show_braces = false,
							show_documentation_window = true,
						},
					},
					lazydev = {
						module = "lazydev.integrations.blink",
						name = "LazyDev",
						score_offset = 100, -- Show lazydev's items first
					},
					dictionary = {
						name = "blink-cmp-words",
						module = "blink-cmp-words.dictionary",
						min_keyword_length = 4,
						-- All available options
						opts = {
							-- A score offset applied to returned items.
							-- By default the highest score is 0 (item 1 has a score of -1, item 2 of -2 etc..).
							score_offset = 0,

							-- Default pointers define the lexical relations listed under each definition,
							-- see Pointer Symbols below.
							-- Default is as below ("antonyms", "similar to" and "also see").
							definition_pointers = { "!", "&", "^" },
						},
					},
				},
			},
			signature = {
				enabled = true,
				window = {
					show_documentation = true,
					-- One line per parameter (see danvim.blink_signature) makes a
					-- wide signature tall, and the default 10 rows cut the last
					-- parameters off entirely
					max_height = 25,
					scrollbar = true,
				},
				trigger = {
					enabled = true,
					-- Show the signature help window after typing a trigger character
					show_on_trigger_character = true,
					-- Show the signature help window when entering insert mode
					show_on_insert = true,
					-- Show the signature help window when the cursor comes after a trigger character when entering insert mode
					show_on_insert_on_trigger_character = true,
				},
			},
			appearance = {
				use_nvim_cmp_as_default = false,
				nerd_font_variant = "normal",
			},
			completion = {
				list = {
					max_items = 200,
					selection = {
						preselect = false,
					},
				},
				ghost_text = {
					enabled = false,
					show_with_menu = true,
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 100,
					treesitter_highlighting = true,
				},
				menu = {
					draw = {
						-- No label_description column: colorful-menu already folds
						-- the item's detail into the label (truncated at 60 chars).
						-- A separate un-ellipsized column duplicated it at full
						-- length, and ty puts entire overload signatures there,
						-- stretching the menu across the screen.
						columns = { { "label" }, { "kind_icon", "kind", gap = 1 }, { "source_name" } },
						components = {
							label = {
								width = { fill = true, max = 60 },
								-- Deferred requires: colorful-menu lives in `opt`, so it is
								-- not on the rtp when this spec table is built at startup
								text = function(...)
									return require("colorful-menu").blink_components_text(...)
								end,
								highlight = function(...)
									return require("colorful-menu").blink_components_highlight(...)
								end,
							},
							source_name = {
								width = { max = 15 },
								text = function(ctx)
									return "[" .. ctx.source_name .. "]"
								end,
								highlight = "BlinkCmpSource",
							},
						},
					},
				},
			},
			cmdline = {
				enabled = true,
				keymap = {
					preset = "inherit",
					["<CR>"] = { "accept", "fallback" },
					-- No "fallback" on the cycling keys. Whenever the menu is closed or
					-- the list is momentarily empty (a source re-running, nothing
					-- matching), blink passed the raw key through to the cmdline — where
					-- <C-j> is <NL>, which *submits* the search, and <C-k> opens digraph
					-- entry, swallowing the next two keys. "show_and_insert" returns nil
					-- when the menu is already open, so cycling still falls through to
					-- select_next/prev; when the menu dropped out it just reopens it.
					-- The "prev" keys open on the *last* item (idx -1), matching blink's
					-- own cmdline preset for <S-Tab>.
					["<C-j>"] = { "show_and_insert", "select_next" },
					["<C-k>"] = {
						function(cmp)
							return cmp.show_and_insert({ initial_selected_item_idx = -1 })
						end,
						"select_prev",
					},
					["<Tab>"] = { "show_and_insert", "select_next" },
					["<S-Tab>"] = {
						function(cmp)
							return cmp.show_and_insert({ initial_selected_item_idx = -1 })
						end,
						"select_prev",
					},
					["<C-e>"] = { "hide", "fallback" },
				},
				completion = {
					menu = {
						auto_show = true,
						draw = {
							columns = { { "kind_icon" }, { "label" } },
						},
					},
					list = {
						selection = {
							preselect = false,
							-- Deliberately false. With auto_insert, every <C-j>/<C-k>
							-- rewrote the cmdline to the highlighted candidate, which
							-- re-ran the sources and re-fuzzied the list against the new
							-- text. blink only restores the previous selection when the
							-- item resurfaces within the top 10 (completion/list.lua), so
							-- past a few steps the selection kept resetting and cycling
							-- wandered instead of stepping. Now the list stays pinned to
							-- what you typed; <CR> accepts the highlighted item into the
							-- cmdline, a second <CR> runs it.
							auto_insert = false,
						},
					},
				},
			},
		},
	},
}
