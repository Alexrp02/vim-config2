local M = {}

local state = {
	files = {},
	current_index = 1,
	diff_base = nil,
	file_list_buf = nil,
	file_list_win = nil,
	diff_buf = nil,
	diff_win = nil,
	diff_job = nil,
	previous_tab = nil,
	ns_id = vim.api.nvim_create_namespace("difftastic-review"),
}

function M.open(opts)
	opts = opts or {}
	local args = opts.args or ""

	-- Close existing review if open
	if state.file_list_buf and vim.api.nvim_buf_is_valid(state.file_list_buf) then
		M.close()
	end

	state.diff_base = args ~= "" and args or nil

	-- Get changed files
	local cmd
	if state.diff_base then
		cmd = "git diff --name-only " .. state.diff_base
	else
		cmd = "git diff --name-only"
	end

	local result = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("git diff failed: " .. table.concat(result, "\n"), vim.log.levels.ERROR)
		return
	end

	state.files = vim.tbl_filter(function(f)
		return f ~= ""
	end, result)

	if #state.files == 0 then
		vim.notify("No changes found", vim.log.levels.INFO)
		return
	end

	state.current_index = 1
	state.previous_tab = vim.fn.tabpagenr()

	M.create_layout()
	M.render_file_list()
	M.show_diff()
end

function M.create_layout()
	-- Open a new tab for the review
	vim.cmd("tabnew")
	state.diff_win = vim.api.nvim_get_current_win()

	-- Mark the initial buffer so it gets cleaned up
	local initial_buf = vim.api.nvim_get_current_buf()
	vim.bo[initial_buf].bufhidden = "wipe"

	-- Create file list split on the left
	vim.cmd("topleft vnew")
	state.file_list_win = vim.api.nvim_get_current_win()
	state.file_list_buf = vim.api.nvim_get_current_buf()

	vim.api.nvim_win_set_width(state.file_list_win, 40)

	-- File list buffer settings
	vim.bo[state.file_list_buf].buftype = "nofile"
	vim.bo[state.file_list_buf].bufhidden = "wipe"
	vim.bo[state.file_list_buf].swapfile = false
	vim.bo[state.file_list_buf].filetype = "difftastic-files"
	vim.bo[state.file_list_buf].buflisted = false

	-- File list window settings
	vim.wo[state.file_list_win].number = false
	vim.wo[state.file_list_win].relativenumber = false
	vim.wo[state.file_list_win].signcolumn = "no"
	vim.wo[state.file_list_win].foldcolumn = "0"
	vim.wo[state.file_list_win].winfixwidth = true
	vim.wo[state.file_list_win].wrap = false
	vim.wo[state.file_list_win].cursorline = true

	-- Diff window settings
	vim.wo[state.diff_win].number = false
	vim.wo[state.diff_win].relativenumber = false
	vim.wo[state.diff_win].signcolumn = "no"

	-- Winbar title
	local title = state.diff_base
			and string.format(" Difftastic: %s (%d files)", state.diff_base, #state.files)
		or string.format(" Difftastic: unstaged (%d files)", #state.files)
	vim.wo[state.file_list_win].winbar = title

	-- Set keymaps on file list buffer
	M.set_keymaps(state.file_list_buf)

	-- Cleanup when the file list buffer is wiped (tab closed, etc.)
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = state.file_list_buf,
		once = true,
		callback = function()
			M.cleanup_state()
		end,
	})
end

function M.render_file_list()
	local buf = state.file_list_buf
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local lines = {}
	for i, file in ipairs(state.files) do
		local prefix = i == state.current_index and " > " or "   "
		table.insert(lines, prefix .. file)
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	-- Highlight current file line
	vim.api.nvim_buf_clear_namespace(buf, state.ns_id, 0, -1)
	if state.current_index >= 1 and state.current_index <= #state.files then
		vim.api.nvim_buf_add_highlight(buf, state.ns_id, "Visual", state.current_index - 1, 0, -1)
	end

	-- Sync cursor in file list window
	if vim.api.nvim_win_is_valid(state.file_list_win) then
		vim.api.nvim_win_set_cursor(state.file_list_win, { state.current_index, 0 })
	end
end

function M.show_diff()
	local file = state.files[state.current_index]
	if not file then
		return
	end
	if not vim.api.nvim_win_is_valid(state.diff_win) then
		return
	end

	-- Remember which window had focus so we can restore it
	local prev_win = vim.api.nvim_get_current_win()

	-- Kill previous job if still running
	if state.diff_job and vim.fn.jobwait({ state.diff_job }, 0)[1] == -1 then
		vim.fn.jobstop(state.diff_job)
		state.diff_job = nil
	end

	-- Switch to diff window and create a fresh buffer
	vim.api.nvim_set_current_win(state.diff_win)
	vim.cmd("enew")
	state.diff_buf = vim.api.nvim_get_current_buf()
	vim.bo[state.diff_buf].buflisted = false
	vim.bo[state.diff_buf].bufhidden = "wipe"

	-- Build diff command sized to the window
	local width = vim.api.nvim_win_get_width(state.diff_win)
	local diff_cmd
	if state.diff_base then
		diff_cmd = string.format(
			"GIT_EXTERNAL_DIFF='difft --color always --width %d' git diff %s -- %s",
			width,
			vim.fn.shellescape(state.diff_base),
			vim.fn.shellescape(file)
		)
	else
		diff_cmd = string.format(
			"GIT_EXTERNAL_DIFF='difft --color always --width %d' git diff -- %s",
			width,
			vim.fn.shellescape(file)
		)
	end

	state.diff_job = vim.fn.termopen(diff_cmd, {
		on_exit = function()
			state.diff_job = nil
			vim.schedule(function()
				-- Scroll to top once the diff finishes rendering
				if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
					vim.api.nvim_win_set_cursor(state.diff_win, { 1, 0 })
				end
			end)
		end,
	})

	-- Set keymaps on the new diff buffer
	M.set_keymaps(state.diff_buf)

	-- Show current file name in winbar
	vim.wo[state.diff_win].winbar = " " .. file

	-- Restore focus to wherever the user was
	if vim.api.nvim_win_is_valid(prev_win) then
		vim.api.nvim_set_current_win(prev_win)
	end
end

-- Navigation ----------------------------------------------------------------

function M.next_file()
	if state.current_index < #state.files then
		state.current_index = state.current_index + 1
		M.render_file_list()
		M.show_diff()
	end
end

function M.prev_file()
	if state.current_index > 1 then
		state.current_index = state.current_index - 1
		M.render_file_list()
		M.show_diff()
	end
end

function M.select_file()
	if not vim.api.nvim_win_is_valid(state.file_list_win) then
		return
	end
	local line = vim.api.nvim_win_get_cursor(state.file_list_win)[1]
	if line >= 1 and line <= #state.files then
		state.current_index = line
		M.render_file_list()
		M.show_diff()
	end
end

-- Actions -------------------------------------------------------------------

function M.stage_file()
	local file = state.files[state.current_index]
	if not file then
		return
	end
	local result = vim.fn.system("git add " .. vim.fn.shellescape(file))
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to stage: " .. result, vim.log.levels.ERROR)
	else
		vim.notify("Staged: " .. file, vim.log.levels.INFO)
	end
end

function M.goto_file()
	local file = state.files[state.current_index]
	if not file then
		return
	end
	-- Jump to the tab the user was on before opening the review
	if state.previous_tab and state.previous_tab <= vim.fn.tabpagenr("$") then
		vim.cmd(state.previous_tab .. "tabnext")
	else
		vim.cmd("tabprevious")
	end
	vim.cmd("edit " .. vim.fn.fnameescape(file))
end

function M.close()
	-- Stop any running diff job
	if state.diff_job and vim.fn.jobwait({ state.diff_job }, 0)[1] == -1 then
		vim.fn.jobstop(state.diff_job)
	end
	-- tabclose triggers BufWipeout on the file list buf which calls cleanup_state
	vim.cmd("tabclose")
end

function M.cleanup_state()
	state.files = {}
	state.current_index = 1
	state.diff_base = nil
	state.file_list_buf = nil
	state.file_list_win = nil
	state.diff_buf = nil
	state.diff_win = nil
	state.diff_job = nil
	state.previous_tab = nil
end

-- Keymaps -------------------------------------------------------------------

function M.set_keymaps(buf)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc, nowait = true })
	end

	map("<Tab>", M.next_file, "Next file")
	map("<S-Tab>", M.prev_file, "Previous file")
	map("<leader>hS", M.stage_file, "Stage file")
	map("gf", M.goto_file, "Go to file")
	map("q", M.close, "Close review")

	-- Enter selects file only in the file list panel
	if buf == state.file_list_buf then
		map("<CR>", M.select_file, "Select file")
	end
end

-- Setup ---------------------------------------------------------------------

function M.setup()
	vim.api.nvim_create_user_command("DifftasticReview", function(opts)
		M.open(opts)
	end, {
		nargs = "?",
		desc = "Open difftastic review for changed files",
		complete = function()
			local branches = vim.fn.systemlist("git branch --format='%(refname:short)'")
			local remotes = vim.fn.systemlist("git branch -r --format='%(refname:short)'")
			return vim.list_extend(branches, remotes)
		end,
	})
end

return M
