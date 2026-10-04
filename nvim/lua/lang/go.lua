return {
  requires = { { "go", "brew install go" } },
  parsers = { "go", "gomod", "gosum", "gowork" },
  tools = { "gopls", "goimports", "gofumpt", "golangci-lint", "delve" },
  servers = {
    gopls = {
      settings = {
        gopls = {
          gofumpt = true,
          usePlaceholders = true,
          staticcheck = true,
          analyses = { unusedparams = true, unusedwrite = true, nilness = true },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
        },
      },
    },
  },
  formatters = { go = { "goimports", "gofumpt" } },
  linters = { go = { "golangcilint" } },
  dap = function()
    require("dap-go").setup()
  end,
  tests = function()
    return { require("neotest-golang")({}) }
  end,
  plugins = {
    { "leoluz/nvim-dap-go", lazy = true },
    { "fredrikaverpil/neotest-golang", lazy = true },
  },
}
