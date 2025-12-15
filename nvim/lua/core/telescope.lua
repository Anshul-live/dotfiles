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
vim.keymap.set("n", "<leader>/", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>bb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>ss", builtin.lsp_document_symbols, { desc = "Document symbols" })
vim.keymap.set("n", "<leader>sw", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })

vim.keymap.set("n", "<leader>fg", function()
  require("telescope.builtin").git_files()
end, { desc = "Find git files" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf, desc = "Find references" }
    vim.keymap.set("n", "gr", function()
      require("telescope.builtin").lsp_references()
    end, opts)
  end,
})

--git navigation
vim.keymap.set("n", "<leader>gs",
  require("telescope.builtin").git_status,
  { desc = "Git status" })

vim.keymap.set("n", "<leader>gc",
  require("telescope.builtin").git_commits,
  { desc = "Git commits" })

vim.keymap.set("n", "<leader>gb",
  require("telescope.builtin").git_branches,
  { desc = "Git branches" })


-- Jump list navigation
vim.keymap.set("n", "<C-o>", "<C-o>", { silent = true }) -- back
vim.keymap.set("n", "<C-i>", "<C-i>", { silent = true }) -- forward

