local lint = require("lint")

lint.linters_by_ft = {
  python = { "ruff" },
  c = { "clangtidy" },
  cpp = { "clangtidy" },
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  go = { "golangcilint" },
}

vim.api.nvim_create_autocmd(
  { "BufWritePost", "BufReadPost", "InsertLeave" },
  {
    callback = function()
      lint.try_lint()
    end,
  }
)

