return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		animate = { enabled = false },
		dashboard = { enabled = false }, -- I don't want a dashboard when I open nvim
		terminal = { enabled = true },
		bigfile = { enabled = true },
		explorer = { enabled = true },
		indent = { enabled = true },
		input = { enabled = false },
		picker = {
			enabled = true,
			sources = {
				lsp_symbols = {
					filter = {
						default = {
							"Class",
							"Constructor",
							"Enum",
							"Field",
							"Function",
							"Interface",
							"Method",
							"Module",
							"Namespace",
							"Package",
							"Property",
							"Struct",
							"Trait",
							"Variable",
							"Constant",
						},
					},
				},
			},
			win = {
				input = {
					keys = {
						["<M-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
						["<M-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
					},
				},
			},
			layouts = {
				default = {
					layout = {
						backdrop = false,
						row = 1,
						width = 0.97,
						min_width = 80,
						height = 0.99,
						border = "none",
						box = "vertical",
						{ win = "preview", title = "{preview}", height = 0.6, border = true },
						{
							box = "vertical",
							border = true,
							title = "{title} {live} {flags}",
							title_pos = "center",
							{ win = "input", height = 1, border = "bottom" },
							{ win = "list", border = "none" },
						},
					},
				},
			},
		},
		notifier = { enabled = false },
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		zen = { enabled = true, toggles = { dim = false } },
	},
	config = function(_, opts)
		require("snacks").setup(opts)

		local function get_site_packages()
			local venv = os.getenv("VIRTUAL_ENV")
			if not venv then
				vim.notify("VIRTUAL_ENV is not set", vim.log.levels.WARN)
				return nil
			end
			local site_packages = vim.fn.globpath(venv .. "/lib/python*/site-packages", "", 0, 1)[1]
			if not site_packages then
				vim.notify("Could not locate site-packages in VIRTUAL_ENV", vim.log.levels.ERROR)
				return nil
			end
			return site_packages
		end

		vim.keymap.set("n", "<leader>fd", function()
			local site_packages = get_site_packages()
			if not site_packages then
				return
			end
			Snacks.picker.grep({
				dirs = { site_packages },
				title = "Grep Dependencies (site-packages)",
				args = {
					"--glob",
					"!*.pyc",
					"--glob",
					"!__pycache__/",
					"--glob",
					"!*.dist-info/",
					"--glob",
					"!*.egg-info/",
				},
			})
		end, { desc = "Grep installed Python dependencies" })

		vim.keymap.set("n", "<leader>fD", function()
			local site_packages = get_site_packages()
			if not site_packages then
				return
			end
			Snacks.picker.files({
				dirs = { site_packages },
				title = "Find Files in Dependencies",
				args = { "--glob", "*.py", "--glob", "!__pycache__/" },
			})
		end, { desc = "Find files in Python dependencies" })
	end,
}
