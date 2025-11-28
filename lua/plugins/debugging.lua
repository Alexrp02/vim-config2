return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"mxsdev/nvim-dap-vscode-js",
				config = function()
					require("dap-vscode-js").setup({
						debugger_path = vim.fn.resolve(vim.fn.stdpath("data") .. "/lazy/vscode-js-debug"),
					})
				end,
				adapters = {
					"chrome",
					"pwa-chrome",
					-- "pwa-node",
					"node",
					"node-terminal",
				},
			},
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
			end, { desc = "Continue" })
			vim.keymap.set("n", "<leader>dl", function()
				dap.step_over()
			end, { desc = "Step Over" })
			vim.keymap.set("n", "<leader>di", function()
				dap.step_into()
			end, { desc = "Step Into" })
			vim.keymap.set("n", "<leader>do", function()
				dap.step_out()
			end, { desc = "Step Out" })
			vim.keymap.set("n", "<Leader>dt", function()
				dap.toggle_breakpoint()
			end, { desc = "Toggle Breakpoint" })
			vim.keymap.set("n", "<Leader>dT", function()
				dap.toggle_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Conditional Breakpoint" })
			vim.keymap.set("n", "<Leader>db", function()
				dap.set_breakpoint()
			end, { desc = "Set Breakpoint" })
			vim.keymap.set("n", "<Leader>dr", function()
				dap.repl.open()
			end, { desc = "Open REPL" })
			vim.keymap.set("n", "<Leader>dK", function()
				require("dap.ui.widgets").hover()
			end, { desc = "DAP Hover" })

			-- dap.adapters.firefox = {
			-- 	type = "executable",
			-- 	command = "node",
			-- 	args = { os.getenv("HOME") .. "/DAPS/vscode-firefox-debug/dist/adapter.bundle.js" },
			-- }
			--
			-- if not dap.adapters["pwa-chrome"] then
			-- 	dap.adapters["pwa-chrome"] = {
			-- 		type = "server",
			-- 		host = "localhost",
			-- 		port = "${port}",
			-- 		executable = {
			-- 			command = "node",
			-- 			args = {
			-- 				vim.fn.exepath("js-debug-adapter"),
			-- 				"${port}",
			-- 			},
			-- 		},
			-- 	}
			-- end
			-- dap.adapters["pwa-node"] = {
			-- 	type = "server",
			-- 	host = "localhost",
			-- 	port = "${port}",
			-- 	executable = {
			-- 		command = "node",
			-- 		args = {
			-- 			vim.fn.exepath("js-debug-adapter"),
			-- 			"${port}",
			-- 		},
			-- 	},
			-- }
			dap.adapters.node = {
				type = "executable",
				command = "node",
				args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
			}
			dap.adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = {
						vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
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
					outFiles = { "${workspaceFolder}/dist/**/*.js" },
					autoAttachChildProcesses = true,
					restart = true,
					autoReload = {
						enable = true,
					},
				})
				table.insert(dap.configurations[lang], {
					type = "pwa-node",
					request = "attach",
					name = "Attach to Node.js (port)",
					address = "localhost", -- or the container's IP if not mapped to localhost
					port = function()
						return vim.fn.input("Port: ", "9229")
					end,
					restart = true,
					sourceMaps = true,
					cwd = vim.fn.getcwd(),
					localRoot = vim.fn.getcwd(),
					remoteRoot = function()
						return vim.fn.input("Remote root: ", "/usr/src/app")
					end,
					protocol = "inspector",
					autoAttachChildProcesses = true,
					skipFiles = { "<node_internals>/**" },
				})

				table.insert(dap.configurations[lang], {
					type = "pwa-node",
					request = "attach",
					name = "Auto Attach to node process",
					cwd = vim.fn.getcwd(),
				})
				table.insert(dap.configurations[lang], {
					type = "pwa-node",
					request = "launch",
					name = "Debug nest",
					runtimeExecutable = function()
						local package_manager = vim.fn.input("Package manager (npm/yarn/npx): ", "npm")
						return package_manager
					end,
					runtimeArgs = function()
						return vim.split(
							vim.fn.input("Enter command arguments (e.g. run start:debug): ", "run start:debug"),
							" "
						)
					end,
					-- runtimeArgs = {
					-- 	"run",
					-- 	"start:debug",
					-- 	"--",
					-- 	"--inspect-brk",
					-- },
					autoAttachChildProcesses = true,
					restart = true,
					sourceMaps = true,
					stopOnEntry = false,
					console = "integratedTerminal",
					cwd = "${workspaceFolder}",
					autoReload = {
						enable = true,
					},
					env = {
						NODE_TLS_REJECT_UNAUTHORIZED = "0",
					},
				})
			end
			-- RUST DEBUGGING
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
					args = {
						"--port",
						"${port}",
					},
				},
			}

			dap.configurations.rust = {
				{
					name = "Launch file",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					preRunCommands = {
						"command script import " .. vim.fn.stdpath("config") .. "/utils/rust_prettifier_for_lldb.py",
					},
				},
			}
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
			dapui.setup({
				layouts = {
					{
						position = "right",
						size = 45,
						elements = {
							{ id = "scopes", size = 0.40 },
							{ id = "watches", size = 0.30 },
							{ id = "stacks", size = 0.15 },
							{ id = "breakpoints", size = 0.15 },
						},
					},
					{
						position = "bottom",
						size = 12,
						elements = {
							"repl",
							"console",
						},
					},
				},
			})
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			-- dap.listeners.before.event_exited.dapui_config = function()
			-- 	dapui.close()
			-- end
			-- KEYMAPS

			vim.keymap.set("n", "<leader>du", function()
				dapui.toggle()
			end, { desc = "Toggle Dap UI" })
			vim.keymap.set("n", "<Leader>de", function()
				dapui.eval()
			end, { desc = "Evaluate expression" })
		end,
	},
}
