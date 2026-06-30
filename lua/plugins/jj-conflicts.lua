return {
	{
		name = "jj-conflicts",
		dir = vim.fn.stdpath("config"),
		cmd = { "JjConflict" },
		keys = {
			{ "<leader>cj", "<cmd>JjConflict<cr>", desc = "jj: resolve conflict (current file)" },
		},
		config = function()
			require("jj-conflicts").setup()
		end,
	},
}
