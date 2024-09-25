vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.o.number = true
vim.o.relativenumber = true

-- Diagnostics
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", { desc = "Document Diagnostics" })

-- Use tabs but no so long to indent
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false

-- windows
vim.keymap.set("n", "<leader>w", "<c-w>", { desc = "Windows", remap = true })
vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

vim.keymap.set({ "n", "i" }, "<C-s>", function()
	if vim.api.nvim_get_mode().mode == "i" then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "n", true)
	end
	vim.cmd("w") -- Save the file
	--	vim.lsp.buf.format({ async = true }) -- Format the code
end, { silent = true })

-- vim.keymap.set("n", "<leader>qq", ":wqall!<CR>")
vim.keymap.set("n", "<leader>qq", function()
	vim.cmd("Neotree close")
	vim.cmd("q")
end)

-- Navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Recognize Dockerfile filetypes
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile", "VimEnter"}, {
    pattern = {"[Dd]ockerfile", "[Dd]ockerfile*", "*.[Dd]ockerfile", "*.dock"},
    command = "setfiletype Dockerfile"
})

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile", "VimEnter"}, {
    pattern = "[Dd]ockerfile.vim",
    command = "setfiletype vim"
})
