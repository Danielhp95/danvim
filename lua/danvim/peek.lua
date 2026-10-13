--- Peek the definition under the cursor in a floating window (<leader>ld):
--- lspsaga's peek_definition without lspsaga. The float shows the real buffer,
--- so it can be edited, and peeking from inside it stacks another on top.
local M = {}

-- Mappings can't be window-local, so `q` is mapped everywhere and only means
-- "close" inside a peek.
vim.keymap.set("n", "q", function()
	return vim.w.danvim_peek and "<cmd>close<cr>" or "q"
end, { expr = true })

function M.definition()
	vim.lsp.buf.definition({
		on_list = function(what)
			local item = what.items[1]
			-- Above the cursor when it sits in the lower half of the screen.
			local up = vim.fn.screenpos(0, vim.fn.line("."), vim.fn.col(".")).row > vim.o.lines / 2
			local win = vim.api.nvim_open_win(vim.fn.bufadd(item.filename), true, {
				relative = "cursor",
				anchor = up and "SW" or "NW",
				row = up and 0 or 1,
				col = 0,
				width = math.min(125, vim.o.columns - 4),
				height = math.min(25, math.floor(vim.o.lines / 2) - 4),
				title = " " .. vim.fn.fnamemodify(item.filename, ":~:.") .. " ",
			})
			vim.w[win].danvim_peek = true
			vim.api.nvim_win_set_cursor(win, { item.lnum, item.col - 1 })
			vim.cmd("normal! zvzt")
		end,
	})
end

return M
