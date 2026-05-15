return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		vim.g.db_ui_use_nerd_fonts = 1

		-- 1. Define the persistent data path
		local db_path = vim.fn.stdpath("data") .. require("plenary.path").path.sep .. "db_ui"

		-- 2. Ensure the directory actually exists so dadbod doesn't fail silently
		vim.fn.mkdir(db_path, "p")

		-- 3. Assign it
		vim.g.db_ui_save_location = db_path
	end,
}
