return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	-- 1. Add the file operations bridge for Oil.nvim
	{
		"antosha417/nvim-lsp-file-operations",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-neo-tree/neo-tree.nvim" },
		config = true,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = { "antosha417/nvim-lsp-file-operations" },
		config = function()
			-- 1. Master Capabilities Merge (Blink + File Operations)
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			local ok_blink, blink = pcall(require, "blink.cmp")
			if ok_blink then
				capabilities = blink.get_lsp_capabilities(capabilities)
			end

			local ok_file_ops, file_ops = pcall(require, "lsp-file-operations")
			if ok_file_ops then
				capabilities = vim.tbl_deep_extend("force", capabilities, file_ops.default_capabilities())
			end

			-- Apply merged capabilities globally to ALL servers using the new API
			vim.lsp.config("*", {
				capabilities = capabilities,
			})

			-- Global Keymaps
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", function()
				vim.cmd("Trouble lsp_definitions")
			end, {})
			vim.keymap.set("n", "gD", function()
				vim.cmd("Trouble lsp_declarations")
			end, {})
			vim.keymap.set("n", "gi", function()
				vim.cmd("Trouble lsp_implementations")
			end, {})
			vim.keymap.set("n", "gt", function()
				vim.cmd("Trouble lsp_type_definitions")
			end, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "gr", function()
				vim.cmd("Trouble lsp_references")
			end, {})

			-- ==========================================
			-- ASTRO CONFIGURATION
			-- ==========================================
			vim.lsp.config("astro", {
				settings = {
					astro = { updateImportsOnFileMove = { enabled = true } },
				},
			})
			vim.lsp.enable("astro")

			-- ==========================================
			-- RUST CONFIGURATION (rust-analyzer)
			-- ==========================================
			local ra_cmd = { "rust-analyzer" } -- Default to your system RA

			-- Check if we are in an ESP project by reading the local toolchain file
			local toolchain_file = io.open(vim.fn.getcwd() .. "/rust-toolchain.toml", "r")
			if toolchain_file then
				local content = toolchain_file:read("*a")
				toolchain_file:close()
				if content:match('channel%s*=%s*"esp"') then
					-- Force Neovim to use the 1.90.0 rust-analyzer to bypass the lockfile crash
					ra_cmd = { "rustup", "run", "1.90.0", "rust-analyzer" }
				end
			end

			vim.lsp.config("rust_analyzer", {
				cmd = ra_cmd,
				settings = {
					["rust-analyzer"] = {
						diagnostics = { enable = true },
					},
				},
			})
			vim.lsp.enable("rust_analyzer")

			-- ==========================================
			-- TYPESCRIPT CONFIGURATION (vtsls)
			-- ==========================================
			vim.lsp.config("vtsls", {
				settings = {
					vtsls = { autoUseWorkspaceTsdk = true },
					typescript = {
						updateImportsOnFileMove = { enabled = "always" },
						inlayHints = {
							parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = true },
							parameterTypes = { enabled = true },
							variableTypes = { enabled = false, suppressWhenTypeMatchesName = false },
							enumMemberValues = { enabled = true },
						},
					},
					javascript = {
						updateImportsOnFileMove = { enabled = "always" },
						inlayHints = {
							parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = true },
							parameterTypes = { enabled = true },
							variableTypes = { enabled = false, suppressWhenTypeMatchesName = false },
							enumMemberValues = { enabled = true },
						},
					},
				},
			})
			vim.lsp.enable("vtsls")

			-- ==========================================
			-- ARDUINO CONFIGURATION
			-- ==========================================
			vim.lsp.config("arduino_language_server", {
				cmd = {
					"arduino-language-server",
					"-cli",
					"arduino-cli",
					"-cli-config",
					os.getenv("HOME") .. "/.arduinoIDE/arduino-cli.yaml",
					"-fqbn",
					"arduino:avr:mega",
				},
			})
			vim.lsp.enable("arduino_language_server")
		end,
	},
	{
		"jay-babu/mason-null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "williamboman/mason.nvim", "nvimtools/none-ls.nvim" },
		config = function()
			require("mason-null-ls").setup({
				ensure_installed = { "stylua", "black", "isort", "prettier" },
			})
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = { { "mason-org/mason.nvim", opts = {} }, "neovim/nvim-lspconfig" },
		config = function()
			require("mason-lspconfig").setup({
				automatic_enable = {
					exclude = {
						"ts_ls",
						"arduino_language_server",
					},
				},
			})
		end,
	},
}
