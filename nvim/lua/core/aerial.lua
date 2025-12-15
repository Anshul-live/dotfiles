require("aerial").setup({
  layout = {
    max_width = { 40 },
    min_width = 30,
  },
   close_automatic_events = { "switch_buffer", "unfocus", "jump" },
  backends = { "lsp" },
  show_guides = true,
  filter_kind = false, -- show all symbols
  highlight_on_hover = true,
  autojump = true,
})
vim.keymap.set("n", "<leader>so", "<cmd>AerialToggle<CR>", { desc = "Symbols outline" })
vim.keymap.set("n", "<leader>sn", "<cmd>AerialNext<CR>", { desc = "Next symbol" })
vim.keymap.set("n", "<leader>sp", "<cmd>AerialPrev<CR>", { desc = "Prev symbol" })

