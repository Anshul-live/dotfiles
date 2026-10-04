-- General keymaps. Plugin keymaps live with their plugin spec in lua/plugins/.
-- Press <leader> and wait to see everything (which-key).
local map = vim.keymap.set

-- UI
map("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>")

-- centered movement
map("n", "n", "nzzzv", { silent = true })
map("n", "N", "Nzzzv", { silent = true })
map("n", "<C-d>", "<C-d>zz", { silent = true })
map("n", "<C-u>", "<C-u>zz", { silent = true })
map("n", "j", "gj")
map("n", "k", "gk")

-- move selected lines
map("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
map("v", "<", "<gv")
map("v", ">", ">gv")

-- registers
map("v", "<leader>d", '"_d', { desc = "Delete without yank" })
map("n", "<leader>D", '"_d', { desc = "Delete without yank" })
map("v", "<leader>p", '"_dP', { desc = "Paste over without yank" })

-- escape
map("i", "jk", "<Esc>")
map("i", "jj", "<Esc>")

-- files / buffers
map("n", "<leader>pv", "<cmd>Ex<CR>", { desc = "Netrw explorer" })
map("n", "<BS>", "<cmd>b#<CR>", { silent = true, desc = "Previous file" })
map("n", "<leader>r", function()
  require("config.run").run()
end, { desc = "Run file / project" })
map("n", "<leader>R", function()
  require("config.run").run(true)
end, { desc = "Run with arguments" })
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "New buffer" })

-- windows (<C-h/j/k/l> navigation is handled by vim-tmux-navigator)
map("n", "<leader>|", "<cmd>vsplit<CR>", { desc = "Split right" })
map("n", "<leader>-", "<cmd>split<CR>", { desc = "Split below" })
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })

-- terminals (debug I/O, runner, <C-/>): <Esc><Esc> back to normal mode,
-- <C-h/j/k/l> leave the terminal window directly
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Normal mode" })
map("t", "<C-h>", "<C-\\><C-n><cmd>TmuxNavigateLeft<CR>", { desc = "Window left" })
map("t", "<C-j>", "<C-\\><C-n><cmd>TmuxNavigateDown<CR>", { desc = "Window down" })
map("t", "<C-k>", "<C-\\><C-n><cmd>TmuxNavigateUp<CR>", { desc = "Window up" })
map("t", "<C-l>", "<C-\\><C-n><cmd>TmuxNavigateRight<CR>", { desc = "Window right" })

-- drop Neovim's gr* LSP prefix so `gr` (references) fires instantly;
-- rename / code action live on <leader>cr / <leader>ca
for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx" }) do
  pcall(vim.keymap.del, { "n", "x" }, lhs)
end

-- diagnostics ([d / ]d are Neovim defaults)
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next error" })
map("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Prev error" })

-- quickfix
map("n", "<leader>xq", "<cmd>copen<CR>", { desc = "Quickfix list" })

-- undotree (built into Neovim 0.12)
map("n", "<leader>uu", function()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd("Undotree")
end, { desc = "Undotree" })

-- verify the whole dev setup (servers, formatters, debuggers, parsers, tools)
vim.api.nvim_create_user_command("DevCheck", function()
  require("config.devcheck").run()
end, { desc = "Check the dev setup" })
map("n", "<leader>oc", "<cmd>DevCheck<CR>", { desc = "Check dev setup" })

-- forcing for learning
map({ "n", "i", "v" }, "<Up>", "<nop>")
map({ "n", "i", "v" }, "<Down>", "<nop>")
map({ "n", "i", "v" }, "<Left>", "<nop>")
map({ "n", "i", "v" }, "<Right>", "<nop>")
map({ "n", "v" }, "<LeftMouse>", "<nop>")
map({ "n", "v" }, "<LeftDrag>", "<nop>")
