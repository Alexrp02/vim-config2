vim.api.nvim_create_user_command("JestFile", function(opts)
	local file = vim.fn.expand("%:p")
	if vim.fn.filereadable(file) == 1 then
		local cmd = "split | terminal npx jest " .. vim.fn.fnameescape(file) .. " --testPathIgnorePatterns=a^"
		if opts.args and opts.args ~= "" then
			cmd = cmd .. " -t " .. vim.fn.shellescape(opts.args)
		end
		vim.cmd(cmd)
	else
		print("Current buffer is not a file.")
	end
end, { desc = "Run Jest on current buffer file with optional test pattern", nargs = "?" })
