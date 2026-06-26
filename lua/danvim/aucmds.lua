-- [[ Highlight on yank ]]: Flashed text after being yanked
-- See `:help vim.hl.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

-- Sets tab to 2 spaces on markdown files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.bo.shiftwidth = 2
		vim.bo.softtabstop = 2
		vim.bo.expandtab = true
	end,
})

-- Make visual selection bold on all colorschemes
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		local visual = vim.api.nvim_get_hl(0, { name = "Visual" })
		visual.bold = true
		vim.api.nvim_set_hl(0, "Visual", visual)
	end,
})

-- Create missing directories on save
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		local dir = vim.fn.expand("<afile>:p:h")
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
	end,
})

-- Auto-open quickfix when populated, close when empty
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
	pattern = "*",
	callback = function()
		if vim.fn.getqflist({ size = 0 }).size == 0 then
			vim.cmd("cclose")
		else
			vim.cmd("cwindow")
		end
	end,
})

-- Auto-resize splits when the host window changes size
vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		local current = vim.api.nvim_get_current_tabpage()
		vim.cmd("tabdo wincmd =")
		vim.api.nvim_set_current_tabpage(current)
	end,
})

-- Restore last cursor position on file open
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local lcount = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Close auxiliary filetypes with `q`
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "help", "qf", "lspinfo", "checkhealth", "man", "notify" },
	callback = function(args)
		vim.bo[args.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
	end,
})
