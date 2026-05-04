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
			"daliusd/blink-cmp-fuzzy-path",
		},
		init = function()
			local function set_blink_highlights()
				vim.api.nvim_set_hl(0, "BlinkCmpMenu", { link = "Pmenu" })
				vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { link = "FloatBorder" })
				vim.api.nvim_set_hl(0, "BlinkCmpDoc", { link = "Pmenu" })
				vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { link = "FloatBorder" })
			end

			set_blink_highlights()
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = set_blink_highlights,
			})
		end,
		opts = {
			keymap = {
				preset = "enter",
			},
			snippets = {
				preset = "luasnip",
			},
			completion = {
				menu = {
					border = "single",
					winblend = 4,
					scrollbar = false,
				},
				documentation = {
					auto_show = true,
					window = {
						border = "single",
						winblend = 4,
					},
				},
			},
			enabled = function()
				local ft = vim.bo.filetype
				return ft ~= "dap-repl" and ft ~= "dapui_watches" and ft ~= "dapui_hover"
			end,
			sources = {
				default = { "fuzzy-path", "lsp", "path", "buffer", "snippets" },
				providers = {
					["fuzzy-path"] = {
						name = "Fuzzy Path",
						module = "blink-cmp-fuzzy-path",
						score_offset = 0,
						opts = {
							filetypes = { "markdown", "json" }, -- optional
						},
					},
				},
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
