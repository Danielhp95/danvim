-- Here we do two things:
-- (1) Set up the configuration for packages used in the declaration of LSPs
-- (2) Call lspconfig.config function, which sets all the individual LSPs

-- Formmater
local Conform = {
	"stevearc/conform.nvim",
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

-- LSP Configuration & Plugins
local lspconfig_toplevel = {
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Useful status updates for LSP
		{ "j-hui/fidget.nvim", event = "LspAttach", opts = {} },
		lazydev,
	},
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
	Conform,
}
