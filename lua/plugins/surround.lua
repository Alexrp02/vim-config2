return {
	"kylechui/nvim-surround",
	version = "*", -- Use for stability; omit to use `main` branch for the latest features
	event = "VeryLazy",
	config = function()
		vim.keymap.set("v", "<CR>", "<Plug>(nvim-surround-visual)", { desc = "Surround with operator" })
	end,
}
