return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("core.lsp")
    end,
  },
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "clangd",
          "pyright",
          "gopls",
          "rust_analyzer",
        },
      })
    end,
  },
}

