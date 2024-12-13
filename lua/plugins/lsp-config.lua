return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"pyright",
					"rust_analyzer",
					"intelephense",
					"docker_compose_language_service",
					"dockerls",
					"bashls",
					"ts_ls",
					"html",
					"cssls",
					"ruby_lsp",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lspconfig = require("lspconfig")
			local util = require("lspconfig/util")

			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})

			lspconfig.pyright.setup({
				capabilities = capabilities,
				filetypes = { "python" },
			})

			lspconfig.rust_analyzer.setup({
				capabilities = capabilities,
				filetypes = { "rust" },
				root_dir = util.root_pattern("Cargo.toml"),
				settings = {
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
						},
					},
				},
			})

			lspconfig.intelephense.setup({
				capabilities = capabilities,
				filetypes = { "php" },
			})
			lspconfig.jsonls.setup({
				capabilities = capabilities,
				filetypes = { "json" },
			})

			lspconfig.docker_compose_language_service.setup({
				capabilities = capabilities,
				filetypes = { "docker_compose.yaml.yml" },
			})

			lspconfig.bashls.setup({
				capabilities = capabilities,
				filetypes = { "sh" },
			})

			lspconfig.ts_ls.setup({
				capabilities = capabilities,
				filetypes = { "javascript" },
			})

			lspconfig.html.setup({
				capabilities = capabilities,
				filetypes = { "html" },
			})

			lspconfig.cssls.setup({
				capabilities = capabilities,
				filetypes = { "css" },
			})

			lspconfig.ruby_lsp.setup({
				capabilities = capabilities,
				filetypes = { "ruby" },
			})

			lspconfig.dockerls.setup({
				capabilities = capabilities,
			})
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "gr", vim.lsp.buf.references, {})
		end,
	},
	{
		"jay-babu/mason-null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"nvimtools/none-ls.nvim",
		},
		config = function()
			require("mason-null-ls").setup({
				ensure_installed = { "stylua", "black", "isort" },
			})
		end,
	},
	{
		"smjonas/inc-rename.nvim",
		config = function()
			require("inc_rename").setup()
			vim.keymap.set("n", "<leader>cr", function()
				return ":IncRename " .. vim.fn.expand("<cword>")
			end, { expr = true, desc = "Rename variable" })
		end,
	},
}
