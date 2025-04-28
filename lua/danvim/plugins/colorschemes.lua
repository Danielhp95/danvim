return {
  'olimorris/onedarkpro.nvim',
  lazy = false,
  config = function()
    local onedarkpro = require 'onedarkpro'
    onedarkpro.setup {
      log_level = 'debug',
      caching = true,
      colors = {
        light_gray = '#646870',
        dark_gray = '#1A1A1A',
        darker_gray = '#141414',
        darkest_gray = '#080808',
        color_column = '#181919',
        bg_statusline = '#1f1f23',
        visual_grey = '#212121',
      },
      highlights = {
        PmenuSel = { bg = '${visual_grey}', bold = true },
        -- The little thing telling us how deep into the scrollbar we are
        PmenuThumb = { fg = '${green}', bg = '${green}' },
        BlinkCmpScrollBarThumb = { fg = '${green}', bg = '${green}' },
        --
        Folded = { bold = true, fg = '${green}' },
        CmdLine = {
          bg = '${dark_gray}',
          fg = '${fg}',
        },
        CmdLineBorder = {
          bg = '${dark_gray}',
          fg = '${dark_gray}',
        },
        LspFloat = {
          bg = '${darker_gray}',
        },
        LspFloatBorder = {
          bg = '${darker_gray}',
          fg = '${darker_gray}',
        },
        Search = {
          fg = '${black}',
          bg = '${highlight}',
        },
        TelescopeBorder = {
          fg = '${darkest_gray}',
          bg = '${darkest_gray}',
        },
        TelescopePromptBorder = {
          fg = '${darker_gray}',
          bg = '${darker_gray}',
        },
        TelescopePromptCounter = { fg = '${fg}' },
        TelescopePromptNormal = { fg = '${fg}', bg = '${darker_gray}' },
        TelescopeWindowBorder = { fg = '${green}' },
        TelescopePromptPrefix = {
          fg = '${green}',
          bg = '${darker_gray}',
        },
        TelescopePromptTitle = {
          fg = '${darker_gray}',
          bg = '${green}',
          bold = true,
        },

        TelescopePreviewTitle = {
          fg = '${darkest_gray}',
          bg = '${green}',
          bold = true,
        },
        TelescopeResultsTitle = {
          fg = '${darkest_gray}',
          bg = '${darkest_gray}',
          bold = true,
        },

        TelescopeMatching = { fg = '${green}' },
        TelescopeNormal = { bg = '${darkest_gray}' },
        TelescopeSelection = { bg = '${darker_gray}' },

        -- WinBar = { bg = '${bg_statusline}' },
        -- WinBarNC = { bg = '${bg_statusline}' },

        -- LSP inlay hints are too dark/not enough contrast with the default nvim_lsp theme plugin
        -- LspInlayHint = { fg = '${light_gray}', bg = '${darker_gray}' },
      },
      plugins = { all = true },
      options = {
        bold = true,
        italic = true,
        undercurl = true,
        highlight_inactive_windows = true,
      },
      styles = {
        comments = 'italic',
        keywords = 'italic',
      },
    }
    vim.cmd.colorscheme 'onedark_dark'
  end,
}
