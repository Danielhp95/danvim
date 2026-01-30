-- Here we do two things:
-- (1) Set up the configuration for packages used in the declaration of LSPs
-- (2) Call lspconfig.config function, which sets all the individual LSPs

-- Formmater
local Conform = {
  'stevearc/conform.nvim',
  opts = {
    formatters_by_ft = {
      lua = { 'stylua' },
      -- Conform will run multiple formatters sequentially
      python = { 'ruff_format', 'ruff' },
      yaml = { 'yamlfmt' },
      nix = { 'nixfmt' },
      json = { 'jq' },
      -- Use the "_" filetype to run formatters on filetypes that don't
      -- have other formatters configured.
      ['_'] = { 'trim_whitespace' },
    },
    notify_on_error = true,
  },
}

-- LUA
-- Additional lua configuration, makes nvim stuff amazing!
local neodev = {
  'folke/neodev.nvim',
  lazy = true,
  opts = {
    library = {
      enabled = true,
      runtime = true,
      types = true,
      plugins = true,
    },
    setup_jsonls = true,
    lspconfig = true,
  },
}

-- LSP Configuration & Plugins
local lspconfig_toplevel = {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Useful status updates for LSP
    { 'j-hui/fidget.nvim', event = 'LspAttach', opts = {} },
    neodev,
  },
  config = function()
    vim.lsp.config['ty'] = {
      cmd = { 'ty', 'server' },
      filetypes = { 'python' },
      root_markers = { 'ty.toml', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
      capabilities = {
        textDocument = {
          diagnostic = {},
        },
      },
    }
    vim.lsp.enable 'ty'

    vim.lsp.config['pyrefly'] = {
      cmd = { 'pyrefly', 'lsp' },
      -- This does not seem to work
      initializationOptions = {
        analyzer = true,
        typechecking = 'strict',
        diagnostics = true,
      },
      --
      filetypes = { 'python' },
      -- root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
      root_markers = { '.git' },
      capabilities = {
        textDocument = {
          publishDiagnostics = {},
          diagnostic = {},
        },
      },
      -- Don't show hover finally works
      settings = {
        python = {
          diagnostics = true,
          analysis = {
            showHoverGoToLinks = false,
          },
        },
      },
      --
    }
    -- vim.lsp.enable 'pyrefly'

    -- -- lua
    vim.lsp.config['lua_ls'] = {
      cmd = { 'lua-language-server' },
      settings = {
        Lua = {
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            checkThirdParty = false,
            library = {
              vim.fn.expand '$VIMRUNTIME',
              require('neodev.config').types(),
              '${3rd}/busted/library',
              '${3rd}/luassert/library',
            },
            maxPreload = 5000,
            preloadFileSize = 10000,
          },
          telemetry = { enable = false },
        },
      },
    }
    vim.lsp.enable 'lua_ls'
    -- -- latex
    vim.lsp.enable 'textlab'
    -- NIX
    vim.lsp.enable 'nixd'
    -- BASH
    vim.lsp.enable 'bashls'
    -- DOCKER
    vim.lsp.enable 'docker_language_server'
    -- YAML
    vim.lsp.enable 'yamlls'
    --JSON
    vim.lsp.enable 'jsonls'
    -- -- Markdown: TODO: not in love with this
    -- vim.lsp.enable 'marksman'
    -- -- Hyprland cofig
    -- -- DOES NOT support folds nicely, which is a must for my config file
    -- -- lspconfig.hyprls.setup({})
    -- -- NUSHELL
    -- vim.lsp.enable 'nushell'
  end,
}

local LspSaga = {
  'nvimdev/lspsaga.nvim',
  config = function()
    require('lspsaga').setup { lightbulb = { enable = false } }
  end,
}

return {
  lspconfig_toplevel,
  LspSaga,
  Conform,
}
