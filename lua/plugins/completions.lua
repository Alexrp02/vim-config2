return {
	{
		"L3MON4D3/LuaSnip",
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	{
		"saghen/blink.cmp",
		version = "1.*", -- pin stable major to avoid v2 breaking changes
		dependencies = {
			"L3MON4D3/LuaSnip",
		},
		opts = {
			keymap = {
				preset = "enter",
			},
			snippets = {
				preset = "luasnip",
			},
			completion = {
				documentation = {
					auto_show = true,
				},
			},
			enabled = function()
				local ft = vim.bo.filetype
				return ft ~= "dap-repl" and ft ~= "dapui_watches" and ft ~= "dapui_hover"
			end,
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = {
				implementation = "prefer_rust_with_warning",
			},
		},
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"rcarriga/cmp-dap",
		},
		config = function()
			local cmp = require("cmp")

			cmp.setup({
				enabled = function()
					return require("cmp_dap").is_dap_buffer()
				end,
			})

			cmp.setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = {
					{ name = "dap" },
				},
			})
		end,
	},
}
