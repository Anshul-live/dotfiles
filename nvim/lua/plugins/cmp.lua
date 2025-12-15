return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    config = function()
      require("core.cmp")
    end,
  },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },      -- ← THIS WAS MISSING
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
}


