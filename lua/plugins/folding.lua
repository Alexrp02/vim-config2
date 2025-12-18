return {
	{
		"kevinhwang91/nvim-ufo",
		event = "BufReadPost",
		dependencies = { "kevinhwang91/promise-async" },
		keys = {
			{
				"zR",
				function()
					require("ufo").openAllFolds()
				end,
				desc = "Open all folds",
			},
			{
				"zM",
				function()
					require("ufo").closeAllFolds()
				end,
				desc = "Close all folds",
			},
		},
		config = function()
			vim.o.foldcolumn = "1" -- '0' is not bad
			vim.o.fillchars = "eob: ,fold: ,foldopen:,foldsep:|,foldclose:"
			vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true

			require("ufo").setup({
				provider_selector = function(bufnr, filetype, buftype)
					return { "treesitter", "indent" }
				end,
			})
		end,
	},
}
