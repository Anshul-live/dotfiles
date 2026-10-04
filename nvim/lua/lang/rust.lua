-- rustaceanvim manages rust-analyzer and debugging itself (no lspconfig entry).
-- Requires a Rust toolchain: https://rustup.rs
return {
  requires = { { "cargo", "curl https://sh.rustup.rs -sSf | sh" } },
  parsers = { "rust", "ron" },
  tools = { "rust-analyzer", "codelldb" },
  tests = function()
    return { require("rustaceanvim.neotest") }
  end,
  plugins = {
    {
      "mrcjkb/rustaceanvim",
      version = "^6",
      lazy = false, -- the plugin lazy-loads itself on rust files
    },
    {
      "saecki/crates.nvim",
      event = "BufRead Cargo.toml",
      opts = { lsp = { enabled = true, actions = true, completion = true, hover = true } },
    },
  },
}
