vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set({ "n", "i" }, "<C-s>", function()
	if vim.api.nvim_get_mode().mode == 'i' then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'n', true)
	end
	vim.cmd('w') -- Save the file
	--	vim.lsp.buf.format({ async = true }) -- Format the code
end, { silent = true })

vim.keymap.set("n", "<leader>qq", ":wqa<CR>")
