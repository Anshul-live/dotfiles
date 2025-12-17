return {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require("core.format")
  end
  }
