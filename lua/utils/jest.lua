local M = {}

--- Gets the test name(s) at cursor position using treesitter
--- Builds full path for nested describe/it blocks (e.g., "Parent > Child > test name")
---@return string|nil
function M.get_test_at_cursor()
	local ts_utils_ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
	if not ts_utils_ok then
		vim.notify("nvim-treesitter is required for test detection", vim.log.levels.ERROR)
		return nil
	end

	local node = ts_utils.get_node_at_cursor()
	if not node then
		return nil
	end

	local test_functions = {
		["it"] = true,
		["test"] = true,
		["describe"] = true,
	}

	local path_parts = {}

	--- Extracts the test name string from a call_expression node
	---@param call_node TSNode
	---@return string|nil
	local function extract_test_name(call_node)
		local func_node = call_node:field("function")[1]
		if not func_node then
			return nil
		end

		local func_name = vim.treesitter.get_node_text(func_node, 0)
		if not test_functions[func_name] then
			return nil
		end

		local args_node = call_node:field("arguments")[1]
		if not args_node then
			return nil
		end

		-- First argument should be the test name (string or template_string)
		for child in args_node:iter_children() do
			local child_type = child:type()
			if child_type == "string" then
				local text = vim.treesitter.get_node_text(child, 0)
				-- Remove quotes
				return text:gsub("^['\"`]", ""):gsub("['\"`]$", "")
			elseif child_type == "template_string" then
				local text = vim.treesitter.get_node_text(child, 0)
				-- Remove backticks
				return text:gsub("^`", ""):gsub("`$", "")
			end
		end

		return nil
	end

	-- Traverse up the tree to find all enclosing test/describe blocks
	local current = node
	while current do
		if current:type() == "call_expression" then
			local name = extract_test_name(current)
			if name then
				table.insert(path_parts, 1, name)
			end
		end
		current = current:parent()
	end

	if #path_parts == 0 then
		return nil
	end

	-- Join with " " to create the full test path pattern for Jest -t
	return table.concat(path_parts, " ")
end

return M
