-- Highlight, edit, and navigate code
local context = {
	"nvim-treesitter/nvim-treesitter-context",
	opts = {
		enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
		multiwindow = false, -- Enable multiwindow support.
		max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
		min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
		line_numbers = true,
		multiline_threshold = 20, -- Maximum number of lines to show for a single context
		trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
		mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
		-- Separator between context and content. Should be a single character string, like '-'.
		-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
		separator = nil,
		zindex = 20, -- The Z-index of the context window
		on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching	},
	},
}
local treesitter_objects = {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = { "nvim-treesitter/nvim-treesitter", branch = "main" },
	init = function()
		vim.g.no_plugin_maps = true
	end,
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				-- Automatically jump forward to textobj, similar to targets.vim
				lookahead = true,
				-- You can choose the select mode (default is charwise 'v')

				selection_modes = {
					["@parameter.outer"] = "v", -- charwise
					["@function.outer"] = "V", -- linewise
					["@class.outer"] = "<c-v>", -- blockwise
				},
				include_surrounding_whitespace = false,
			},
			move = {
				-- whether to set jumps in the jumplist
				set_jumps = true,
			},
		})

		-- Selects
		local select = require("nvim-treesitter-textobjects.select")
		vim.keymap.set({ "x", "o" }, "am", function()
			select.select_textobject("@function.outer", "textobjects")
		end)
		vim.keymap.set({ "x", "o" }, "im", function()
			select.select_textobject("@function.inner", "textobjects")
		end)
		vim.keymap.set({ "x", "o" }, "ac", function()
			select.select_textobject("@class.outer", "textobjects")
		end)
		vim.keymap.set({ "x", "o" }, "ic", function()
			select.select_textobject("@class.inner", "textobjects")
		end)
		-- You can also use captures from other query groups like `locals.scm`
		vim.keymap.set({ "x", "o" }, "as", function()
			select.select_textobject("@local.scope", "locals")
		end)

		-- Swaps
		local swap = require("nvim-treesitter-textobjects.swap")
		vim.keymap.set("n", "<leader>a", function()
			swap.swap_next("@parameter.inner")
		end)
		vim.keymap.set("n", "<leader>A", function()
			swap.swap_previous("@parameter.outer")
		end)

		local move = require("nvim-treesitter-textobjects.move")
		vim.keymap.set({ "n", "x", "o" }, "]m", function()
			move.goto_next_start("@function.outer", "textobjects")
		end)
		vim.keymap.set({ "n", "x", "o" }, "]]", function()
			move.goto_next_start("@class.outer", "textobjects")
		end)
		-- You can also pass a list to group multiple queries.
		vim.keymap.set({ "n", "x", "o" }, "]o", function()
			move.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
		end)
		-- You can also use captures from other query groups like `locals.scm` or `folds.scm`
		vim.keymap.set({ "n", "x", "o" }, "]s", function()
			move.goto_next_start("@local.scope", "locals")
		end)
		vim.keymap.set({ "n", "x", "o" }, "]z", function()
			move.goto_next_start("@fold", "folds")
		end)

		vim.keymap.set({ "n", "x", "o" }, "]M", function()
			move.goto_next_end("@function.outer", "textobjects")
		end)
		vim.keymap.set({ "n", "x", "o" }, "][", function()
			move.goto_next_end("@class.outer", "textobjects")
		end)

		vim.keymap.set({ "n", "x", "o" }, "[m", function()
			move.goto_previous_start("@function.outer", "textobjects")
		end)
		vim.keymap.set({ "n", "x", "o" }, "[[", function()
			move.goto_previous_start("@class.outer", "textobjects")
		end)

		vim.keymap.set({ "n", "x", "o" }, "[M", function()
			move.goto_previous_end("@function.outer", "textobjects")
		end)
		vim.keymap.set({ "n", "x", "o" }, "[]", function()
			move.goto_previous_end("@class.outer", "textobjects")
		end)

		-- Go to either the start or the end, whichever is closer.
		-- Use if you want more granular movements
		vim.keymap.set({ "n", "x", "o" }, "]d", function()
			move.goto_next("@conditional.outer", "textobjects")
		end)
		vim.keymap.set({ "n", "x", "o" }, "[d", function()
			move.goto_previous("@conditional.outer", "textobjects")
		end)

		local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

		-- Repeat movement with ; and ,
		-- ensure ; goes forward and , goes backward regardless of the last direction
		vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
		vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

		-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
		vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
	end,
}

-- causes compilation of treesitter with using lazy
-- nix package doesn't work with lazy
local Treesitter = {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	dependencies = {
		-- { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
		-- { "nvim-treesitter/nvim-treesitter-refactor", branch = "master" },
		-- "RRethy/nvim-treesitter-textsubjects",
		context,
		-- "hiphish/rainbow-delimiters.nvim",
	},
	config = function()
		local treesitter = require("nvim-treesitter")
		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				if vim.list_contains(treesitter.get_installed(), vim.treesitter.language.get_lang(args.match)) then
					vim.treesitter.start(args.buf)
				end
			end,
		})
	end,
	-- 	require("nvim-treesitter.configs").setup({
	-- 		-- cannot be used when using nixpkgs nvim-treesitter
	-- 		-- Add languages to be installed here that you want installed for treesitter
	-- 		-- ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'typescript', 'vimdoc', 'vim' },
	--
	-- 		-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
	-- 		auto_install = false,
	--
	-- 		highlight = { enable = true }, -- TODO: what is this?
	-- 		rainbow = { enable = true }, -- Rainbow paranthesis for free!
	-- 		autotag = { enable = true }, -- TODO: What is this?
	-- 		indent = { enable = true }, -- TODO: What is this?
	-- 		incremental_selection = {
	-- 			enable = true,
	-- 			keymaps = {
	-- 				init_selection = "<CR>",
	-- 				node_incremental = "<CR>",
	-- 				scope_incremental = "<S-CR>",
	-- 				node_decremental = "<BS>",
	-- 			},
	-- 		},
	-- 		refactor = {
	-- 			highlight_definitions = {
	-- 				enable = true,
	-- 				clear_on_cursor_move = true,
	-- 			},
	-- 			highlight_current_scope = { enable = false },
	-- 			smart_rename = { enable = false }, -- Not as powerful as LSP saga
	-- 		},
	-- 	})
	-- end,
}

return {
	Treesitter,
	treesitter_objects,
	context,
}
