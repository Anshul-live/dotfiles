local group = vim.api.nvim_create_augroup("user_config", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- flash yanked text
autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- reopen files at the last cursor position
autocmd("BufReadPost", {
  group = group,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines and vim.bo[ev.buf].filetype ~= "gitcommit" then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- reload files changed outside of Neovim
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  command = "checktime",
})

-- keep splits equal when the terminal is resized
autocmd("VimResized", {
  group = group,
  command = "tabdo wincmd =",
})

-- close helper windows with q
autocmd("FileType", {
  group = group,
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "dap-float", "neotest-output", "neotest-summary", "nvim-undotree" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})

-- spell check prose
autocmd("FileType", {
  group = group,
  pattern = { "markdown", "gitcommit", "text" },
  callback = function(ev)
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
    -- wrapped lines: j/k move by screen line (buffer-local, so it wins over hardtime's j/k)
    vim.keymap.set("n", "j", "gj", { buffer = ev.buf })
    vim.keymap.set("n", "k", "gk", { buffer = ev.buf })
  end,
})

-- autosave when leaving a buffer or switching apps (<leader>ua toggles)
autocmd({ "BufLeave", "FocusLost" }, {
  group = group,
  callback = function(ev)
    local bo = vim.bo[ev.buf]
    if vim.g.autosave ~= false and bo.modified and bo.buftype == "" and bo.modifiable and vim.api.nvim_buf_get_name(ev.buf) ~= "" then
      vim.api.nvim_buf_call(ev.buf, function()
        vim.cmd("silent! update")
      end)
    end
  end,
})

-- create missing parent directories on save
autocmd("BufWritePre", {
  group = group,
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
