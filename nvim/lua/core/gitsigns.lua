local gs = require("gitsigns")

vim.keymap.set("n", "]h", gs.next_hunk, { desc = "Next git hunk" })
vim.keymap.set("n", "[h", gs.prev_hunk, { desc = "Prev git hunk" })

vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })

vim.keymap.set("n", "<leader>hb", function()
  gs.blame_line({ full = true })
end, { desc = "Blame line" })

