return {
	{
		"dlyongemallo/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
		keys = {
			{ "<leader>dO", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
		},
		config = function()
			require("diffview").setup({
				use_icons = true,
				keymaps = {
					view = {
						{ "n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
						{ "n", "<leader>dt", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle Diffview Files" } },
					},
					file_panel = {
						{ "n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
						{ "n", "<leader>dt", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle Diffview Files" } },
					},
					file_history_panel = {
						{ "n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
						{ "n", "<leader>dt", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle Diffview Files" } },
					},
				},
			})
		end,
	}
}
