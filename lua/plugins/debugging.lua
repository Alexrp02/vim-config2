return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"mxsdev/nvim-dap-vscode-js",
			-- build debugger from source
			{
				"microsoft/vscode-js-debug",
				version = "1.x",
				build = "npm i && npm run compile vsDebugServerBundle && mv dist out",
			},
		},
		config = function()
			local dap = require("dap")
			vim.keymap.set("n", "<leader>dc", function()
				dap.continue()
			end)
			vim.keymap.set("n", "<F10>", function()
				dap.step_over()
			end)
			vim.keymap.set("n", "<F11>", function()
				dap.step_into()
			end)
			vim.keymap.set("n", "<F12>", function()
				dap.step_out()
			end)
			vim.keymap.set("n", "<Leader>dt", function()
				dap.toggle_breakpoint()
			end)
			vim.keymap.set("n", "<Leader>db", function()
				dap.set_breakpoint()
			end)
			vim.keymap.set("n", "<Leader>dl", function()
				dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end)
			vim.keymap.set("n", "<Leader>dr", function()
				dap.repl.open()
			end)

			dap.adapters.firefox = {
				type = "executable",
				command = "node",
				args = { os.getenv("HOME") .. "/DAPS/vscode-firefox-debug/dist/adapter.bundle.js" },
			}

			if not dap.adapters["pwa-chrome"] then
				dap.adapters["pwa-chrome"] = {
					type = "server",
					host = "localhost",
					port = "${port}",
					executable = {
						command = "node",
						args = {
							require("mason-registry").get_package("js-debug-adapter"):get_install_path()
							.. "/js-debug/src/dapDebugServer.js",
							"${port}",
						},
					},
				}
			end
			dap.adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = {
						require("mason-registry").get_package("js-debug-adapter"):get_install_path()
						.. "/js-debug/src/dapDebugServer.js",
						"${port}",
					},
				},
			}
			for _, lang in ipairs({
				"typescript",
				"javascript",
				"typescriptreact",
				"javascriptreact",
			}) do
				dap.configurations[lang] = dap.configurations[lang] or {}
				table.insert(dap.configurations[lang], {
					type = "pwa-chrome",
					request = "launch",
					name = "Launch Chrome",
					url = "http://localhost:8000",
					sourceMaps = true,
					webRoot = vim.fn.getcwd(),
					runtimeExecutable = "/usr/bin/google-chrome",
					runtimeArgs = { "--disable-gpu", "--remote-debugging-port=9222", "--no-sandbox" },
				})
				table.insert(dap.configurations[lang], {
					type = "pwa-node",
					request = "attach",
					name = "Attach to node process",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
					sourceMaps = true,
					program = "${workspaceFolder}/dist/apps/backend/main.js",
					outFiles = {"${workspaceFolder}/dist/**/*.js"}
				})
			end
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
			"mxsdev/nvim-dap-vscode-js",
			-- build debugger from source
			{
				"microsoft/vscode-js-debug",
				version = "1.x",
				build = "npm i && npm run compile vsDebugServerBundle && mv dist out",
			},
		},
		config = function()
			local dap, dapui = require("dap"), require("dapui")
			dapui.setup()
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end
		end,
	},
}
