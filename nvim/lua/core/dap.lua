local dap = require("dap")
local dapui = require("dapui")

-- =========================
-- LLDB (C / C++)
-- =========================
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
    args = { "--port", "${port}" },
  },
}

dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input(
        "Path to executable: ",
        vim.fn.getcwd() .. "/",
        "file"
      )
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

-- C uses same config
dap.configurations.c = dap.configurations.cpp

-- =========================
-- Keymaps
-- =========================
vim.keymap.set("n", "<leader>dc", dap.continue,        { desc = "DAP continue" })
vim.keymap.set("n", "<leader>dn", dap.step_over,       { desc = "DAP next / step over" })
vim.keymap.set("n", "<leader>di", dap.step_into,       { desc = "DAP step into" })
vim.keymap.set("n", "<leader>do", dap.step_out,        { desc = "DAP step out" })

-- breakpoints
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "DAP conditional breakpoint" })

-- session / tools
vim.keymap.set("n", "<leader>dr", dap.repl.open,       { desc = "DAP REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last,        { desc = "DAP run last" })
vim.keymap.set("n", "<leader>dq", dap.terminate,       { desc = "DAP terminate" })-- =========================
-- DAP UI
-- =========================
dapui.setup({
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.25 },
        { id = "breakpoints", size = 0.25 },
        { id = "stacks", size = 0.25 },
        { id = "watches", size = 0.25 },
      },
      size = 40,
      position = "left",
    },
    {
      elements = {
        { id = "repl", size = 0.5 },
        { id = "console", size = 0.5 },
      },
      size = 10,
      position = "bottom",
    },
  },
})

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

vim.keymap.set("n", "<leader>du", dapui.toggle,
  { desc = "DAP UI toggle" })

