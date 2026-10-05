-- gp: peek at the definition under the cursor in a float, without leaving your place.
-- The float is the real file: scroll it, edit it, save it. q closes it, <CR> opens the
-- definition in the window you came from, and leaving the float closes it too.
local M = {}

local function open(location, offset_encoding, origin_win)
  local uri = location.uri or location.targetUri
  local range = location.targetSelectionRange or location.range
  local buf = vim.uri_to_bufnr(uri)
  vim.fn.bufload(buf)
  vim.bo[buf].buflisted = true

  local width = math.min(100, math.floor(vim.o.columns * 0.8))
  local height = math.min(20, math.floor(vim.o.lines * 0.45))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    border = "single",
    title = " " .. vim.fn.fnamemodify(vim.uri_to_fname(uri), ":~:.") .. " ",
    title_pos = "left",
  })
  local line = vim.api.nvim_buf_get_lines(buf, range.start.line, range.start.line + 1, false)[1] or ""
  local col = vim.str_byteindex(line, offset_encoding, range.start.character, false)
  vim.api.nvim_win_set_cursor(win, { range.start.line + 1, col })
  vim.cmd("normal! zt")

  -- q / <CR> only while the float is open (buffer-local, removed again on close)
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, false)
    end
  end
  local had = {}
  for _, lhs in ipairs({ "q", "<CR>" }) do
    local m = vim.fn.maparg(lhs, "n", false, true)
    had[lhs] = (m.buffer == 1) and m or nil
  end
  vim.keymap.set("n", "q", close, { buffer = buf, desc = "Close peek" })
  vim.keymap.set("n", "<CR>", function()
    local pos = vim.api.nvim_win_get_cursor(win)
    close()
    if vim.api.nvim_win_is_valid(origin_win) then
      vim.api.nvim_set_current_win(origin_win)
    end
    vim.cmd("normal! m'") -- jumplist: <C-o> comes back
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_cursor(0, pos)
  end, { buffer = buf, desc = "Open definition here" })

  local group = vim.api.nvim_create_augroup("peek_" .. win, { clear = true })
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() == win then
        vim.schedule(close)
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(win),
    callback = function()
      for _, lhs in ipairs({ "q", "<CR>" }) do
        pcall(vim.keymap.del, "n", lhs, { buffer = buf })
        local m = had[lhs]
        if m then
          vim.api.nvim_buf_call(buf, function()
            vim.fn.mapset(m) -- a buffer-local map is restored into its own buffer
          end)
        end
      end
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
end

function M.definition()
  local origin_win = vim.api.nvim_get_current_win()
  local client = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/definition" })[1]
  if not client then
    return vim.notify("No LSP definition provider here", vim.log.levels.WARN)
  end
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  client:request("textDocument/definition", params, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      return vim.notify("No definition found", vim.log.levels.INFO)
    end
    open(vim.islist(result) and result[1] or result, client.offset_encoding, origin_win)
  end, 0)
end

return M
