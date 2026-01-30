-- sets the cwd to the parent of the buffer that has a .git or Makefile
-- Didn't quite work for some reason. Try again in future
-- vim.api.nvim_create_autocmd("BufEnter", {
-- 	callback = function(ctx)
-- 		local root = vim.fs.root(ctx.buf, {".git", "Makefile"})
-- 		if root then vim.uv.chdir(root) end
-- 	end,
-- })

return {
  {
    'amitds1997/remote-nvim.nvim',
    version = '*', -- Pin to GitHub releases
    dependencies = {
      'nvim-lua/plenary.nvim', -- For standard functions
      'MunifTanjim/nui.nvim', -- To build the plugin UI
      'nvim-telescope/telescope.nvim', -- For picking b/w different remote methods
    },
    config = true,
  },
  'sanfusu/neovim-undotree',  -- NOTE: checkout built-in version
  'folke/which-key.nvim',
  { 'windwp/nvim-autopairs', event = 'InsertEnter', opts = {} },
  {
    'kylechui/nvim-surround',
    opts = {
      highlight = {
        duration = 0, -- Highlight always on
      },
    },
  },
  {
    'esmuellert/codediff.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    cmd = 'CodeDiff',
  },
}
