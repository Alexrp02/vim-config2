return {
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		-- setting the keybinding for LazyGit with 'keys' is recommended in
		-- order to load the plugin when the command is run for the first time
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
			local gs = package.loaded.gitsigns
			vim.keymap.set("n", "<leader>gb", function () gs.blame_line({full = true}) end, {desc = "Git blame line"})
			vim.keymap.set("n", "<leader>hp", function () gs.preview_hunk() end, {desc = "Git preview hunk"})
			vim.keymap.set("n", "<leader>hi", function () gs.preview_hunk_inline() end, {desc = "Git preview hunk inline"})
			vim.keymap.set("n", "<leader>hs", function () gs.stage_hunk() end, {desc = "Git stage hunk"})
			vim.keymap.set("n", "<leader>hr", function () gs.reset_hunk() end, {desc = "Git reset hunk"})
		end,
	},
	{
		"tpope/vim-fugitive"
	}
}
