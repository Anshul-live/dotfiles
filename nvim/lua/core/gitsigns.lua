local gs = require("gitsigns")
gs.setup({
  signs = {
    add          = { text = "+" },
    change       = { text = "~" },
    delete       = { text = "_" },
    topdelete    = { text = "‾" },
    changedelete = { text = "~" },
  },
  signcolumn = true,   -- show signs
  numhl      = false,  -- no number highlight
  linehl     = false,  -- disable full-line color
})


-- Reserve git namespace
vim.keymap.set("n", "<leader>g", "<nop>")
vim.keymap.set("n", "<leader>gh", "<nop>")
vim.keymap.set("n", "<leader>h", "<nop>", { desc = "Git hunks" })

vim.keymap.set("n", "]h", gs.next_hunk, { desc = "Next git hunk" })
vim.keymap.set("n", "[h", gs.prev_hunk, { desc = "Prev git hunk" })

vim.keymap.set("n", "<leader>ghp", gs.preview_hunk, { desc = "Preview hunk" })
vim.keymap.set("n", "<leader>ghs", gs.stage_hunk, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>ghr", gs.reset_hunk, { desc = "Reset hunk" })

vim.keymap.set("n", "<leader>ghb", function()
  gs.blame_line({ full = true })
end, { desc = "Blame line" })

