-- TODO: use `gevent=true` to bypass the issue with fetching data forever on `aws s3`` calls
-- Look into this to have pytest integration https://github.com/mfussenegger/nvim-dap-python
local Dap = {
	url = "https://github.com/mfussenegger/nvim-dap",
	-- lua keymaps that call require('dap') load it via lazy's module hook
	cmd = { "DapNew", "DapContinue", "DapToggleBreakpoint", "DapSetLogLevel", "DapShowLog", "DapEval" },
	dependencies = {
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		local dap = require("dap")
		-- Codicon signs, one per breakpoint state (icons.lua). Each texthl is a
		-- group of the same name, coloured in plugins/colorschemes.lua.
		local icons = require("danvim.icons").dap
		vim.fn.sign_define("DapBreakpoint", { text = icons.breakpoint, texthl = "DapBreakpoint" })
		vim.fn.sign_define("DapBreakpointCondition", { text = icons.condition, texthl = "DapBreakpointCondition" })
		vim.fn.sign_define("DapLogPoint", { text = icons.log_point, texthl = "DapLogPoint" })
		vim.fn.sign_define("DapStopped", { text = icons.stopped, texthl = "DapStopped", linehl = "DapStoppedLine" })
		vim.fn.sign_define("DapBreakpointRejected", { text = icons.rejected, texthl = "DapBreakpointRejected" })

		require("nvim-dap-virtual-text").setup({
			commented = true,
		})

		-- Python
		dap.adapters.python = {
			type = "executable",
			command = "python",
			args = { "-m", "debugpy.adapter" },
		}

		dap.configurations.python = {
			{
				-- The first three options are required by nvim-dap
				type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
				request = "launch",
				name = "Launch file",
				-- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

				justMyCode = false,
				program = "${file}", -- This configuration will launch the current file if used.
				pythonPath = "python",
				gevent = true,
				subProcess = true,
			},
			{
				type = "python",
				request = "launch",
				name = "run_local",
				cwd = vim.uv.cwd(),
				logToFile = true,
				program = "/home/dev/venv/bin/dart",
				args = {
					"run_local",
					"-m",
					"both",
					"${file}",
				},
			},
			{
				type = "python",
				request = "launch",
				name = "Python Debug in ~/Projects/sai",
				program = "${file}",
				console = "integratedTerminal",
				cwd = "/home/dani/Projects/sai",
			},
		}
	end,
}

local dap_view = {
	"igorlfs/nvim-dap-view",
	cmd = { "DapViewOpen", "DapViewToggle", "DapViewWatch" },
	dependencies = { "mfussenegger/nvim-dap" },
	version = "1.*",
	---@module 'dap-view'
	---@type dapview.Config
	opts = {},
}

return { Dap, dap_view }
