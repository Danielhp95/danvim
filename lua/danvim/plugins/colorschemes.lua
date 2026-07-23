return {
	{
		"ember-theme/nvim",
		config = function()
			require("ember").setup({
				on_highlights = function(hl, theme)
					local syn = theme.syn

					-- Bold visual selection (the ColorScheme autocmd in aucmds.lua
					-- can fire too late for the startup colorscheme)
					hl["Visual"] = { bg = theme.ui.visual, bold = true }

					-- Parameters get their own color (mauve — otherwise unused in syntax)
					hl["@variable.parameter"] = { fg = syn.mauve, italic = true }

					-- self/cls/this distinct from keywords: rose instead of coral
					hl["@variable.builtin"] = { fg = syn.rose, italic = true }
					-- self/cls in a method signature (python captures these as parameter.builtin)
					hl["@variable.parameter.builtin"] = { fg = syn.rose, italic = true }
					hl["@module.builtin"] = { fg = syn.rose, italic = true }
					hl["@lsp.typemod.variable.defaultLibrary"] = { fg = syn.rose, italic = true }

					-- self/cls/this inside method bodies — pyright/ty emit selfParameter
					-- and clsParameter token types; rust-analyzer emits selfKeyword
					hl["@lsp.type.selfParameter"] = { link = "@variable.builtin" }
					hl["@lsp.type.clsParameter"] = { link = "@variable.builtin" }
					hl["@lsp.type.selfKeyword"] = { link = "@variable.builtin" }
				end,
			})
			vim.cmd.colorscheme("ember")

			-- Search highlight overrides: gray background, keep the
			-- underlying foreground (no fg), bold the matched text.
			local search = { fg = "NONE", bg = "#4c4b49", bold = true }
			for _, group in ipairs({ "Search", "IncSearch", "CurSearch" }) do
				vim.api.nvim_set_hl(0, group, search)
			end
		end,
	},
	{ "serhez/teide.nvim", lazy = true },
	{ "initsyscall/themeInitNvim", lazy = true },
}
