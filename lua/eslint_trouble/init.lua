local M = {}

function M.run_eslint()
  local cmd = { "yarn", "--silent", "lint", "-f", "json" }

  vim.system(cmd, { text = true }, function(obj)
    if obj.code ~= 0 and obj.code ~= 1 then
      vim.schedule(function()
        vim.notify('[eslint-trouble] Linting failed to run', vim.log.levels.ERROR)
      end)
      return
    end

    local ok, decoded = pcall(vim.json.decode, obj.stdout)
    if not ok then
      vim.schedule(function()
        vim.notify('[eslint-trouble] Failed to parse ESLint output', vim.log.levels.ERROR)
      end)
      return
    end

    local items = {}

    for _, file in ipairs(decoded) do
      if file.errorCount > 0 or file.warningCount > 0 then
        for _, msg in ipairs(file.messages) do
          if msg.line then
            table.insert(items, {
              filename = file.filePath,
              lnum = msg.line,
              col = msg.column or 1,
              text = msg.message,
              type = msg.severity == 2 and "E" or "W",
            })
          end
        end
      end
    end

    vim.schedule(function()
      if #items == 0 then
        vim.notify("[eslint-trouble] No problems found", vim.log.levels.INFO)
        return
      end

      vim.fn.setqflist({}, ' ', {
        title = 'ESLint',
        items = items,
      })

      vim.cmd("Trouble quickfix")
    end)
  end)
end

return M

