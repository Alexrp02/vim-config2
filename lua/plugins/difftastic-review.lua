return {
	{
		name = "difftastic-review",
		dir = vim.fn.stdpath("config"),
		cmd = { "DifftasticReview" },
		keys = {
			{ "<leader>dr", "<cmd>DifftasticReview<cr>", desc = "Difftastic Review (unstaged)" },
		},
		config = function()
			require("difftastic-review").setup()
		end,
	},
}
