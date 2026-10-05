-- Debugging. Adapters/configurations come from lua/lang/*.lua.
-- Projects with a .vscode/launch.json are picked up automatically.
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      { "theHamsta/nvim-dap-virtual-text", opts = { virt_text_pos = "eol", highlight_changed_variables = true } },
      "mason-org/mason.nvim", -- adapters run from Mason's bin/
    },
    lazy = true, -- loads on first require("dap"), i.e. when debug mode is used
    init = function()
      local function dap()
        return require("dap")
      end
      require("config.modes").define("debug", {
        key = "<leader>d",
        desc = "breakpoints, run, step (auto-on while debugging)",
        keys = {
          { "c", function() dap().continue() end, "start / continue" },
          { "n", function() dap().step_over() end, "step over" },
          { "i", function() dap().step_into() end, "step into" },
          { "o", function() dap().step_out() end, "step out" },
          { "C", function() dap().run_to_cursor() end, "run to cursor" },
          { "R", function() require("config.debug_rewind").rewind() end, "rewind to cursor" },
          { "l", function() dap().run_last() end, "run last session" },
          { "s", function() dap().terminate() end, "stop session" },
          { "b", function() dap().toggle_breakpoint() end, "breakpoint" },
          { "B", function() dap().set_breakpoint(vim.fn.input("Condition: ")) end, "conditional bp" },
          { "L", function() dap().set_breakpoint(nil, nil, vim.fn.input("Log message: ")) end, "log point" },
          { "x", function() dap().clear_breakpoints() end, "clear breakpoints" },
          { "e", function() require("dapui").eval(nil, { enter = false }) end, "value under cursor", mode = { "n", "x" } },
          { "u", function() require("dapui").toggle() end, "variables / stack" },
          { "r", function() dap().repl.toggle() end, "REPL" },
        },
      })
    end,
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticError" })

      -- compact: variables + call stack on the right, program I/O below.
      -- REPL on `r`, value under cursor on `e` (debug mode)
      dapui.setup({
        controls = { enabled = false },
        floating = { border = "single" },
        layouts = {
          {
            elements = { { id = "scopes", size = 0.7 }, { id = "stacks", size = 0.3 } },
            size = 0.3,
            position = "right",
          },
          {
            elements = { { id = "console", size = 1 } },
            size = 0.25,
            position = "bottom",
          },
        },
      })
      -- keep the cursor in the code; the program I/O panel never steals focus
      dap.defaults.fallback.focus_terminal = false

      require("config.debug_rewind").setup(dap)

      -- debug mode turns on when a session starts and off when it ends
      -- (unless you entered it yourself); program I/O panel opens alongside
      local modes = require("config.modes")
      local function session_start()
        modes.enter("debug", { auto = true })
        dapui.open({ layout = 2 }) -- program I/O only; `u` shows variables/stack
      end
      local function session_end()
        modes.exit_auto("debug")
        dapui.close()
      end
      dap.listeners.after.event_initialized.user = session_start
      dap.listeners.before.event_terminated.user = session_end
      dap.listeners.before.event_exited.user = session_end
      dap.listeners.before.disconnect.user = session_end

      require("lang").each("dap", dap)
    end,
  },
}
