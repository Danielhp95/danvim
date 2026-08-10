-- Here we do two things:
-- (1) Set up the configuration for packages used in the declaration of LSPs
-- (2) Call lspconfig.config function, which sets all the individual LSPs

-- Formmater
local Conform = {
	"stevearc/conform.nvim",
	-- <leader>lf calls require('conform') and loads it via lazy's module hook
	cmd = "ConformInfo",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			-- Conform will run multiple formatters sequentially
			python = { "ruff_format", "ruff" },
			yaml = { "yamlfmt" },
			nix = { "nixfmt" },
			json = { "jq" },
			-- Use the "_" filetype to run formatters on filetypes that don't
			-- have other formatters configured.
			["_"] = { "trim_whitespace" },
		},
		notify_on_error = true,
	},
}

-- LUA: type info for nvim Lua API + plugin libs
local lazydev = {
	"folke/lazydev.nvim",
	ft = "lua",
	opts = {
		library = {
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			{ path = "${3rd}/busted/library" },
			{ path = "${3rd}/luassert/library" },
			"snacks.nvim",
		},
	},
}

-- Useful status updates for LSP. Standalone spec, NOT a dependency of
-- lspconfig: lazy.nvim force-loads dependencies with their parent, which
-- would defeat the LspAttach trigger.
local fidget = {
	"j-hui/fidget.nvim",
	event = "LspAttach",
	opts = {},
}

-- Diagnostics / LSP reference list. Used by <leader>dP, <leader>db and
-- <leader>lr. Previously declared inside plugins/telescope.lua; moved here
-- when telescope was removed so the bindings survive.
local trouble = {
	"folke/trouble.nvim",
	cmd = "Trouble",
	opts = { auto_preview = true },
}

-- LSP Configuration & Plugins
local lspconfig_toplevel = {
	"neovim/nvim-lspconfig",
	-- vim.lsp.enable() only registers FileType autocmds; BufReadPre fires
	-- before FileType, so deferring to first real buffer loses nothing
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		vim.lsp.config["ty"] = {
			cmd = { "ty", "server" },
			filetypes = { "python" },
			root_markers = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
			capabilities = {
				textDocument = {
					diagnostic = {},
				},
			},
			settings = {
				ty = {
					-- Diagnostics for the whole project, not just open buffers
					diagnosticMode = "workspace",
					completions = {
						-- Suggest symbols that aren't imported yet and insert the
						-- import on accept
						autoImport = true,
						-- Complete functions/methods as `foo($1)` snippets. blink's
						-- auto_brackets sees the parens in the item and won't
						-- double-insert.
						completeFunctionParentheses = true,
					},
					-- Served on demand; toggled client-side with <leader>lh
					inlayHints = {
						variableTypes = true,
						callArgumentNames = true,
					},
				},
			},
		}
		vim.lsp.enable("ty")

		vim.lsp.config["lua_ls"] = {
			cmd = { "lua-language-server" },
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim", "hl" }, -- vim and hyprland
					},
					workspace = {
						checkThirdParty = false,
						-- When making the lua change to hyprland
						-- https://wiki.hypr.land/Configuring/Start/#language-style-and-syntax
						library = {
							vim.fn.expand("$VIMRUNTIME"),
							"${3rd}/busted/library",
							"${3rd}/luassert/library",
						},
						maxPreload = 5000,
						preloadFileSize = 10000,
					},
					telemetry = { enable = false },
				},
			},
		}
		vim.lsp.enable("lua_ls")

		-- LUAU: noctalia plugin API (noctalia/dart-plugin/*.luau).
		-- noctalia injects `noctalia`, `barWidget`, `ui`, `panel`, ... straight
		-- into each plugin VM's global namespace -- there is nothing to
		-- require() -- so with a bare luau_lsp every one of them is an unknown
		-- global. Feeding luau-lsp a definitions file is the counterpart to
		-- putting $VIMRUNTIME on lua_ls's library above. The definitions are
		-- hand-written (noctalia ships none) and live next to the plugin they
		-- describe; the lint config that goes with them is noctalia/.luaurc.
		local noctalia_defs = vim.fn.expand("~/nix_config/noctalia/noctalia.d.luau")
		local luau_cmd = { "luau-lsp", "lsp" }
		if vim.uv.fs_stat(noctalia_defs) then
			table.insert(luau_cmd, "--definitions=" .. noctalia_defs)
		end
		vim.lsp.config["luau_lsp"] = {
			cmd = luau_cmd,
			settings = {
				-- Defaults to "roblox", which switches on sourcemap and
				-- .robloxrc handling that means nothing for noctalia plugins.
				["luau-lsp"] = { platform = { type = "standard" } },
			},
		}
		vim.lsp.enable("luau_lsp")
		-- latex
		vim.lsp.enable("texlab")
		-- NIX
		vim.lsp.enable("nixd")
		-- BASH
		vim.lsp.enable("bashls")
		-- DOCKER
		vim.lsp.enable("docker_language_server")
		-- YAML
		vim.lsp.enable("yamlls")
		--JSON
		vim.lsp.enable("jsonls")
		-- NUSHELL
		vim.lsp.enable("nushell")
	end,
}

return {
	lspconfig_toplevel,
	fidget,
	lazydev,
	Conform,
	trouble,
}
