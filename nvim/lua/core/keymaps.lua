-- UI
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>")

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true })
vim.keymap.set("n", "n", "nzzzv", { silent = true })
vim.keymap.set("n", "N", "Nzzzv", { silent = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { silent = true })
vim.keymap.set("n", "<leader>d", '"_d', { silent = true })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set("v", "<leader>d", '"_d', { silent = true })

-- Code Diagnostics
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.diagnostic.config({
	float = {
		border = "rounded",
		source = "always",
	},
	severity_sort = true,
})

vim.keymap.set("v", "<leader>p", '"_dP')
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "<leader>pv", ":Ex<CR>")

vim.keymap.set("n", "<leader><leader>", "<cmd>b#<CR>", {
	noremap = true,
	silent = true,
	desc = "Switch to alternate buffer",
})

-- forcing for learning
-- vim.keymap.set({ "n", "v" }, "h", "<nop>")
-- vim.keymap.set({ "n", "v" }, "l", "<nop>")
-- vim.keymap.set("n", "v", "<nop>")
-- vim.keymap.set("n", "V", "<nop>")

vim.keymap.set({ "n", "i", "v" }, "<Up>", "<nop>")
vim.keymap.set({ "n", "i", "v" }, "<Down>", "<nop>")
vim.keymap.set({ "n", "i", "v" }, "<Left>", "<nop>")
vim.keymap.set({ "n", "i", "v" }, "<Right>", "<nop>")
vim.keymap.set("n", "<LeftMouse>", "<nop>")
vim.keymap.set("v", "<LeftMouse>", "<nop>")
vim.keymap.set("n", "<LeftDrag>", "<nop>")
vim.keymap.set("v", "<LeftDrag>", "<nop>")
