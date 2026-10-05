-- Debug "rewind": re-run the session (same program + args) and stop at the cursor line.
-- (real step-back needs `rr`, which macOS doesn't have)
local M = {}

local target

function M.rewind()
  local dap = require("dap")
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
  target = { buf = buf, line = line, temp = not has }
  vim.notify("rewinding to line " .. line, vim.log.levels.INFO, { title = "debug" })
  dap.restart()
end

function M.setup(dap)
  -- act only on stops of the restarted run, once its stack frames are loaded
  local function arm()
    if target then
      target.armed = true
    end
  end
  dap.listeners.after.event_initialized.rewind = arm
  dap.listeners.after.restart.rewind = arm
  dap.listeners.after.stackTrace.rewind = function(session)
    local t = target
    if not (t and t.armed and session.current_frame) then
      return
    end
    if session.current_frame.line == t.line then
      target = nil
      if t.temp then
        require("dap.breakpoints").remove(t.buf, t.line)
        session:set_breakpoints({ [t.buf] = require("dap.breakpoints").get(t.buf)[t.buf] or {} })
      end
    elseif session.stopped_thread_id then
      vim.schedule(dap.continue) -- an earlier breakpoint hit first; keep going to the target
    end
  end
end

return M
