return {
  parsers = { "bash", "fish" },
  tools = { "bash-language-server", "shellcheck", "shfmt" },
  servers = {
    bashls = { filetypes = { "sh", "bash", "zsh" } }, -- runs shellcheck automatically
  },
  formatters = { sh = { "shfmt" }, bash = { "shfmt" }, zsh = { "shfmt" } },
}
