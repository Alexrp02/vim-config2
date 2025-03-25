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
					"html",
					"cssls",
					"astro",
				},
			})
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			require("mason-lspconfig").setup_handlers({
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
					if server_name == "ltex" then
						require("lspconfig").ltex.setup({
							capabilities = capabilities,
							settings = {
								ltex = {
									language = "es",
								},
							},
						})
					end
					if server_name ~= "ts_ls" then
						require("lspconfig")[server_name].setup({
							capabilities = capabilities,
						})
					end
				end,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			-- local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lspconfig = require("lspconfig")

			-- lspconfig.docker_compose_language_service.setup({
			-- 	capabilities = capabilities,
			-- 	filetypes = { "docker_compose.yaml.yml" },
			-- })

			-- lspconfig.html.setup({
			-- 	capabilities = capabilities,
			-- 	filetypes = { "astro" },
			-- })
			lspconfig.astro.setup({
				settings = {
					astro = {
						updateImportsOnFileMove = {
							enabled = true,
						},
					},
				},
			})
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "gr", function()
				vim.cmd("Trouble lsp_references")
			end, {})
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
				ensure_installed = { "stylua", "black", "isort", "prettier" },
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
	-- {
	-- 	"WieeRd/auto-lsp.nvim",
	-- 	dependencies = { "neovim/nvim-lspconfig" },
	-- 	event = "VeryLazy",
	-- 	opts = {},
	-- },
}
