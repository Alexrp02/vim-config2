return {
	{
		"olimorris/persisted.nvim",
		lazy = false,
		opts = {
			autoload = true,
			autosave = true,
			use_git_branch = true,
		},
		config = function(_, opts)
			local persisted = require("persisted")
			persisted.branch = function()
				local branch = vim.fn.systemlist("git branch --show-current")[1]
				return vim.v.shell_error == 0 and branch or nil
			end
			persisted.setup(opts)
		end,

		keys = {
			{ "<leader>qs", "<cmd>SessionLoad<cr>", desc = "Restore Session" },
			{
				"<leader>ql",
				"<cmd>SessionLoadFast<cr>",
				desc = "Restore Last Session",
			},
			{
				"<leader>qd",
				"<cmd>SessionStop<cr>",
				desc = "Don't Save Current Session",
			},
		},
	},
}
