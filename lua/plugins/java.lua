return {
	{
		"mfussenegger/nvim-jdtls",
		dependencies = {
			"mfussenegger/nvim-dap"
		},
		ft = { "java" }, -- load only for Java files
		config = function()
			-- Only run when a Java buffer is opened
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function()
					local ok, jdtls = pcall(require, "jdtls")
					if not ok then
						vim.notify("nvim-jdtls not found", vim.log.levels.ERROR)
						return
					end

					local root_dir = vim.fs.root(0, { "gradlew", ".git", "mvnw" })
					if not root_dir then
						vim.notify("No project root found for JDTLS", vim.log.levels.ERROR)
						return
					end

					-- Per-project workspace directory
					local workspace_dir = vim.fn.stdpath("data") .. "/jdtls/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

					-- Mason path
					local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
					local launcher_path = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
					if launcher_path == "" then
						vim.notify(
							"Could not find org.eclipse.equinox.launcher_*.jar under " .. jdtls_path,
							vim.log.levels.ERROR
						)
						return
					end

					local cmd = {
						"java",
						"-Declipse.application=org.eclipse.jdt.ls.core.id1",
						"-Dosgi.bundles.defaultStartLevel=4",
						"-Declipse.product=org.eclipse.jdt.ls.core.product",
						"-Dlog.protocol=true",
						"-Dlog.level=ALL",
						"-Xms1g",
						"--add-modules=ALL-SYSTEM",
						"--add-opens",
						"java.base/java.util=ALL-UNNAMED",
						"--add-opens",
						"java.base/java.lang=ALL-UNNAMED",
						"-jar",
						launcher_path,
						"-configuration",
						jdtls_path .. "/config_linux",
						"-data",
						workspace_dir,
					}

					local java_debug_path = vim.fn.stdpath("data")
						.. "/mason/packages/java-debug-adapter/extension/server/"
					local java_debug_bundle = vim.fn.glob(java_debug_path .. "com.microsoft.java.debug.plugin-*.jar")

					local config = {
						cmd = cmd,
						root_dir = root_dir,
						init_options = {
							bundles = {
								java_debug_bundle,
							},
						},
					}

					-- Start or attach to JDTLS for this buffer
					jdtls.start_or_attach(config)
				end,
			})
		end,
	},
}
