return {
	{
	'nvim-telescope/telescope.nvim',
	tag = '0.1.8',
	dependencies = { 'nvim-lua/plenary.nvim' },
	config = function ()
		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader><leader>", builtin.find_files, {desc="Search files with telescope"})
		vim.keymap.set("n", "<leader>sg", builtin.live_grep, {desc="Search with grep on folder"})
	end
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function ()
			require("telescope").setup ({
			  extensions = {
			    ["ui-select"] = {
			      require("telescope.themes").get_dropdown {
			      }
			    }
			  }
			})
			require("telescope").load_extension("ui-select")
		end
	}
}
