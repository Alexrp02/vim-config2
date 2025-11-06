return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			-- local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- lspconfig.docker_compose_language_service.setup({
			-- 	capabilities = capabilities,
			-- 	filetypes = { "docker_compose.yaml.yml" },
			-- })

			-- lspconfig.html.setup({
			-- 	capabilities = capabilities,
			-- 	filetypes = { "astro" },
			-- })
			vim.lsp.config("astro", {
				settings = {
					astro = {
						updateImportsOnFileMove = {
							enabled = true,
						},
					},
				},
			})
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", function ()
				vim.cmd("Trouble lsp_definitions")
			end, {})
			vim.keymap.set("n", "gD", function ()
				vim.cmd("Trouble lsp_declarations")
			end, {})
			vim.keymap.set("n", "gi", function ()
				vim.cmd("Trouble lsp_implementations")
			end, {})
			vim.keymap.set("n", "gt", function ()
				vim.cmd("Trouble lsp_type_definitions")
			end, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "gr", function()
				vim.cmd("Trouble lsp_references")
			end, {})

			vim.lsp.config("rust_analyzer", {
				settings = {
					["rust-analyzer"] = {
						diagnostics = {
							enable = true,
						},
					},
				},
			})
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
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "neovim/nvim-lspconfig",
    },
		config = function()
			require("mason-lspconfig").setup({
				automatic_enable = {
					exclude = {
						"ts_ls"
					}
				}
			})
		end
}
}
