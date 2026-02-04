return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
		config = function()
			-- vim.cmd.colorscheme "catppuccin-mocha"
		end,
	},
	{
		"navarasu/onedark.nvim",
		priority = 1000,
		config = function()
			-- require("onedark").setup({
			-- 	style = "darker",
			-- })
			-- require("onedark").load()
		end,
	},
	{
		"ribru17/bamboo.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("bamboo").setup({})
			require("bamboo").load()
		end,
	},
}
