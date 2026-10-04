return {
  requires = { { "python3", "brew install python" } },
  parsers = { "python", "requirements" },
  tools = { "basedpyright", "ruff", "debugpy" },
  servers = {
    basedpyright = {
      settings = {
        basedpyright = {
          analysis = { typeCheckingMode = "standard" },
        },
      },
    },
    ruff = {}, -- linting + quick fixes
  },
  formatters = { python = { "ruff_organize_imports", "ruff_format" } },
  dap = function()
    require("dap-python").setup("debugpy-adapter")
  end,
  tests = function()
    return { require("neotest-python")({ dap = { justMyCode = false } }) }
  end,
  plugins = {
    { "mfussenegger/nvim-dap-python", lazy = true },
    { "nvim-neotest/neotest-python", lazy = true },
  },
}
