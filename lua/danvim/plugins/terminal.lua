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
      require("floaterm.api").cycle_term_bufs("prev")
    end, { buffer = buf })
    vim.keymap.set({ "n", "t" }, "<C-S-k>", function()
      require("floaterm.api").cycle_term_bufs("next")
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
