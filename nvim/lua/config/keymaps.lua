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
-- (<leader>D: <leader>d enters debug mode)
map({ "n", "x" }, "<leader>D", '"_d', { desc = "Delete without yank" })
map("v", "<leader>p", '"_dP', { desc = "Paste over without yank" })

-- escape
map("i", "jk", "<Esc>")
map("i", "jj", "<Esc>")

-- files / buffers
map("n", "<BS>", "<cmd>b#<CR>", { silent = true, desc = "Previous file" })
map("n", "<leader>r", function()
  require("config.run").run()
end, { desc = "Run file / project" })
map("n", "<leader>R", function()
  require("config.run").run(true)
end, { desc = "Run with arguments" })

-- windows (<C-h/j/k/l> move and <M-arrows> resize via smart-splits, plugins/editor.lua)
map("n", "<leader>|", "<cmd>vsplit<CR>", { desc = "Split right" })
map("n", "<leader>-", "<cmd>split<CR>", { desc = "Split below" })

-- terminals (debug I/O, runner, <C-/>): <Esc><Esc> back to normal mode,
-- <C-h/j/k/l> leave the terminal window directly
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Normal mode" })
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  map("t", "<C-" .. key .. ">", function()
    vim.cmd.stopinsert()
    require("smart-splits")["move_cursor_" .. dir]()
  end, { desc = "Window " .. dir })
end

-- drop Neovim's gr* LSP prefix so `gr` (references) fires instantly;
-- rename / code action live on <leader>cr / <leader>ca
for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx" }) do
  pcall(vim.keymap.del, { "n", "x" }, lhs)
end

-- diagnostics ([d / ]d are Neovim defaults)
-- ask Claude Code about the error / code here, or the selection (config/ask_claude.lua)
map("n", "<leader>e", function()
  require("config.ask_claude").ask()
end, { desc = "Ask Claude about this" })
map("x", "<leader>e", function()
  require("config.ask_claude").ask(true)
end, { desc = "Ask Claude about selection" })
map("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next error" })
map("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Prev error" })

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

-- notes for this project: a markdown float kept per working directory (outside the repo)
map("n", "<leader>n", function()
  Snacks.scratch({ name = "Notes", ft = "markdown", icon = "\u{f0219} ", filekey = { cwd = true, branch = false, count = false } })
end, { desc = "Project notes" })

-- focus mode: errors only, quiet, dimmed, pomodoro timer (<leader>z)
require("config.focus")
