return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				html = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			-- When no configured formatter is installed for the buffer (e.g. prettier
			-- isn't installed via Mason), fall back to the language server's formatter
			-- instead of running both and fighting over the buffer.
			default_format_opts = {
				lsp_format = "fallback",
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			conform.format({ async = true, lsp_format = "fallback" })
		end, { desc = "(C)ode (Format) the buffer" })
	end,
}
