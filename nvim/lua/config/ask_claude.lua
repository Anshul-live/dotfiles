-- <leader>e: ask Claude Code about the code under the cursor (or the visual selection).
-- On a line with an error the question is pre-filled with a fix request. Claude opens in
-- a tmux split (a terminal split outside tmux) with the location, the code and its
-- diagnostics in the prompt, and reads/edits the files itself; Neovim reloads them when
-- you come back (checktime on focus, config/autocmds.lua).
local M = {}

local severity = { "error", "warning", "info", "hint" }

local function launch(prompt)
  local cwd = vim.uv.cwd()
  if vim.env.TMUX then
    -- several arguments: tmux runs claude directly, so the prompt needs no quoting
    vim.system({ "tmux", "split-window", "-h", "-l", "45%", "-c", cwd, "claude", prompt })
  else
    Snacks.terminal({ "claude", prompt }, { cwd = cwd, win = { position = "right", width = 0.45 } })
  end
end

---@param visual? boolean ask about the visual selection instead of the cursor line
function M.ask(visual)
  local first, last = vim.fn.line("."), vim.fn.line(".")
  if visual then
    first, last = vim.fn.line("v"), vim.fn.line(".")
    if first > last then
      first, last = last, first
    end
    vim.cmd("normal! \27") -- leave visual mode
  end
  local file = vim.fn.expand("%:.")
  if file == "" or vim.bo.buftype ~= "" then
    return vim.notify("Ask Claude works on files", vim.log.levels.WARN)
  end

  local diags = vim.tbl_filter(function(d)
    return d.lnum + 1 >= first and d.lnum + 1 <= last
  end, vim.diagnostic.get(0))
  table.sort(diags, function(a, b)
    return a.severity < b.severity
  end)

  -- a cursor line gets a few lines around it; a selection is sent as is
  local from, to = first, last
  if not visual then
    from, to = math.max(1, first - 3), math.min(vim.fn.line("$"), last + 3)
  end
  local code = table.concat(vim.api.nvim_buf_get_lines(0, from - 1, to, false), "\n")
  local ft = vim.bo.filetype

  local default = diags[1] and ("Fix this " .. severity[diags[1].severity] .. ": " .. diags[1].message:gsub("\n.*", "")) or ""
  vim.ui.input({ prompt = "Ask Claude: ", default = default }, function(question)
    if not question or question == "" then
      return
    end
    if vim.bo.modified then
      vim.cmd("silent! write") -- Claude reads the file from disk
    end
    local loc = first == last and ("%s:%d"):format(file, first) or ("%s:%d-%d"):format(file, first, last)
    local parts = { question, "", ("Location: %s (code below is lines %d-%d)"):format(loc, from, to), "```" .. ft, code, "```" }
    if #diags > 0 then
      table.insert(parts, "Diagnostics there:")
      for _, d in ipairs(diags) do
        table.insert(parts, ("- line %d %s: %s%s"):format(d.lnum + 1, severity[d.severity], d.message, d.source and (" (" .. d.source .. ")") or ""))
      end
    end
    launch(table.concat(parts, "\n"))
  end)
end

return M
