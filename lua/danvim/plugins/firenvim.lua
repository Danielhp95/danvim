-- Firenvim: embeds this neovim inside browser text areas.
-- Requires the Firenvim browser extension. The native-messaging manifest
-- (~/.mozilla/native-messaging-hosts/firenvim.json) is written once by
-- `:call firenvim#install(0)`; its launcher resolves `nvim` from PATH, so it
-- survives nix rebuilds without reinstalling.
return {
	"glacambre/firenvim",
	-- Load eagerly when the browser launched us; otherwise lazy-load so it
	-- costs nothing in a normal terminal session.
	lazy = not vim.g.started_by_firenvim,
	module = false,
	config = function()
		vim.g.firenvim_config = {
			localSettings = {
				[".*"] = {
					-- Never auto-takeover: click the firenvim icon (or <C-e>) to activate
					takeover = "never",
					cmdline = "neovim",
				},
			},
		}

		if vim.g.started_by_firenvim then
			-- Browser text areas are small: keep UI minimal
			vim.o.laststatus = 0
			vim.o.showtabline = 0
			vim.o.guifont = "monospace:h10"
		end
	end,
}
