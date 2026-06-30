local M = {}

local ns = vim.api.nvim_create_namespace("jj-conflicts")

local state = {
	buf = nil,
	source_path = nil,
	by_marker = {},
}

-- Highlight groups -----------------------------------------------------------

local function setup_highlights()
	-- Base / "removed" side — red tones
	vim.api.nvim_set_hl(0, "JjConflictBase", { bg = "#3a1a1a", default = true })
	vim.api.nvim_set_hl(0, "JjConflictBaseText", { bg = "#5c2626", fg = "#ff9999", bold = true, default = true })

	-- Side #1 (changes in the diff hunk) — green tones
	vim.api.nvim_set_hl(0, "JjConflictSide", { bg = "#1a2e1a", default = true })
	vim.api.nvim_set_hl(0, "JjConflictSideText", { bg = "#265c26", fg = "#99ff99", bold = true, default = true })

	-- Side #2 (snapshot contents) — blue tones
	vim.api.nvim_set_hl(0, "JjConflictSnap", { bg = "#16242e", default = true })

	-- Marker / section header lines — dimmed
	vim.api.nvim_set_hl(0, "JjConflictMarker", { fg = "#7aa2f7", italic = true, default = true })

	-- Sign column glyphs
	vim.api.nvim_set_hl(0, "JjConflictSignAdd", { fg = "#99ff99", default = true })
	vim.api.nvim_set_hl(0, "JjConflictSignDel", { fg = "#ff9999", default = true })
	vim.api.nvim_set_hl(0, "JjConflictSignSnap", { fg = "#7dcfff", default = true })
	vim.api.nvim_set_hl(0, "JjConflictSignMarker", { fg = "#7aa2f7", default = true })
end

-- Parsing --------------------------------------------------------------------

local function marker_kind(line)
	local p = line:sub(1, 7)
	if p == "<<<<<<<" then
		return "start"
	elseif p == ">>>>>>>" then
		return "end"
	elseif p == "%%%%%%%" then
		return "diff"
	elseif p == "+++++++" then
		return "side"
	elseif p == "-------" then
		return "base"
	end
	return nil
end

--- Byte range of the differing middle between two strings (common prefix/suffix trimmed).
--- Returns a_start, a_end, b_start, b_end (0-based, end-exclusive).
local function inline_change(a, b)
	local la, lb = #a, #b
	local p = 0
	while p < la and p < lb and a:byte(p + 1) == b:byte(p + 1) do
		p = p + 1
	end
	local s = 0
	while s < (la - p) and s < (lb - p) and a:byte(la - s) == b:byte(lb - s) do
		s = s + 1
	end
	return p, la - s, p, lb - s
end

--- Pair each base line with the following side #1 line and record the changed
--- byte range on both, so only the exact edit is char-highlighted.
local function compute_inline(glines, decor, srow)
	local bi = 1
	while bi <= #decor do
		if decor[bi].role == "base" then
			local d0 = bi
			while bi <= #decor and decor[bi].role == "base" do
				bi = bi + 1
			end
			local d1 = bi - 1
			local a0 = bi
			while bi <= #decor and decor[bi].role == "side1" do
				bi = bi + 1
			end
			local a1 = bi - 1
			for k = 0, math.min(d1 - d0, a1 - a0) do
				local di, ai = d0 + k, a0 + k
				local atext = glines[srow + di] or ""
				local btext = glines[srow + ai] or ""
				local as, ae, bs, be = inline_change(atext, btext)
				if ae > as then
					decor[di].inline = { as, ae }
				end
				if be > bs then
					decor[ai].inline = { bs, be }
				end
			end
		else
			bi = bi + 1
		end
	end
end

--- Parse a conflicted file into clean render lines + per-conflict metadata.
--- Each original line maps 1:1 to a render line: marker/header lines are kept
--- verbatim (so `/<<<<` still works), content lines have their diff prefix
--- stripped (so a normal yank is clean). Per conflict we also reconstruct the
--- full clean contents of every side and base for the accept commands, keyed by
--- the (unique) start-marker line so decorations can be re-derived after edits.
local function parse(orig)
	local lines, conflicts = {}, {}
	local i, n = 1, #orig
	while i <= n do
		if marker_kind(orig[i]) == "start" then
			local srow = #lines -- 0-based render row of the start marker
			local start_text = orig[i]
			table.insert(lines, orig[i])
			local decor = { { role = "start" } }
			local sides, bases = {}, {}
			local cur, acc, dbase, dside = nil, nil, nil, nil

			local function flush()
				if cur == "diff" then
					table.insert(sides, dside or {})
					table.insert(bases, dbase or {})
				elseif cur == "side" then
					table.insert(sides, acc or {})
				elseif cur == "base" then
					table.insert(bases, acc or {})
				end
				cur, acc, dbase, dside = nil, nil, nil, nil
			end

			i = i + 1
			while i <= n and marker_kind(orig[i]) ~= "end" do
				local k = marker_kind(orig[i])
				if k == "diff" or k == "side" or k == "base" then
					flush()
					cur = k
					if k == "diff" then
						dbase, dside = {}, {}
					else
						acc = {}
					end
					table.insert(lines, orig[i])
					table.insert(decor, { role = k .. "_hdr" })
				else
					local raw = orig[i]
					if cur == "diff" then
						local c = raw:sub(1, 1)
						if c == "-" then
							local t = raw:sub(2)
							table.insert(dbase, t)
							table.insert(lines, t)
							table.insert(decor, { role = "base" })
						elseif c == "+" then
							local t = raw:sub(2)
							table.insert(dside, t)
							table.insert(lines, t)
							table.insert(decor, { role = "side1" })
						else
							local t = (c == " ") and raw:sub(2) or raw
							table.insert(dbase, t)
							table.insert(dside, t)
							table.insert(lines, t)
							table.insert(decor, { role = "context" })
						end
					elseif cur == "side" then
						table.insert(acc, raw)
						table.insert(lines, raw)
						table.insert(decor, { role = "side2" })
					elseif cur == "base" then
						table.insert(acc, raw)
						table.insert(lines, raw)
						table.insert(decor, { role = "base_snap" })
					else
						table.insert(lines, raw)
						table.insert(decor, { role = "context" })
					end
				end
				i = i + 1
			end
			flush()

			if i <= n then
				table.insert(lines, orig[i]) -- end marker
				table.insert(decor, { role = "end" })
				i = i + 1
			end

			compute_inline(lines, decor, srow)
			-- Snapshot the conflict's render lines (1:1 with decor) so decorations
			-- can be re-aligned to the live text after edits (see redecorate).
			local clines = {}
			for r = srow + 1, srow + #decor do
				clines[#clines + 1] = lines[r]
			end
			table.insert(conflicts, {
				start_text = start_text,
				decor = decor,
				clines = clines,
				sides = sides,
				bases = bases,
			})
		else
			table.insert(lines, orig[i])
			i = i + 1
		end
	end
	return lines, conflicts
end

-- Decoration -----------------------------------------------------------------

local SIGN = {
	start = "▼",
	["end"] = "▲",
	diff_hdr = "~",
	side_hdr = "+",
	base_hdr = "-",
}

local function decorate_line(buf, row, text, d)
	local role = d.role
	if SIGN[role] then
		vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
			end_row = row,
			end_col = #text,
			hl_group = "JjConflictMarker",
			sign_text = SIGN[role],
			sign_hl_group = "JjConflictSignMarker",
			priority = 200,
		})
		return
	end

	local line_hl, sign_text, sign_hl, text_hl
	if role == "base" or role == "base_snap" then
		line_hl, sign_text, sign_hl, text_hl = "JjConflictBase", "-", "JjConflictSignDel", "JjConflictBaseText"
	elseif role == "side1" then
		line_hl, sign_text, sign_hl, text_hl = "JjConflictSide", "+", "JjConflictSignAdd", "JjConflictSideText"
	elseif role == "side2" then
		line_hl, sign_text, sign_hl = "JjConflictSnap", "+", "JjConflictSignSnap"
	else
		return -- context / plain
	end

	vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
		line_hl_group = line_hl,
		sign_text = sign_text,
		sign_hl_group = sign_hl,
		priority = 150,
	})

	if d.inline and text_hl then
		pcall(vim.api.nvim_buf_set_extmark, buf, ns, row, d.inline[1], {
			end_col = d.inline[2],
			hl_group = text_hl,
			priority = 200,
		})
	end
end

--- Live conflict blocks (start..end marker pairs) in the current buffer text.
local function scan_blocks(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local blocks, cur = {}, nil
	for idx, l in ipairs(lines) do
		local k = marker_kind(l)
		if k == "start" then
			cur = { start_row = idx - 1, start_text = l }
		elseif k == "end" and cur then
			cur.end_row = idx - 1
			table.insert(blocks, cur)
			cur = nil
		end
	end
	return blocks
end

--- Map each live line index to the parsed-conflict line index it still matches,
--- via xdiff. Lines unchanged on both sides line up 1:1 (the LCS); edited or
--- inserted live lines map to nothing, deleted parsed lines simply drop out. So
--- a parsed line's decoration only ever lands on the live line that still is it.
local function align(parsed, live)
	local hunks = vim.diff(table.concat(parsed, "\n"), table.concat(live, "\n"), { result_type = "indices" })
	local changed_a, changed_b = {}, {}
	for _, h in ipairs(hunks) do
		local sa, ca, sb, cb = h[1], h[2], h[3], h[4]
		for x = sa, sa + ca - 1 do
			changed_a[x] = true
		end
		for x = sb, sb + cb - 1 do
			changed_b[x] = true
		end
	end
	local ua, ub = {}, {}
	for x = 1, #parsed do
		if not changed_a[x] then
			ua[#ua + 1] = x
		end
	end
	for x = 1, #live do
		if not changed_b[x] then
			ub[#ub + 1] = x
		end
	end
	local map = {}
	for k = 1, math.min(#ua, #ub) do
		map[ub[k]] = ua[k]
	end
	return map
end

--- Re-derive all decorations from the current buffer text. Idempotent and safe
--- to call on every change, so undo/redo/manual edits stay consistent. Each
--- live block is matched to its parsed conflict by start-marker line, then its
--- current lines are aligned to the parsed render lines so only the lines the
--- user actually changed lose their decoration — untouched hunks, even within a
--- whole-file conflict, keep full fidelity, and nothing spills past the block.
local function redecorate()
	local buf = state.buf
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, blk in ipairs(scan_blocks(buf)) do
		local c = state.by_marker[blk.start_text]
		if c then
			local blines = vim.api.nvim_buf_get_lines(buf, blk.start_row, blk.end_row + 1, false)
			local map = align(c.clines, blines)
			for bi = 1, #blines do
				local ai = map[bi]
				if ai then
					decorate_line(buf, blk.start_row + bi - 1, blines[bi], c.decor[ai])
				end
			end
		end
	end
end

-- Coalesce bursts of changes (e.g. multi-line edits) into a single redraw on
-- the next tick. nvim_buf_attach fires inside the change, where buffer edits
-- are restricted, so the actual decoration is deferred via vim.schedule.
local redraw_scheduled = false
local function schedule_redecorate()
	if redraw_scheduled then
		return
	end
	redraw_scheduled = true
	vim.schedule(function()
		redraw_scheduled = false
		redecorate()
	end)
end

-- Actions --------------------------------------------------------------------

--- Replace the conflict under the cursor with the clean contents of a side.
--- @param which "side1"|"side2"|"base"
function M.accept(which)
	local buf = state.buf
	if not buf or vim.api.nvim_get_current_buf() ~= buf then
		return
	end
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	for _, blk in ipairs(scan_blocks(buf)) do
		if row >= blk.start_row and row <= blk.end_row then
			local c = state.by_marker[blk.start_text]
			if not c then
				vim.notify("jj-conflicts: unrecognized conflict block", vim.log.levels.WARN)
				return
			end
			local content
			if which == "base" then
				content = c.bases[1]
			elseif which == "side1" then
				content = c.sides[1]
			else
				content = c.sides[2]
			end
			if not content then
				vim.notify("jj-conflicts: no " .. which .. " available for this conflict", vim.log.levels.WARN)
				return
			end
			vim.api.nvim_buf_set_lines(buf, blk.start_row, blk.end_row + 1, false, content)
			redecorate()
			return
		end
	end
	vim.notify("jj-conflicts: cursor is not inside a conflict", vim.log.levels.INFO)
end

local function goto_marker(forward)
	vim.fn.search("^<<<<<<<", forward and "W" or "bW")
end

function M.write()
	local buf = state.buf
	if not buf or not state.source_path then
		return
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local has_marker = false
	for _, l in ipairs(lines) do
		if marker_kind(l) ~= nil then
			has_marker = true
			break
		end
	end

	local ok, err = pcall(vim.fn.writefile, lines, state.source_path)
	if not ok then
		vim.notify("jj-conflicts: failed to write " .. state.source_path .. ": " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	vim.bo[buf].modified = false

	-- Reload the real file if it is open in another buffer.
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if b ~= buf and vim.api.nvim_buf_get_name(b) == state.source_path then
			vim.api.nvim_buf_call(b, function()
				vim.cmd("checktime")
			end)
		end
	end

	if has_marker then
		vim.notify("jj-conflicts: wrote " .. state.source_path .. " (conflict markers still present)", vim.log.levels.WARN)
	else
		vim.notify("jj-conflicts: wrote " .. state.source_path, vim.log.levels.INFO)
	end
end

function M.close()
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		vim.cmd("tabclose")
	end
end

-- Keymaps --------------------------------------------------------------------

local function set_keymaps(buf)
	local map = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, nowait = true, silent = true })
	end

	map("n", "]x", function()
		goto_marker(true)
	end, "jj: next conflict")
	map("n", "[x", function()
		goto_marker(false)
	end, "jj: previous conflict")
	map("n", "<localleader>c1", function()
		M.accept("side1")
	end, "jj: accept side #1")
	map("n", "<localleader>c2", function()
		M.accept("side2")
	end, "jj: accept side #2")
	map("n", "<localleader>cb", function()
		M.accept("base")
	end, "jj: accept base")
	map("n", "<leader>cw", M.write, "jj: write to file")
	map("n", "q", M.close, "jj: close view")
end

-- Core -----------------------------------------------------------------------

--- Drop the buffer load from the undo history so `u` reverts the user's own
--- edits rather than wiping the loaded conflict view. (see :h clear-undo)
local function clear_undo_history(buf)
	vim.api.nvim_buf_call(buf, function()
		local old = vim.bo[buf].undolevels
		vim.bo[buf].undolevels = -1
		vim.cmd([[execute "normal! a \<BS>\<Esc>"]])
		vim.bo[buf].undolevels = old
	end)
end

function M.open(opts)
	opts = opts or {}
	local args = vim.trim(opts.args or "")

	local path
	if args ~= "" then
		path = vim.fn.fnamemodify(args, ":p")
	else
		path = vim.api.nvim_buf_get_name(0)
	end

	if path == "" or vim.fn.filereadable(path) == 0 then
		vim.notify("jj-conflicts: no readable file (open the conflicted file first, or pass a path)", vim.log.levels.ERROR)
		return
	end

	local orig = vim.fn.readfile(path)
	local has_conflict = false
	for _, l in ipairs(orig) do
		if marker_kind(l) == "start" then
			has_conflict = true
			break
		end
	end
	if not has_conflict then
		vim.notify("jj-conflicts: no conflict markers found in " .. path, vim.log.levels.WARN)
		return
	end

	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		M.close()
	end

	setup_highlights()

	local lines, conflicts = parse(orig)
	state.by_marker = {}
	for _, c in ipairs(conflicts) do
		state.by_marker[c.start_text] = c
	end

	vim.cmd("tabnew")
	local buf = vim.api.nvim_get_current_buf()
	state.buf = buf
	state.source_path = path

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].buflisted = false
	vim.api.nvim_buf_set_name(buf, "jj-conflict://" .. path)

	-- Syntax-highlight the code without attaching LSP to the scratch buffer.
	local ft = vim.filetype.match({ filename = path, buf = buf })
	if ft then
		local lang = vim.treesitter.language.get_lang(ft)
		if lang then
			pcall(vim.treesitter.start, buf, lang)
		end
	end

	local win = vim.api.nvim_get_current_win()
	vim.wo[win].signcolumn = "yes:1"
	vim.wo[win].winbar = " jj conflicts: " .. vim.fn.fnamemodify(path, ":.")

	clear_undo_history(buf)
	redecorate()
	set_keymaps(buf)
	vim.bo[buf].modified = false

	-- Re-derive decorations on every change (undo, redo, manual edits, API).
	vim.api.nvim_buf_attach(buf, false, {
		on_lines = function()
			if not vim.api.nvim_buf_is_valid(buf) then
				return true
			end
			schedule_redecorate()
		end,
	})
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = M.write,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			state.buf = nil
			state.source_path = nil
			state.by_marker = {}
		end,
	})
end

function M.setup()
	vim.api.nvim_create_user_command("JjConflict", function(opts)
		M.open(opts)
	end, {
		nargs = "?",
		complete = "file",
		desc = "Open a jj conflict resolver view for the current (or given) file",
	})
end

return M
