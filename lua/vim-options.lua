require("configs")

vim.g.mapleader = " "
vim.g.maplocalleader = ","


vim.opt.wrap = true
vim.opt.linebreak = true


vim.o.number = true
vim.o.relativenumber = true

-- Diagnostics
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", { desc = "Document Diagnostics" })

-- Use tabs but no so long to indent
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
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

-- Indentation jumping
-- Helper to get indent level of a line
local function get_indent(lnum)
  return vim.fn.indent(lnum)
end

-- Jump to previous line with less indent
vim.keymap.set("n", "[i", function()
  local cur = vim.fn.line(".")
  local cur_indent = get_indent(cur)
  for lnum = cur - 1, 1, -1 do
    if get_indent(lnum) < cur_indent then
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      return
    end
  end
end, { desc = "Jump to previous line with less indent" })

-- Jump to next line with less indent
vim.keymap.set("n", "]i", function()
  local cur = vim.fn.line(".")
  local max = vim.fn.line("$")
  local cur_indent = get_indent(cur)
  for lnum = cur + 1, max do
    if get_indent(lnum) < cur_indent then
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      return
    end
  end
end, { desc = "Jump to next line with less indent" })

-- Recognize Dockerfile filetypes
vim.filetype.add({
	pattern = {
		["[Dd]ockerfile.*"] = "dockerfile",
		["*.[Dd]ockerfile"] = "dockerfile",
		["*.dock"] = "dockerfile",
		["[Dd]ockerfile.vim"] = "vim",
		["*[Dd]ocker-compose*"] = "docker-compose.yaml.yml",
	},
})

-- LSP signature help
vim.keymap.set('i', '<C-h>', 
	function()
		vim.lsp.buf.signature_help()
	end, 
	{ desc = "LSP Signature Help" })

-- Fold all the same levels of folds under the cursor
vim.api.nvim_create_user_command("FoldSameLevel", function()
  local target_level = vim.fn.foldlevel('.')
  if target_level <= 0 then
    print("No fold under cursor")
    return
  end

  local last_line = vim.fn.line('$')
  for l = 1, last_line do
    local level = vim.fn.foldlevel(l)
    local closed = vim.fn.foldclosed(l)
    if level == target_level and closed == -1 then
      vim.cmd(l .. "foldclose")
    end
  end

  print("Folded all folds at level " .. target_level)
end, {})

vim.api.nvim_create_user_command("FoldOuter", function()
  local last_line = vim.fn.line('$')
  for l = 1, last_line do
    local level = vim.fn.foldlevel(l)
    local closed = vim.fn.foldclosed(l)
    if level == 1 and closed == -1 then
      vim.cmd(l .. "foldclose")
    end
  end
end, {})

vim.keymap.set("n", "zo", "<Cmd>FoldOuter<CR>", { desc = "Fold Outer Levels" })
vim.keymap.set("n", "zs", "<Cmd>FoldSameLevel<CR>", { desc = "Fold Same Level" })
