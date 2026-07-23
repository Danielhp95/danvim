-- Previous terminal plugins (tabterm.nvim + floaterm), commented out in favour
-- of terminals.nvim below.
--[==[
local function drop_esc(buf)
  -- defer so this runs after volt has installed its maps, regardless of order
  vim.schedule(function()
    pcall(vim.keymap.del, "n", "<Esc>", { buffer = buf })
  end)
end

local function drop_esc_and_q(buf)
  -- defer so this runs after volt has installed its maps, regardless of order
  vim.schedule(function()
    pcall(vim.keymap.del, "n", "<Esc>", { buffer = buf })
    pcall(vim.keymap.del, "n", "q", { buffer = buf })
    -- floaterm maps <C-j>/<C-k> in BOTH n and t modes; the terminal mode is the
    -- one that matters while typing in the float, so delete both.
    pcall(vim.keymap.del, "n", "<C-j>", { buffer = buf })
    pcall(vim.keymap.del, "n", "<C-k>", { buffer = buf })
    pcall(vim.keymap.del, "t", "<C-j>", { buffer = buf })
    pcall(vim.keymap.del, "t", "<C-k>", { buffer = buf })
    vim.keymap.set({ "n", "t" }, "<C-S-j>", function()
      require("floaterm.api").cycle_term_bufs("next")
    end, { buffer = buf })
    vim.keymap.set({ "n", "t" }, "<C-S-k>", function()
      require("floaterm.api").cycle_term_bufs("prev")
    end, { buffer = buf })
  end)
end


return {
	{
		"kremovtort/tabterm.nvim",
		cmd = "Tabterm",
		keys = { "<leader><leader>" },
		opts = {
			ui = {
				border = "rounded",
				sidebar_width = 30,
				float = {
					width = 0.9,
					height = 0.9,
				},
			},
		},
	},
	{
		"nvzone/floaterm",
		dependencies = "nvzone/volt",
		opts = {
		  size = { h = 95, w = 95 },
		  mappings = {
		    sidebar = drop_esc,
		    term = drop_esc_and_q,
      },
    },
		cmd = "FloatermToggle",
		config = function(_, opts)
		  require("floaterm").setup(opts)

		  -- A terminal whose `name` is nil (e.g. after cancelling a sidebar
		  -- rename, which stores vim.ui.input's nil result) crashes the
		  -- statusbar redraw: floaterm.ui.bar concatenates `active_term.name`
		  -- with no fallback (unlike ui.items). cycle_term_bufs triggers that
		  -- redraw via switch_buf, so cycling surfaces the crash. Guard the
		  -- name in the bar's layout section before the original renderer runs.
		  local state = require("floaterm.state")
		  local utils = require("floaterm.utils")
		  local layout = require("floaterm.layout")

		  -- Upstream buffer leak: new_term() eagerly creates a scratch buffer in
		  -- its defaults table, and gen_term_bufs() then tbl_extends the existing
		  -- terminal entry over it — so for every terminal that already has a
		  -- buffer, the fresh one is orphaned (one leaked buffer per terminal per
		  -- workspace open). Rebuild gen_term_bufs to only create a buffer when
		  -- the terminal doesn't have a valid one.
		  utils.gen_term_bufs = function()
		    for i, term in ipairs(state.terminals) do
		      if term.buf and not vim.api.nvim_buf_is_valid(term.buf) then
		        term.buf = nil
		      end
		      if not term.buf then
		        state.terminals[i] = vim.tbl_extend("force", utils.new_term(), term)
		      else
		        term.time = term.time or os.date("%H:%M")
		        term.name = term.name or "Terminal"
		      end
		      utils.add_keymap(i, state.terminals[i].buf)
		    end
		  end

		  local orig_bar = layout.bar[1].lines
		  layout.bar[1].lines = function(buf)
		    local found = utils.get_term_by_key(state.buf)
		    if found and found[2] and found[2].name == nil then
		      found[2].name = "Terminal"
		    end
		    return orig_bar(buf)
		  end
		end,
	},
}
]==]

return {
	{
		"sassanh/terminals.nvim",
		-- load eagerly: setup() is what creates the global maps (<M-0>…<M-9>
		-- slot jumps, <M-m> layout cycle), so they must exist before any
		-- lazy-load trigger fires
		lazy = false,
		config = function()
			local terminals = require("terminals")
			terminals.setup({
				keys = {
					-- defaults use macOS <D-…> (Cmd); remap to match the old
					-- floaterm setup on Linux
					toggle = "<leader><leader>f",
					cycle_layout = "<M-m>",
					-- cycle terminals, same as the old floaterm buffer maps
					go_right = "<C-S-j>",
					go_left = "<C-S-k>",
					move_right = "<M-S-j>",
					move_left = "<M-S-k>",
					focus = "<M-i>",
					unfocus = "<M-S-i>",
					leave = "<M-[>",
					toggle_reverse_search = "<M-/>",
					paste = "<C-S-v>",
					paste_in_place = "<C-S-p>",
					-- <M-0>…<M-9> jump to terminal slots (Alt instead of Cmd)
					modifier = "M",
				},
				layouts = {
					-- near-fullscreen
					{ width = "95%", height = "99%", row = 0 },
					-- left half
					{ width = "50%", height = terminals.default_height, row = 0, col = 0 },
					-- right half
					{ width = "50%", height = terminals.default_height, row = 0, col = "right" },
					-- bottom half
					{ width = "100%", height = "50%", row = "bottom", col = 0 },
				},
				preserved_keys = {},
			})
		end,
	},
}
