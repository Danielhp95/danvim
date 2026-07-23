return {
	{
		"saghen/blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			"rafamadriz/friendly-snippets",
			"moyiz/blink-emoji.nvim",
			"Kaiser-Yang/blink-cmp-avante",
			"xzbdmw/colorful-menu.nvim",
			"fang2hou/blink-copilot",
			"archie-judd/blink-cmp-words",
			"daliusd/blink-cmp-fuzzy-path", -- Fuzzy searches paths recursively
			{
				"Kaiser-Yang/blink-cmp-git",
				dependencies = { "nvim-lua/plenary.nvim" },
			},
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

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
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
				["K"] = { "show_signature", "hide_signature", "fallback" },
				["<C-j>"] = { "select_next" },
				["<C-k>"] = { "select_prev" },
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
					AvanteInput = { "avante" },
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
					git = {
						-- NOTE: if you can't see users / issues, it's probably because you need to login via `gh auth login`
						module = "blink-cmp-git",
						name = "Git",
						opts = {
							-- options for the blink-cmp-git
						},
					},
					avante = {
						module = "blink-cmp-avante",
						name = "Avante",
						opts = {
							-- options for blink-cmp-avante
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
					border = "rounded",
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
					window = {
						border = "rounded",
					},
				},
				menu = {
					border = "rounded",
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
					["<C-j>"] = { "select_next", "fallback" },
					["<C-k>"] = { "select_prev", "fallback" },
					["<Tab>"] = { "select_next", "fallback" },
					["<S-Tab>"] = { "select_prev", "fallback" },
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
							auto_insert = true,
						},
					},
				},
			},
		},
	},
}
