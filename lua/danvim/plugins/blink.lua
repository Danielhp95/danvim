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
					"sort_text",
				},
			},
			sources = {
				-- Use a function to enable completions in comments for all languages (TODO: check if this is still needed)
				default = function()
					-- NOTE: we no longer have 'git' because it just got in the way
					return { "avante", "fuzzy-path", "lsp", "copilot", "snippets", "buffer", "ripgrep", "emoji" }
				end,
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
								"json",
							}, -- optional
						},
					},
					ripgrep = {
						module = "blink-ripgrep",
						name = "Ripgrep",
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
						score_offset = 100,
						async = true,
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
					dictionary = {
						name = "blink-cmp-words",
						module = "blink-cmp-words.dictionary",
						-- All available options
						opts = {
							-- A score offset applied to returned items.
							-- By default the highest score is 0 (item 1 has a score of -1, item 2 of -2 etc..).
							score_offset = 0,

							-- Default pointers define the lexical relations listed under each definition,
							-- see Pointer Symbols below.
							-- Default is as below ("antonyms", "similar to" and "also see").
							pointer_symbols = { "!", "&", "^" },
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
				-- TODO: look into this!
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
						columns = { { "label", "label_description" }, { "kind_icon", "kind", gap = 1 }, { "source_name" } },
						components = {
							label_description = { ellipsis = false }, -- Show full description
							label = {
								text = require("colorful-menu").blink_components_text,
								highlight = require("colorful-menu").blink_components_highlight,
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
