local M = {}

local state = {
	files = {},
	current_index = 1,
	diff_base = nil,
	git_root = nil,
	-- Windows and buffers
	file_list_buf = nil,
	file_list_win = nil,
	old_buf = nil,
	old_win = nil,
	new_buf = nil,
	new_win = nil,
	-- Line mapping: display_line (1-indexed) -> original_line (0-indexed)
	-- Only non-padding lines have entries
	old_line_map = {},
	new_line_map = {},
	total_display_lines = 0,
	previous_tab = nil,
	ns = vim.api.nvim_create_namespace("difftastic-review"),
	ns_files = vim.api.nvim_create_namespace("difftastic-files"),
}

-- Highlight groups -----------------------------------------------------------

local function setup_highlights()
	-- Old side (removed/changed) — red tones
	vim.api.nvim_set_hl(0, "DifftasticOldLine", { bg = "#3a1a1a", default = true })
	vim.api.nvim_set_hl(0, "DifftasticOldText", { bg = "#5c2626", fg = "#ff9999", bold = true, default = true })

	-- New side (added/changed) — green tones
	vim.api.nvim_set_hl(0, "DifftasticNewLine", { bg = "#1a2e1a", default = true })
	vim.api.nvim_set_hl(0, "DifftasticNewText", { bg = "#265c26", fg = "#99ff99", bold = true, default = true })

	-- Padding lines (no counterpart on this side)
	vim.api.nvim_set_hl(0, "DifftasticPadding", { bg = "#2a2a3a", default = true })
end

-- Utilities ------------------------------------------------------------------

local function get_git_root()
	local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return root
end

local function get_old_content(diff_base, file)
	local ref = diff_base and (diff_base .. ":" .. file) or (":" .. file)
	local lines = vim.fn.systemlist({ "git", "show", ref })
	if vim.v.shell_error ~= 0 then
		return {}
	end
	return lines
end

local function get_new_content(git_root, file)
	local path = git_root .. "/" .. file
	if vim.fn.filereadable(path) == 0 then
		return {}
	end
	return vim.fn.readfile(path)
end

local function run_difft(old_path, new_path)
	local output = vim.fn.system(string.format(
		"DFT_UNSTABLE=yes difft --display json %s %s 2>/dev/null",
		vim.fn.shellescape(old_path),
		vim.fn.shellescape(new_path)
	))
	if output == "" then
		return nil
	end
	local ok, data = pcall(vim.json.decode, output)
	if not ok then
		return nil
	end
	if vim.islist(data) then
		return data[1]
	end
	return data
end

--- Build aligned display lines from difft aligned_lines data.
--- Returns padded old/new line arrays (same length) and line maps.
local function build_display(old_lines, new_lines, difft_data)
	local aligned = difft_data and difft_data.aligned_lines
	local old_disp, new_disp = {}, {}
	local old_map, new_map = {}, {} -- display_idx -> orig 0-based line
	local old_rev, new_rev = {}, {} -- orig 0-based line -> display_idx

	if aligned and #aligned > 0 then
		for _, pair in ipairs(aligned) do
			local ol, nl = pair[1], pair[2]
			if ol == vim.NIL then
				ol = nil
			end
			if nl == vim.NIL then
				nl = nil
			end

			local idx = #old_disp + 1

			if ol then
				old_disp[idx] = old_lines[ol + 1] or ""
				old_map[idx] = ol
				old_rev[ol] = idx
			else
				old_disp[idx] = ""
			end

			if nl then
				new_disp[idx] = new_lines[nl + 1] or ""
				new_map[idx] = nl
				new_rev[nl] = idx
			else
				new_disp[idx] = ""
			end
		end
	else
		-- Fallback: 1:1 alignment
		local n = math.max(#old_lines, #new_lines)
		for i = 1, n do
			old_disp[i] = old_lines[i] or ""
			new_disp[i] = new_lines[i] or ""
			if old_lines[i] then
				old_map[i] = i - 1
				old_rev[i - 1] = i
			end
			if new_lines[i] then
				new_map[i] = i - 1
				new_rev[i - 1] = i
			end
		end
	end

	return old_disp, new_disp, old_map, new_map, old_rev, new_rev
end

--- Parse chunks into per-line highlight info keyed by original line number.
local function parse_highlights(chunks)
	local lhs_hl, rhs_hl = {}, {}

	if not chunks then
		return lhs_hl, rhs_hl
	end

	for _, chunk in ipairs(chunks) do
		for _, entry in ipairs(chunk) do
			local has_lhs = entry.lhs ~= nil and entry.lhs ~= vim.NIL
			local has_rhs = entry.rhs ~= nil and entry.rhs ~= vim.NIL

			if has_lhs then
				lhs_hl[entry.lhs.line_number] = {
					type = has_rhs and "changed" or "removed",
					changes = entry.lhs.changes or {},
				}
			end
			if has_rhs then
				rhs_hl[entry.rhs.line_number] = {
					type = has_lhs and "changed" or "added",
					changes = entry.rhs.changes or {},
				}
			end
		end
	end

	return lhs_hl, rhs_hl
end

--- Apply line and character highlights to a buffer.
--- @param is_old boolean  true = old/left side (red), false = new/right side (green)
local function apply_highlights(buf, ns, display_count, line_map, hl_data, is_old)
	local line_hl_group = is_old and "DifftasticOldLine" or "DifftasticNewLine"
	local text_hl_group = is_old and "DifftasticOldText" or "DifftasticNewText"

	for i = 1, display_count do
		local orig = line_map[i]
		if orig == nil then
			-- Padding line
			vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
				line_hl_group = "DifftasticPadding",
				priority = 150,
			})
		else
			local info = hl_data[orig]
			if info then
				-- Line-level background (subtle red or green)
				vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
					line_hl_group = line_hl_group,
					priority = 150,
				})

				-- Character-level highlights (bold red or green on specific tokens)
				local line_text = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1] or ""
				local line_len = #line_text
				for _, change in ipairs(info.changes) do
					local sc = math.min(change.start or 0, line_len)
					local ec = math.min(change["end"] or sc, line_len)
					if ec > sc then
						vim.api.nvim_buf_set_extmark(buf, ns, i - 1, sc, {
							end_col = ec,
							hl_group = text_hl_group,
							priority = 200,
						})
					end
				end
			end
		end
	end
end

--- Create a read-only scratch buffer with the given lines.
--- Filetype must be set AFTER the buffer is placed in a window so treesitter attaches.
local function create_content_buf(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buflisted = false
	vim.bo[buf].swapfile = false
	return buf
end

--- Find the nearest new-file line for a given display line.
local function nearest_new_line(display_line)
	if state.new_line_map[display_line] then
		return state.new_line_map[display_line]
	end
	for offset = 1, state.total_display_lines do
		local above = display_line - offset
		local below = display_line + offset
		if above >= 1 and state.new_line_map[above] then
			return state.new_line_map[above]
		end
		if below <= state.total_display_lines and state.new_line_map[below] then
			return state.new_line_map[below]
		end
	end
	return 0
end

-- Core -----------------------------------------------------------------------

function M.open(opts)
	opts = opts or {}
	local args = opts.args or ""

	-- Close existing review if open
	if state.file_list_buf and vim.api.nvim_buf_is_valid(state.file_list_buf) then
		M.close()
	end

	state.diff_base = args ~= "" and args or nil
	state.git_root = get_git_root()
	if not state.git_root then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
		return
	end

	local cmd = state.diff_base and ("git diff --name-only " .. state.diff_base) or "git diff --name-only"
	local result = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("git diff failed", vim.log.levels.ERROR)
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

	setup_highlights()
	M.create_layout()
	M.render_file_list()
	M.show_diff()
end

function M.create_layout()
	vim.cmd("tabnew")
	-- rightmost window → new file
	state.new_win = vim.api.nvim_get_current_win()
	local init_buf = vim.api.nvim_get_current_buf()
	vim.bo[init_buf].bufhidden = "wipe"

	-- center window → old file
	vim.cmd("leftabove vnew")
	state.old_win = vim.api.nvim_get_current_win()
	vim.bo[vim.api.nvim_get_current_buf()].bufhidden = "wipe"

	-- leftmost window → file list
	vim.cmd("topleft vnew")
	state.file_list_win = vim.api.nvim_get_current_win()
	state.file_list_buf = vim.api.nvim_get_current_buf()

	-- File list settings
	vim.api.nvim_win_set_width(state.file_list_win, 40)
	vim.bo[state.file_list_buf].buftype = "nofile"
	vim.bo[state.file_list_buf].bufhidden = "wipe"
	vim.bo[state.file_list_buf].swapfile = false
	vim.bo[state.file_list_buf].buflisted = false
	vim.bo[state.file_list_buf].filetype = "difftastic-files"

	vim.wo[state.file_list_win].number = false
	vim.wo[state.file_list_win].relativenumber = false
	vim.wo[state.file_list_win].signcolumn = "no"
	vim.wo[state.file_list_win].foldcolumn = "0"
	vim.wo[state.file_list_win].winfixwidth = true
	vim.wo[state.file_list_win].wrap = false
	vim.wo[state.file_list_win].cursorline = true

	-- Old/new window settings
	for _, win in ipairs({ state.old_win, state.new_win }) do
		vim.wo[win].number = true
		vim.wo[win].relativenumber = false
		vim.wo[win].signcolumn = "no"
		vim.wo[win].scrollbind = true
		vim.wo[win].cursorbind = true
		vim.wo[win].wrap = false
		vim.wo[win].foldmethod = "manual"
		vim.wo[win].foldenable = false
	end

	-- Winbar title
	local title = state.diff_base
			and string.format(" Difftastic: %s (%d files)", state.diff_base, #state.files)
		or string.format(" Difftastic: unstaged (%d files)", #state.files)
	vim.wo[state.file_list_win].winbar = title

	M.set_keymaps(state.file_list_buf)

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

	vim.api.nvim_buf_clear_namespace(buf, state.ns_files, 0, -1)
	if state.current_index >= 1 and state.current_index <= #state.files then
		vim.api.nvim_buf_add_highlight(buf, state.ns_files, "Visual", state.current_index - 1, 0, -1)
	end

	if vim.api.nvim_win_is_valid(state.file_list_win) then
		vim.api.nvim_win_set_cursor(state.file_list_win, { state.current_index, 0 })
	end
end

function M.show_diff()
	local file = state.files[state.current_index]
	if not file then
		return
	end

	local prev_win = vim.api.nvim_get_current_win()

	-- Fetch old and new content
	local old_lines = get_old_content(state.diff_base, file)
	local new_lines = get_new_content(state.git_root, file)

	-- Write old content to a temp file (preserve extension for language detection)
	local ext = vim.fn.fnamemodify(file, ":e")
	local old_tmp = vim.fn.tempname() .. (ext ~= "" and ("." .. ext) or "")
	vim.fn.writefile(old_lines, old_tmp)

	-- Resolve new file path (may need temp if deleted)
	local new_path = state.git_root .. "/" .. file
	local new_tmp = nil
	if vim.fn.filereadable(new_path) == 0 then
		new_tmp = vim.fn.tempname() .. (ext ~= "" and ("." .. ext) or "")
		vim.fn.writefile(new_lines, new_tmp)
		new_path = new_tmp
	end

	-- Run difftastic JSON diff
	local difft_data = run_difft(old_tmp, new_path)

	-- Build aligned display content
	local old_disp, new_disp, old_map, new_map = build_display(old_lines, new_lines, difft_data)
	state.old_line_map = old_map
	state.new_line_map = new_map
	state.total_display_lines = #old_disp

	-- Disable scrollbind before swapping buffers to prevent stale offset jumps
	vim.wo[state.old_win].scrollbind = false
	vim.wo[state.new_win].scrollbind = false

	-- Create read-only buffers (filetype set after window placement)
	local old_buf = create_content_buf(old_disp)
	local new_buf = create_content_buf(new_disp)

	-- Place buffers in windows
	if vim.api.nvim_win_is_valid(state.old_win) then
		vim.api.nvim_win_set_buf(state.old_win, old_buf)
	end
	if vim.api.nvim_win_is_valid(state.new_win) then
		vim.api.nvim_win_set_buf(state.new_win, new_buf)
	end
	state.old_buf = old_buf
	state.new_buf = new_buf

	-- Set filetype AFTER buffers are visible so treesitter can attach
	-- buf parameter is required for vim.filetype.match to work on scratch buffers
	local ft = vim.filetype.match({ buf = new_buf, filename = file })
	if ft then
		vim.bo[old_buf].filetype = ft
		vim.bo[new_buf].filetype = ft
		-- Explicitly start treesitter (FileType autocmd may not fire for scratch bufs)
		pcall(vim.treesitter.start, old_buf)
		pcall(vim.treesitter.start, new_buf)
	end

	-- Apply difftastic AST highlights (priority > treesitter's 100)
	if difft_data then
		local lhs_hl, rhs_hl = parse_highlights(difft_data.chunks)
		apply_highlights(old_buf, state.ns, #old_disp, old_map, lhs_hl, true)
		apply_highlights(new_buf, state.ns, #new_disp, new_map, rhs_hl, false)
	end

	-- Winbar labels
	local old_label = state.diff_base and (state.diff_base .. ":" .. file) or ("index:" .. file)
	vim.wo[state.old_win].winbar = " " .. old_label
	vim.wo[state.new_win].winbar = " " .. file

	-- Set keymaps on new buffers
	M.set_keymaps(old_buf)
	M.set_keymaps(new_buf)

	-- Reset both windows to top, then re-enable and sync scrollbind
	for _, win in ipairs({ state.old_win, state.new_win }) do
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_set_cursor(win, { 1, 0 })
		end
	end
	vim.wo[state.old_win].scrollbind = true
	vim.wo[state.new_win].scrollbind = true
	vim.cmd("syncbind")

	-- Cleanup temp files
	vim.fn.delete(old_tmp)
	if new_tmp then
		vim.fn.delete(new_tmp)
	end

	-- Restore focus
	if vim.api.nvim_win_is_valid(prev_win) then
		vim.api.nvim_set_current_win(prev_win)
	end
end

-- Navigation -----------------------------------------------------------------

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

-- Actions --------------------------------------------------------------------

function M.stage_file()
	local file = state.files[state.current_index]
	if not file then
		return
	end
	local out = vim.fn.system("git add " .. vim.fn.shellescape(file))
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to stage: " .. out, vim.log.levels.ERROR)
	else
		vim.notify("Staged: " .. file, vim.log.levels.INFO)
	end
end

function M.goto_file()
	local file = state.files[state.current_index]
	if not file then
		return
	end

	local target_line = 1
	local target_col = 0
	local cur_win = vim.api.nvim_get_current_win()

	if cur_win == state.new_win or cur_win == state.old_win then
		local cursor = vim.api.nvim_win_get_cursor(cur_win)
		local display_line = cursor[1]
		target_col = cursor[2]
		-- Both sides share the same display alignment, so new_line_map works
		target_line = nearest_new_line(display_line) + 1 -- 0-indexed → 1-indexed
	end

	-- Navigate to previous tab and open the file at the matched position
	if state.previous_tab and state.previous_tab <= vim.fn.tabpagenr("$") then
		vim.cmd(state.previous_tab .. "tabnext")
	else
		vim.cmd("tabprevious")
	end
	vim.cmd("edit " .. vim.fn.fnameescape(state.git_root .. "/" .. file))
	pcall(vim.api.nvim_win_set_cursor, 0, { target_line, target_col })
end

function M.close()
	if state.file_list_buf and vim.api.nvim_buf_is_valid(state.file_list_buf) then
		vim.cmd("tabclose")
	end
end

function M.cleanup_state()
	state.files = {}
	state.current_index = 1
	state.diff_base = nil
	state.git_root = nil
	state.file_list_buf = nil
	state.file_list_win = nil
	state.old_buf = nil
	state.old_win = nil
	state.new_buf = nil
	state.new_win = nil
	state.old_line_map = {}
	state.new_line_map = {}
	state.total_display_lines = 0
	state.previous_tab = nil
end

-- Keymaps --------------------------------------------------------------------

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
	map("gf", M.goto_file, "Go to file at cursor position")
	map("q", M.close, "Close review")

	if buf == state.file_list_buf then
		map("<CR>", M.select_file, "Select file")
	end
end

-- Setup ----------------------------------------------------------------------

function M.setup()
	vim.api.nvim_create_user_command("DifftasticReview", function(opts)
		M.open(opts)
	end, {
		nargs = "?",
		desc = "Open difftastic-based code review",
		complete = function()
			local branches = vim.fn.systemlist("git branch --format='%(refname:short)'")
			local remotes = vim.fn.systemlist("git branch -r --format='%(refname:short)'")
			return vim.list_extend(branches, remotes)
		end,
	})
end

return M
