return {
	{
		"ember-theme/nvim",
		config = function()
			vim.cmd.colorscheme("ember")
		end,
	},
	{ "serhez/teide.nvim" },
	{ "initsyscall/themeInitNvim" },
}
