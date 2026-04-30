return {
	{
		"zbirenbaum/copilot.lua",
		event = "InsertEnter",
		cmd = "Copilot",
		config = function()
			require("copilot").setup({
				panel = {
					enabled = false,
				},
				suggestion = {
					enabled = true,
					auto_trigger = true,
					hide_during_completion = false,
					keymap = {
						accept = "<C-l>",
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<C-]>",
						toggle_auto_trigger = "<M-\\>",
					},
				},
				filetypes = {
					markdown = true,
				},
			})
		end,
	},
}
