return {
	{
		"madmaxieee/unclash.nvim",
		lazy = false,
		-- default options
		opts = {
			action_buttons = {
				enabled = true,
			},
			annotations = {
				enabled = true,
			},
		},
		keys = {
			{
				"]x",
				function()
					require("unclash").next_conflict()
				end,
				desc = "Next Conflict",
			},
			{
				"[x",
				function()
					require("unclash").prev_conflict()
				end,
				desc = "Prev Conflict",
			},
			{
				"<leader>co",
				function()
					require("unclash").open_merge_editor()
				end,
				desc = "Open Merge Editor",
			},
			{
				"<localleader>cc",
				function()
					require("unclash").accept_current()
				end,
				desc = "Accept Current",
			},
			{
				"<localleader>ci",
				function()
					require("unclash").accept_incoming()
				end,
				desc = "Accept Incoming",
			},
			{
				"<localleader>cb",
				function()
					require("unclash").accept_both()
				end,
				desc = "Accept Both",
			},
			{
				"<leader>fx",
				function()
					require("unclash.snacks").pick()
				end,
				desc = "Pick Conflicts",
			},
		},
	},
	{
		"rafikdraoui/jj-diffconflicts",
	},
}
