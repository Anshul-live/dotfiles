-- JSON / YAML / TOML / Markdown / Docker
local prettier = { "prettierd", "prettier", stop_after_first = true }

return {
  parsers = {
    "json", "yaml", "toml", "xml", "markdown", "markdown_inline",
    "dockerfile", "hurl", "gitignore", "gitcommit", "git_rebase", "diff", "regex", "sql",
  },
  tools = {
    "json-lsp", "yaml-language-server", "taplo", "marksman",
    "dockerfile-language-server", "hadolint",
  },
  servers = {
    jsonls = {
      before_init = function(_, config)
        config.settings.json.schemas = require("schemastore").json.schemas()
      end,
      settings = { json = { validate = { enable = true } } },
    },
    yamlls = {
      before_init = function(_, config)
        config.settings.yaml.schemas = require("schemastore").yaml.schemas()
      end,
      settings = { yaml = { schemaStore = { enable = false, url = "" } } },
    },
    taplo = {},
    marksman = {},
    dockerls = {},
  },
  formatters = {
    json = prettier,
    jsonc = prettier,
    yaml = prettier,
    markdown = prettier,
    toml = { "taplo" },
  },
  linters = { dockerfile = { "hadolint" } },
  plugins = {
    { "b0o/SchemaStore.nvim", lazy = true },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = "markdown",
      opts = {},
    },
  },
}
