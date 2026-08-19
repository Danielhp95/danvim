return {
	-- Browser-based live preview: markdown, HTML (+CSS/JS), AsciiDoc and SVG,
	-- with KaTeX and Mermaid. Complements markview.nvim (style.lua) rather than
	-- duplicating it: markview renders *in* the buffer, this serves the rendered
	-- document to a real browser and live-updates it as you type, which is what
	-- you want for checking how a README will actually look.
	--
	-- Replaced iamcco/markdown-preview.nvim, dormant since 2023-10 (last tag
	-- 2022), so nixpkgs could only ever ship a three-year-old snapshot of it.
	-- This one is pure Lua: no node bundle, no `cd app && yarn install`. What
	-- went away with it is the wider diagram set -- PlantUML, flowchart.js, dot
	-- and chart.js all came from that node bundle; Mermaid and KaTeX are the
	-- only two rendered here.
	--
	-- Unlike its predecessor, `cmd` is a real lazy trigger: :LivePreview is a
	-- global user command, where markdown-preview declared `-buffer` local ones
	-- from a FileType autocmd that lazy's stub could never reach in time.
	{
		"brianhuster/live-preview.nvim",
		cmd = "LivePreview",
		config = function()
			-- Not `opts`: lazy would route it through require('livepreview').setup,
			-- which upstream marks @deprecated in favour of the config module.
			require("livepreview.config").set {
				picker = "snacks.picker", -- snacks is already in the plugin set
			}
		end,
	},
  -- {
  --   'obsidian-nvim/obsidian.nvim',
  --   version = '*', -- recommended, use latest release instead of latest commit
  --   lazy = true,
  --   ft = 'markdown',
  --   -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  --   -- event = {
  --   --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   --   -- refer to `:h file-pattern` for more examples
  --   --   "BufReadPre path/to/my-vault/*.md",
  --   --   "BufNewFile path/to/my-vault/*.md",
  --   -- },
  --   ---@module 'obsidian'
  --   ---@type obsidian.config
  --   opts = {
  --     completion = {
  --       nvim_cmp = false, -- Enables completion using nvim_cmp
  --       blink = true, -- Enables completion using blink.cmp
  --       min_chars = 0, -- Trigger completion at 2 chars.
  --       create_new = true, -- Set to false to disable new note creation in the picker
  --     },
  --     picker = {
  --       name = 'telescope.nvim', -- Use telescope.nvim for the picker
  --     },
  --     workspaces = {
  --       {
  --         name = 'SonyAI',
  --         path = '~/vaults/sony_ai',
  --       },
  --       {
  --         name = 'NewYork',
  --         path = '~/vaults/new_york',
  --       },
  --     },
  --   },
  -- },
}
