-- === Arduino Commands for Neovim ===
-- Drop this into: ~/.config/nvim/after/ftplugin/arduino.lua
-- or register it via an autocmd for filetype=arduino or filetype=ino

local arduino = {
  fqbn = "arduino:avr:uno",       -- change this to your board
  port = "/dev/ttyACM0",          -- serial port (use `arduino-cli board list` to find it)
  baud = "115200",                -- serial monitor baudrate
  sketch = vim.fn.expand("%:p:h") -- current file's folder
}

-- Helper: run a command in a floating window
local function run_arduino_cmd(cmd, args)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.4),
    row = math.floor(vim.o.lines * 0.3),
    col = math.floor(vim.o.columns * 0.1),
    border = "rounded",
    title = " " .. cmd .. " ",
  })

  vim.fn.jobstart({ "arduino-cli", cmd, table.unpack(args) }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
      end
    end,
    on_exit = function(_, code)
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
        "",
        "=== Process exited with code " .. code .. " ===",
      })
    end,
  })
end

-- Define commands
vim.api.nvim_create_user_command("ArduinoBuild", function()
  run_arduino_cmd("compile", { "--fqbn", arduino.fqbn, arduino.sketch })
end, {})

vim.api.nvim_create_user_command("ArduinoUpload", function()
  run_arduino_cmd("upload", { "-p", arduino.port, "--fqbn", arduino.fqbn, arduino.sketch })
end, {})

vim.api.nvim_create_user_command("ArduinoMonitor", function()
  run_arduino_cmd("monitor", { "-p", arduino.port, "-c", "baudrate=" .. arduino.baud })
end, {})

-- Buffer-local keymaps for Arduino files only
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "arduino", "ino" },
  callback = function(ev)
    local opts = { buffer = ev.buf, desc = "Arduino command" }
    vim.keymap.set("n", "<localleader>b", ":ArduinoBuild<CR>", opts)
    vim.keymap.set("n", "<localleader>u", ":ArduinoUpload<CR>", opts)
    vim.keymap.set("n", "<localleader>m", ":ArduinoMonitor<CR>", opts)
  end,
})

