-- sets the cwd to the parent of the buffer that has a .git or Makefile
-- Didn't quite work for some reason. Try again in future
-- vim.api.nvim_create_autocmd("BufEnter", {
-- 	callback = function(ctx)
-- 		local root = vim.fs.root(ctx.buf, {".git", "Makefile"})
-- 		if root then vim.uv.chdir(root) end
-- 	end,
-- })

return {
  'sanfusu/neovim-undotree',
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
    'nyngwang/NeoZoom.lua',
    opts = { winopts = { offset = 'left', height = 0.99, width = 0.99 } },
  },
}
