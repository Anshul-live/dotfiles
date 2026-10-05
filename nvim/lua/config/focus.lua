-- Focus mode (<leader>z, or the <leader>m picker): a passive extra mode for deep work.
--   * only errors: warnings/hints leave the gutter, underlines and inline messages
--   * notifications muted (errors still come through)
--   * code outside the current scope is dimmed
--   * a 25-minute timer in the statusline; when it runs out you get a nudge and focus ends
-- Everything is restored when you leave (<leader>z again, or entering another mode).
local M = {}

local minutes = 25
local ends_at, timer, saved_diag, saved_notify

---Statusline text, e.g. "󰔛 18m"; empty when focus is off.
function M.status()
  if not ends_at then
    return ""
  end
  return ("\u{f051b} %dm"):format(math.max(0, math.ceil((ends_at - os.time()) / 60)))
end

local function tiny(severities)
  local ok, t = pcall(require, "tiny-inline-diagnostic")
  if ok and t.config then
    t.change_severities(severities)
  end
end

local function on_enter()
  local sev = vim.diagnostic.severity
  local cfg = vim.diagnostic.config() or {}
  saved_diag = vim.deepcopy(cfg)
  local errors = { min = sev.ERROR }
  vim.diagnostic.config({
    signs = vim.tbl_extend("force", type(cfg.signs) == "table" and cfg.signs or {}, { severity = errors }),
    underline = { severity = errors },
  })
  tiny({ sev.ERROR })

  saved_notify = vim.notify
  vim.notify = function(msg, level, opts)
    if (level or vim.log.levels.INFO) >= vim.log.levels.ERROR then
      return saved_notify(msg, level, opts)
    end
  end

  Snacks.dim.enable()

  ends_at = os.time() + minutes * 60
  timer = vim.uv.new_timer()
  timer:start(30000, 30000, vim.schedule_wrap(function()
    vim.cmd.redrawstatus()
    if ends_at and os.time() >= ends_at then
      local notify = saved_notify
      require("config.modes").exit()
      notify(minutes .. " focused minutes done. Take a break.", vim.log.levels.WARN, { title = "focus" })
    end
  end))
end

local function on_exit()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  ends_at = nil
  Snacks.dim.disable()
  if saved_notify then
    vim.notify = saved_notify
    saved_notify = nil
  end
  if saved_diag then
    vim.diagnostic.config(saved_diag)
    saved_diag = nil
  end
  local sev = vim.diagnostic.severity
  tiny({ sev.ERROR, sev.WARN, sev.INFO, sev.HINT })
end

require("config.modes").define("focus", {
  key = "<leader>z",
  desc = ("errors only, quiet, dimmed, %d-min timer"):format(minutes),
  passive = true,
  keys = {},
  on_enter = on_enter,
  on_exit = on_exit,
})

return M
