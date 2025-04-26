return {
  {
    'saghen/blink.cmp',
    event = 'InsertEnter',
    dependencies = {
      'rafamadriz/friendly-snippets',
      'moyiz/blink-emoji.nvim',
      'Kaiser-Yang/blink-cmp-avante',
      'xzbdmw/colorful-menu.nvim',
      {
        'Kaiser-Yang/blink-cmp-git',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
      {
        'Kaiser-Yang/blink-cmp-dictionary',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
    },

    version = 'v1.*',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- TODO: cmdline is not working for some reason!
      keymap = {
        ['K'] = { 'show_signature', 'hide_signature', 'fallback' },
        ['<C-j>'] = { 'select_next' },
        ['<C-k>'] = { 'select_prev' },
        ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
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
        default = { 'git', 'path', 'lsp', 'snippets', 'buffer', 'dictionary', 'emoji' },
        providers = {
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
            should_show_items = function()
              return vim.tbl_contains(
                -- Enable emoji completion only for git commits and markdown.
                { 'gitcommit', 'markdown' },
                vim.o.filetype
              )
            end,
          },
          dictionary = {
            module = 'blink-cmp-dictionary',
            name = 'Dict',
            min_keyword_length = 3,
            opts = {
              -- options for blink-cmp-dictionary
            },
            should_show_items = function()
              return vim.tbl_contains(
                -- Enable emoji completion only for git commits and markdown.
                { 'text', 'markdown' },
                vim.o.filetype
              )
            end,
          },
        },
      },
      signature = {
        enabled = true,
        window = {
          show_documentation = true,
          border = 'single',
        },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        -- nerd_font_variant = "mono",
        nerd_font_variant = 'normal',
      },
      completion = {
        list = {
          selection = {
            preselect = false,
            auto_insert = true,
          },
        },
        ghost_text = {
          enabled = true,
          show_with_menu = false, -- only show when menu is closed (todo: do i want this)
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = 'single',
          },
        },
        menu = {
          border = 'single',
          draw = {
            columns = { { 'label' }, { 'kind_icon', 'kind', gap = 1 }, { 'source_name' } },
            components = {
              label_description = { ellipsis = false }, -- Show full description
              label = {
                text = require('colorful-menu').blink_components_text,
                highlight = require('colorful-menu').blink_components_highlight,
              },
            },
          },
        },
      },
    },
  },
}
