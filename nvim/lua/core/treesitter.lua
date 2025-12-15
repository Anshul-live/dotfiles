require("nvim-treesitter").setup({
  ensure_installed = {
    "c",
    "cpp",
    "lua",
    "bash",
    "json",
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
})

