return {
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
		keys = {
			{ "<leader>dO", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
			{ "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
			{ "<leader>dt", "<cmd>DiffviewToggleFiles<cr>", desc = "Toggle Diffview Files" },
		},
		config = function()
			require("diffview").setup({
				use_icons = true,
			})
		end,
	}
}
