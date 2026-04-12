return {
	{
		name = "difftastic-review",
		dir = vim.fn.stdpath("config"),
		cmd = { "DifftasticReview", "DifftasticReviewCommit" },
		keys = {
			{ "<leader>dr", "<cmd>DifftasticReview<cr>", desc = "Difftastic Review (unstaged)" },
			{ "<leader>dR", "<cmd>DifftasticReviewCommit HEAD<cr>", desc = "Difftastic Review (HEAD commit)" },
		},
		config = function()
			require("difftastic-review").setup()
		end,
	},
}
