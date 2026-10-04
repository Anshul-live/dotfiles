return {
  parsers = { "lua", "luadoc", "luap", "vim", "vimdoc", "query" },
  tools = { "lua-language-server", "stylua" },
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          completion = { callSnippet = "Replace" },
          hint = { enable = true, setType = true, arrayIndex = "Disable" },
          workspace = { checkThirdParty = false },
        },
      },
    },
  },
  formatters = { lua = { "stylua" } },
  plugins = {
    -- Neovim API completion/types when editing this config
    {
      "folke/lazydev.nvim",
      ft = "lua",
      opts = {
        library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
      },
    },
  },
}
