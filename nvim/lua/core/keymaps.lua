-- =========================
-- Window navigation
-- =========================
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true })

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "jj", "<Esc>")
 

-- forcing for learning
vim.keymap.set({ "n", "v" }, "h", "<nop>")
vim.keymap.set({ "n", "v" }, "l", "<nop>")

vim.keymap.set({ "n", "i", "v" }, "<Up>", "<nop>")
vim.keymap.set({ "n", "i", "v" }, "<Down>", "<nop>")
vim.keymap.set({ "n", "i", "v" }, "<Left>", "<nop>")
vim.keymap.set({ "n", "i", "v" }, "<Right>", "<nop>")
vim.keymap.set("n", "<LeftMouse>", "<nop>")
vim.keymap.set("v", "<LeftMouse>", "<nop>")
vim.keymap.set("n", "<LeftDrag>", "<nop>")
vim.keymap.set("v", "<LeftDrag>", "<nop>")


