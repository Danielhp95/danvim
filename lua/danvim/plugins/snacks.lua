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
		-- Render images inline in markdown/latex/etc. docs (e.g. dart-vibe plots).
		-- Needs a graphics-capable terminal (kitty ✓) + imagemagick on PATH.
		-- tmux passthrough is auto-detected; `allow-passthrough on` is set in tmux.conf.
		image = {
			enabled = true,
			doc = {
				enabled = true, -- render images referenced in the document
				inline = true, -- draw them inline where the terminal supports it (kitty)
				float = true, -- also preview under the cursor in a float on hover
				-- Caps are in CELLS, and the box is already clamped to the window,
				-- so a big max_width just means "use the full window width". More
				-- cells = more physical pixels for the same image = crisper text.
				-- At 256 cols x 10px cells, 240 gives a plot ~2400px of real estate,
				-- roughly 1:1 with a 150dpi matplotlib figure (was 120 -> 1200px,
				-- a 2x downscale that was smearing the axis labels).
				max_width = 240,
				max_height = 70, -- never binds; the window is ~52 rows
			},
			convert = {
				magick = {
					-- Non-PNG rasters get resampled by magick first; Lanczos
					-- (-resize) beats box averaging (-scale) on text, and the cap
					-- should not sit below the display box computed above.
					default = { "{src}[0]", "-resize", "2560x1440>" },
					-- Vector/math/pdf are rasterised by us, so density is a direct
					-- resolution dial. Higher density raises the output DPI tag too,
					-- so the on-screen size is unchanged - only the detail goes up.
					vector = { "-density", 384, "{src}[{page}]" },
					math = { "-density", 384, "{src}[{page}]", "-trim" },
					pdf = { "-density", 384, "{src}[{page}]", "-background", "white", "-alpha", "remove", "-trim" },
				},
			},
		},
		indent = { enabled = true },
		input = { enabled = false },
		picker = {
			enabled = true,
			-- also search dotfiles and gitignored files (untracked ones are
			-- already listed by fd/rg). Toggle live with <a-h> / <a-i>.
			hidden = true,
			ignored = true,
			exclude = { ".git", "node_modules", ".venv", "__pycache__", "result" },
			sources = {
				files = { hidden = true, ignored = true },
				grep = { hidden = true, ignored = true },
				smart = { hidden = true, ignored = true },
				explorer = { hidden = true, ignored = true },
				git_files = { untracked = true, submodules = true },
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
		-- Inside tmux, TERM is tmux-256color and snacks can't reliably detect the
		-- outer terminal (its client_termname query doesn't come back as kitty), so
		-- it skips kitty's unicode-placeholder placement and inline images land in
		-- the terminal's top-left corner instead of on the buffer line. Forcing
		-- kitty detection restores placeholder placement, which composes with the
		-- tmux DCS-passthrough transform snacks already applies. We always run kitty
		-- as the outer terminal, so this is safe; outside tmux native detection
		-- already works, so only override there. (folke/snacks.nvim#2439)
		--
		-- NOTE: snacks' other tmux gotcha — leaking its `\27[>q` terminal-name query
		-- as pasted text (folke/snacks.nvim#2332) — is handled at the tmux layer:
		-- tmux.conf sets `extended-keys on` (not `always`) so snacks takes its
		-- leak-free detection path.
		if vim.env.TMUX then
			vim.env.SNACKS_KITTY = "true"
		end

		require("snacks").setup(opts)

		-- Runtime toggle for inline images (bound to <leader>Sit in keybindings.lua).
		-- snacks only reads image.config.enabled when a buffer first attaches; the
		-- live inline renderer (snacks.image.inline) keeps redrawing via its own
		-- autocmds afterwards and never re-checks the flag, so flipping it alone does
		-- nothing. We gate the renderer's discovery pass (doc.find_visible, called
		-- from inline:update) on the flag: when disabled it reports zero images, so
		-- update() closes existing placements and never re-adds them.
		do
			local doc = require("snacks.image.doc")
			local find_visible = doc.find_visible
			doc.find_visible = function(buf, cb)
				if Snacks.image.config.enabled == false then
					return cb({}) -- no images found → renderer tears down placements
				end
				return find_visible(buf, cb)
			end

			vim.api.nvim_create_user_command("SnacksImageToggle", function()
				local was_on = Snacks.image.config.enabled ~= false
				Snacks.image.config.enabled = not was_on
				if was_on then
					-- remove now; the find_visible guard blocks any redraw
					require("snacks.image.placement").clean()
				else
					-- re-enable: attach any buffers skipped while off, then nudge the
					-- already-attached renderers (via an event they listen to) to
					-- re-run update() and repaint the currently visible windows.
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						if vim.api.nvim_buf_is_loaded(buf) then
							doc.attach(buf)
							pcall(vim.api.nvim_exec_autocmds, "BufWinEnter", { buffer = buf })
						end
					end
				end
				vim.notify(
					(was_on and "Disabled" or "Enabled") .. " inline images",
					was_on and vim.log.levels.WARN or vim.log.levels.INFO
				)
			end, { desc = "Toggle snacks inline image rendering" })
		end

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
