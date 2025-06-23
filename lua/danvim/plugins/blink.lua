return {
  -- {
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   event = "InsertEnter",
  --   config = function()
  --     require("copilot").setup({})
  --   end,
  -- },
  {
    'saghen/blink.cmp',
    event = 'InsertEnter',
    dependencies = {
      'rafamadriz/friendly-snippets',
      'moyiz/blink-emoji.nvim',
      'Kaiser-Yang/blink-cmp-avante',
      'xzbdmw/colorful-menu.nvim',
      "fang2hou/blink-copilot",
      {
        'Kaiser-Yang/blink-cmp-git',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
      -- {
      --   'Kaiser-Yang/blink-cmp-dictionary',
      --   dependencies = { 'nvim-lua/plenary.nvim' },
      -- },
    },

    version = 'v1.*',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- TODO: cmdline is not working for some reason!
      keymap = {
        ['<CR>'] = { 'select_and_accept', 'fallback' },
        ['<C-,>'] = {
          function(cmp)
            if cmp.is_visible() then
              return cmp.select_and_accept()
            else
              return cmp.show()
            end
          end,
          'fallback',
        },
        ['K'] = { 'show_signature', 'hide_signature', 'fallback' },
        ['<C-j>'] = { 'select_next' },
        ['<C-k>'] = { 'select_prev' },
        ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<Tab>'] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          'snippet_forward',
          'fallback',
        },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      },

      sources = {
        default = { 'copilot', 'avante', 'git', 'path', 'lsp', 'snippets', 'buffer', 'emoji' },
        providers = {
          lsp = {
            async = true, -- basedpyright is slow, do we want this
          },
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
          git = {
            -- NOTE: if you can't see users / issues, it's probably because you need to login via `gh auth login`
            module = 'blink-cmp-git',
            name = 'Git',
            opts = {
              -- options for the blink-cmp-git
            },
          },
          avante = {
            module = 'blink-cmp-avante',
            name = 'Avante',
            opts = {
              -- options for blink-cmp-avante
            },
          },
          emoji = {
            module = 'blink-emoji',
            name = 'Emoji',
            score_offset = 15, -- Tune by preference
            opts = { insert = true }, -- Insert emoji (default) or complete its name
            -- should_show_items = function()
            --   return vim.tbl_contains(
            --     -- Enable emoji completion only for git commits and markdown.
            --     { 'gitcommit', 'markdown' },
            --     vim.o.filetype
            --   )
            -- end,
          },
          -- dictionary = {
          --   module = 'blink-cmp-dictionary',
          --   name = 'Dict',
          --   min_keyword_length = 3,
          --   opts = {
          --     -- options for blink-cmp-dictionary
          --   },
          --   should_show_items = function()
          --     return vim.tbl_contains(
          --       -- Enable emoji completion only for git commits and markdown.
          --       { 'text', 'markdown' },
          --       vim.o.filetype
          --     )
          --   end,
          -- },
        },
      },
      signature = {
        enabled = true,
        window = {
          show_documentation = true,
          border = 'rounded',
        },
      },
      appearance = {
        use_nvim_cmp_as_default = false,
        -- nerd_font_variant = "mono",
        nerd_font_variant = 'normal',
      },
      completion = {
        -- TODO: look into this!
        list = {
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
          window = {
            border = 'rounded',
          },
        },
        menu = {
          border = 'rounded',
          draw = {
            -- columns = { { 'label' }, { 'kind_icon', 'kind', gap = 1 }, { 'extra_info' } },
            columns = { { 'label' }, { 'kind_icon', 'kind', gap = 1 } },
            components = {
              label_description = { ellipsis = false }, -- Show full description
              label = {
                text = require('colorful-menu').blink_components_text,
                highlight = require('colorful-menu').blink_components_highlight,
              },
              extra_info = {
                width = { max = 30 },
                text = function(ctx)
                  return ctx.item.detail
                end,
              },
            },
          },
        },
      },
    },
  },
}
