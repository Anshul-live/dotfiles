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
    keys = {
      { "<leader>dc", function() require("dap").continue() end, desc = "Start / continue" },
      { "<leader>dn", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Condition: "))
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>dL",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log message: "))
        end,
        desc = "Log point",
      },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last debug session" },
      { "<leader>dq", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Evaluate" },
      { "<leader>dR", function() vim.api.nvim_feedkeys(vim.keycode("<S-Up>"), "m", false) end, desc = "Rewind to cursor line" },
      { "<leader>dx", function() require("dap").clear_breakpoints() end, desc = "Clear breakpoints" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticError" })

      -- compact: variables + call stack on the right, program I/O below.
      -- REPL on <leader>dr, watch/eval on <leader>de
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

      -- while a session runs: arrows step, K evaluates. Restored when it ends.
      -- rewind: re-run the session (same program + args) and stop at the cursor line.
      -- (real step-back needs `rr`, which macOS doesn't have)
      local rewind_target
      local function rewind()
        local buf, line = vim.api.nvim_get_current_buf(), vim.fn.line(".")
        local bps = require("dap.breakpoints").get(buf)[buf] or {}
        local has = vim.iter(bps):any(function(bp)
          return bp.line == line
        end)
        if not has then
          require("dap.breakpoints").set({}, buf, line) -- temporary, removed on arrival
        end
        local current = dap.session()
        if current then -- make sure the running session knows the target breakpoint
          current:set_breakpoints({ [buf] = require("dap.breakpoints").get(buf)[buf] or {} })
        end
        rewind_target = { buf = buf, line = line, temp = not has }
        vim.notify("rewinding to line " .. line, vim.log.levels.INFO, { title = "debug" })
        dap.restart()
      end
      -- act only on stops of the restarted run, once its stack frames are loaded
      local function arm()
        if rewind_target then
          rewind_target.armed = true
        end
      end
      dap.listeners.after.event_initialized.rewind = arm
      dap.listeners.after.restart.rewind = arm
      dap.listeners.after.stackTrace.rewind = function(session)
        local t = rewind_target
        if not (t and t.armed and session.current_frame) then
          return
        end
        if session.current_frame.line == t.line then
          rewind_target = nil
          if t.temp then
            require("dap.breakpoints").remove(t.buf, t.line)
            session:set_breakpoints({ [t.buf] = require("dap.breakpoints").get(t.buf)[t.buf] or {} })
          end
        elseif session.stopped_thread_id then
          vim.schedule(dap.continue) -- an earlier breakpoint hit first; keep going to the target
        end
      end

      local steps = {
        { "<Down>", dap.step_over, "Step over" },
        { "<Right>", dap.step_into, "Step into" },
        { "<Left>", dap.step_out, "Step out" },
        { "<Up>", dap.continue, "Continue" },
        { "<S-Up>", rewind, "Rewind to cursor line" },
      }
      local eval_bufs = {}
      local function eval_key(buf)
        if eval_bufs[buf] or not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
          return
        end
        eval_bufs[buf] = true
        vim.keymap.set({ "n", "v" }, "K", function()
          dapui.eval(nil, { enter = false })
        end, { buffer = buf, desc = "Debug: value under cursor" })
      end
      local function session_start()
        for _, k in ipairs(steps) do
          vim.keymap.set("n", k[1], k[2], { desc = "Debug: " .. k[3] })
        end
        dapui.open({ layout = 2 }) -- program I/O only; <leader>du shows variables/stack
      end
      local function session_end()
        for _, k in ipairs(steps) do
          vim.keymap.set({ "n", "i", "v" }, k[1], "<nop>") -- back to training wheels
        end
        for buf in pairs(eval_bufs) do
          if vim.api.nvim_buf_is_valid(buf) then
            pcall(vim.keymap.del, { "n", "v" }, "K", { buffer = buf })
            if #vim.lsp.get_clients({ bufnr = buf }) > 0 then
              vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "Hover" })
            end
          end
        end
        eval_bufs = {}
        dapui.close()
      end
      dap.listeners.after.event_initialized.user = session_start
      dap.listeners.after.event_stopped.user = function()
        vim.schedule(function()
          eval_key(vim.api.nvim_get_current_buf())
        end)
      end
      dap.listeners.before.event_terminated.user = session_end
      dap.listeners.before.event_exited.user = session_end
      dap.listeners.before.disconnect.user = session_end

      require("lang").each("dap", dap)
    end,
  },
}
