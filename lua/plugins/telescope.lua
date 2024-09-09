return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-live-grep-args.nvim",
				-- This will not install any breaking changes.
				-- For major updates, this must be adjusted manually.
				version = "^1.0.0",
			},
		},
		config = function()
			local builtin = require("telescope.builtin")
			local open_with_trouble = function(...)
				return require("trouble.sources.telescope").open(...)
			end

			local telescope = require("telescope")

			telescope.setup({
				defaults = {
					mappings = {
						i = { ["<c-t>"] = open_with_trouble },
						n = { ["<c-t>"] = open_with_trouble },
					},
				},
			})
			vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "Search files with telescope" })
			vim.keymap.set("n", "<leader>sgg", builtin.live_grep, { desc = "Search with grep on folder" })
			vim.keymap.set(
				"n",
				"<leader>sb",
				"<cmd>Telescope current_buffer_fuzzy_find<cr>",
				{ desc = "Grep search current buffer" }
			)
			vim.keymap.set(
				"n",
				"<leader>sga",
				":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
				{ desc = "Live grep with arguments" }
			)
			telescope.load_extension("live_grep_args")
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
	{
		"folke/trouble.nvim",
		opts = {
			max_items = 2000,
		}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
}
