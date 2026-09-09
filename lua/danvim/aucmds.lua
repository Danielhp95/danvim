-- [[ Highlight on yank ]]: Flashed text after being yanked
-- See `:help vim.hl.hl_op()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.hl_op()
	end,
	group = highlight_group,
	pattern = "*",
})

-- Sets tab to 2 spaces on markdown files, plus link-aware paste and
-- word-first treesitter selection
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(args)
		vim.bo.shiftwidth = 2
		vim.bo.softtabstop = 2
		vim.bo.expandtab = true

		-- Visual `p`: if the clipboard holds a URL/path, wrap the selection
		-- in a markdown link instead of overwriting it.
		local function looks_like_link_target(s)
			if s == "" or s:find("%s") then
				return false
			end
			return s:match("^%a[%w+.-]*://") ~= nil -- scheme://...
				or s:match("^www%.") ~= nil
				or s:match("^mailto:") ~= nil
				or s:match("^~/") ~= nil
				or s:match("^%.%.?/") ~= nil
				or s:match("^/") ~= nil
		end

		vim.keymap.set("x", "p", function()
			local clip = vim.fn.getreg("+")
			local trimmed = clip:match("^%s*(.-)%s*$")

			if not looks_like_link_target(trimmed) then
				vim.cmd("normal! p")
				return
			end

			vim.cmd('normal! "zy')
			local selected = vim.fn.getreg("z")
			vim.fn.setreg("z", ("[%s](%s)"):format(selected, trimmed))
			vim.cmd('normal! gv"zp')
		end, { buffer = args.buf, desc = "Paste as markdown link when clipboard is a URL/path" })

		-- <CR>: markdown's inline grammar has no word-level nodes, so the
		-- global treesitter parent-select jumps straight to a whole
		-- paragraph. Select just the word first; once a selection already
		-- exists, grow it the normal treesitter way.
		vim.keymap.set({ "n", "x", "o" }, "<CR>", function()
			if vim.fn.mode() == "n" then
				vim.cmd("normal! viw")
			else
				vim.treesitter.select("parent", vim.v.count1)
			end
		end, { buffer = args.buf, desc = "Select word, then grow via treesitter" })

		-- <C-b>/<C-i>/<C-x>/<C-u>: toggle bold/italic/strikethrough/underline.
		-- Visual mode wraps (or unwraps, if already wrapped) the selection.
		-- Insert mode drops an empty marker pair around the cursor, or skips
		-- past the closing marker if already sitting on one (so a second
		-- press exits the formatting instead of nesting it).
		local function visual_toggle_wrap(open_mark, close_mark)
			vim.cmd('normal! "zy')
			local text = vim.fn.getreg("z")

			local result
			if
				text:sub(1, #open_mark) == open_mark
				and text:sub(-#close_mark) == close_mark
				and #text >= #open_mark + #close_mark
			then
				result = text:sub(#open_mark + 1, #text - #close_mark)
			else
				result = open_mark .. text .. close_mark
			end

			vim.fn.setreg("z", result)
			vim.cmd('normal! gv"zp')
		end

		local function insert_toggle_wrap(open_mark, close_mark)
			local row, col = unpack(vim.api.nvim_win_get_cursor(0))
			local after = vim.api.nvim_get_current_line():sub(col + 1)

			if after:sub(1, #close_mark) == close_mark then
				vim.api.nvim_win_set_cursor(0, { row, col + #close_mark })
				return
			end

			vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { open_mark .. close_mark })
			vim.api.nvim_win_set_cursor(0, { row, col + #open_mark })
		end

		local formatting_marks = {
			{ key = "<C-b>", open = "**", close = "**", desc = "bold" },
			{ key = "<C-i>", open = "*", close = "*", desc = "italic" },
			{ key = "<C-x>", open = "~~", close = "~~", desc = "strikethrough" },
			{ key = "<C-u>", open = "<u>", close = "</u>", desc = "underline" },
		}

		for _, m in ipairs(formatting_marks) do
			vim.keymap.set("x", m.key, function()
				visual_toggle_wrap(m.open, m.close)
			end, { buffer = args.buf, desc = "Toggle " .. m.desc .. " on selection" })

			vim.keymap.set("i", m.key, function()
				insert_toggle_wrap(m.open, m.close)
			end, { buffer = args.buf, desc = "Toggle " .. m.desc .. " at cursor" })
		end
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
