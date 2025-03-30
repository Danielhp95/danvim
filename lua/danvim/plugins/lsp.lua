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
    'ray-x/lsp_signature.nvim',
    'folke/neodev.nvim',
  },
  config = function()
    local lspconfig = require 'lspconfig'

    lspconfig.basedpyright.setup {
      root_dir = lspconfig.util.find_git_ancestor,
      settings = {
        basedpyright = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = 'openFilesOnly',
            useLibraryCodeForTypes = true,
          },
        },
      },
    }
    -- lua
    lspconfig.lua_ls.setup {
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
    -- latex
    lspconfig.texlab.setup {}
    -- NIX
    lspconfig.nixd.setup {}
    -- BASH
    lspconfig.bashls.setup {
      cmd = { 'bash-language-server', 'start' },
    }
    -- DOCKER
    lspconfig.docker_compose_language_service.setup {}
    -- YAML
    lspconfig.yamlls.setup {
      settings = {
        redhat = {
          telemetry = {
            enabled = false,
          },
        },
      },
    }
    -- Markdown: TODO: not in love with this
    lspconfig.marksman.setup {}
    -- Hyprland cofig
    -- DOES NOT support folds nicely, which is a must for my config file
    -- lspconfig.hyprls.setup({})
    -- lspconfig.type
    require('lsp_signature').setup {
      bind = true, -- This is mandatory, otherwise border config won't get registered.
      handler_opts = {
        border = 'rounded',
      },
    }
  end,
}

local LspSaga = {
  'nvimdev/lspsaga.nvim',
  config = function()
    require('lspsaga').setup { lightbulb = { enable = false } }
  end,
}

-- Add rounded borders to hover
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = 'rounded',
})

return {
  lspconfig_toplevel,
  LspSaga,
  Conform,
}
