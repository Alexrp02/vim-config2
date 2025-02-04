return {
	{ "echasnovski/mini.nvim", version = false,
		config = function ()
			require("mini.ai").setup()
			require("mini.move").setup()
			require("mini.pairs").setup()
		end
	},
	{ "nvim-tree/nvim-web-devicons" },
}
