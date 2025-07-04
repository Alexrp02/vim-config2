return {
	{
		"mbbill/undotree",
		keys = {
			{ "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
		},
		config = function()
			vim.g.undotree_WindowLayout = 2
			vim.g.undotree_SplitWidth = 35
			vim.g.undotree_SetFocusWhenToggle = 1
			vim.g.undotree_HelpLine = 0
			vim.g.undotree_DiffCommand = "diff"
		end,
	}
}
