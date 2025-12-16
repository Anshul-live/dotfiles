-- core
require("core")

-- plugins
require("plugins")

local function is_tracked_git_file(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    return false
  end

  local dir = vim.fn.fnamemodify(file, ":p:h")

  vim.fn.system({
    "git",
    "-C",
    dir,
    "ls-files",
    "--error-unmatch",
    file,
  })

  return vim.v.shell_error == 0
end

local function attach_gitsigns_once(bufnr)
  if vim.b[bufnr].gitsigns_attached_once then
    return
  end

  vim.b[bufnr].gitsigns_attached_once = true
  vim.cmd("silent! Gitsigns attach")
end

vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  callback = function(args)
    if is_tracked_git_file(args.buf) then
      attach_gitsigns_once(args.buf)
    end
  end,
})


