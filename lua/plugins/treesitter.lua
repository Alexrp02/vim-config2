return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			-- Explicitly install parsers.
			-- Prioritized Rust and TypeScript for your workflow, plus essential Neovim languages.
			local parsers = {
				"rust",
				"typescript",
				"tsx",
				"lua",
				"vim",
				"vimdoc",
				"markdown",
				"markdown_inline",
			}
			require("nvim-treesitter").install(parsers)

			-- Native Treesitter attachment replaces the old `highlight = { enable = true }`
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		-- This plugin handles itself well and doesn't rely on the dead configs module.
		config = function()
			require("treesitter-context").setup()
			vim.keymap.set("n", "gp", function()
				require("treesitter-context").go_to_context()
			end, { desc = "Jump to Treesitter context" })
			vim.keymap.set("n", "<leader>tc", function()
				require("treesitter-context").toggle()
			end, { desc = "Toggle Treesitter context" })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main", -- YOU MUST KEEP THIS HERE
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			-- Setup textobjects directly using its own module
			require("nvim-treesitter-textobjects").setup({
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
					},
				},
				move = {
					enable = true,
					set_jumps = true,
					goto_next_start = {
						["]m"] = "@function.outer",
					},
					goto_next_end = {
						["]M"] = "@function.outer",
					},
				},
			})
		end,
	},
}
