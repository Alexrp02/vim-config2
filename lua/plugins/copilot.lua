return {
	{
		"github/copilot.vim",
		config = function()
			vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
				expr = true,
				replace_keycodes = false,
			})
			vim.g.copilot_no_tab_map = true
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		opts = {},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			{
				"MeanderingProgrammer/render-markdown.nvim",
				ft = { "markdown", "codecompanion" },
			},
			{
				"HakonHarnes/img-clip.nvim",
				opts = {
					filetypes = {
						codecompanion = {
							prompt_for_file_name = false,
							template = "[Image]($FILE_PATH)",
							use_absolute_path = true,
						},
					},
				},
			},
		},
		keys = {
			{
				"<C-a>",
				"<cmd>CodeCompanionActions<CR>",
				desc = "Open the action palette",
				mode = { "n", "v" },
			},
			{
				"<Leader>a",
				"<cmd>CodeCompanionChat Toggle<CR>",
				desc = "Toggle a chat buffer",
				mode = { "n", "v" },
			},
			{
				"<LocalLeader>a",
				"<cmd>CodeCompanionChat Add<CR>",
				desc = "Add code to a chat buffer",
				mode = { "v" },
			},
		},
		init = function ()
			vim.cmd([[cab cc CodeCompanion]])
		end
	},
}
