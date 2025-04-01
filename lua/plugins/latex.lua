return {
	{
		"lervag/vimtex",
		ft = { "tex", "latex" }, -- Load only for tex/latex files
		init = function()
			-- VimTeX configuration goes here, e.g.
			vim.g.vimtex_view_method = "zathura"
			-- Set Spanish language
			vim.g.vimtex_grammar_textidote = {
				lang = "es,en",
			}

			vim.cmd([[set spell]])
			vim.cmd([[set spelllang=es,en]])
			vim.g.vimtex_quickfix_autoclose_after_keystrokes = 2
		end,
	},
}
