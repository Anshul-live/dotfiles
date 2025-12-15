local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.setup({
  defaults = {
    layout_config = {
      width = 0.9,
      height = 0.85,
    },
    sorting_strategy = "ascending",
    prompt_position = "top",

    file_ignore_patterns = {
      "node_modules",
      "build",
      "dist",
      ".git/",
      ".cache",
      "%.o",
      "%.out",
      "%.exe",
    },
  },
})
-- =========================
-- Keymaps (navigation)
-- =========================
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
vim.keymap.set("n", "<leader>fS", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })

vim.keymap.set("n", "<leader>fF", function()
  require("telescope.builtin").git_files()
end, { desc = "Find git files" })

-- Jump list navigation
vim.keymap.set("n", "<C-o>", "<C-o>", { silent = true }) -- back
vim.keymap.set("n", "<C-i>", "<C-i>", { silent = true }) -- forward

