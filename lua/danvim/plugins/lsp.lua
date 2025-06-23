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

    vim.lsp.config('ty', {
      { cmd = { 'ty', 'server' }, filetypes = { 'python' }, root_markers = { 'ty.toml', 'pyproject.toml', '.git' } },
    })

    -- vim.lsp._enabled_configs('pyrefly', {
    --   cmd = { 'pyrefly', 'lsp' },
    --   filetypes = { 'python' },
    --   root_markers = {
    --     'pyrefly.toml',
    --     'pyproject.toml',
    --     'setup.py',
    --     'setup.cfg',
    --     'requirements.txt',
    --     'Pipfile',
    --     '.git',
    --   },
    --   on_exit = function(code, _, _)
    --     vim.notify('Closing Pyrefly LSP exited with code: ' .. code, vim.log.levels.INFO)
    --   end,
    -- })

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

    --JSON
    vim.lsp.config('jsonls', {
      cmd = { 'vscode-json-languageserver', '--stdio' },
      filetypes = { 'json', 'jsonc' },
      {
        init_options = { provideFormatter = true },
      },
    })
    vim.lsp.enable 'jsonls'

    -- Markdown: TODO: not in love with this
    lspconfig.marksman.setup {}
    -- Hyprland cofig
    -- DOES NOT support folds nicely, which is a must for my config file
    -- lspconfig.hyprls.setup({})

    -- NUSHELL
    vim.lsp.config('nushell', {
      cmd = { 'nu', '--lsp' },
      filetypes = { 'nu' },
    })
    vim.lsp.enable 'nushell'
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
