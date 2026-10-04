-- JavaScript / TypeScript / React / HTML / CSS / Tailwind
local js_fts = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "svelte" }
local prettier = { "prettierd", "prettier", stop_after_first = true }

local formatters = { html = prettier, css = prettier, scss = prettier, less = prettier, graphql = prettier }
for _, ft in ipairs(js_fts) do
  formatters[ft] = prettier
end

return {
  requires = { { "node", "brew install node" }, { "npm", "brew install node" } },
  parsers = {
    "javascript", "typescript", "tsx", "jsdoc",
    "html", "css", "scss", "graphql", "vue", "svelte", "prisma",
  },
  tools = {
    "vtsls", "eslint-lsp", "html-lsp", "css-lsp", "tailwindcss-language-server",
    "emmet-language-server", "prettierd", "prettier", "js-debug-adapter",
  },
  servers = {
    vtsls = {
      settings = {
        complete_function_calls = true,
        vtsls = { enableMoveToFileCodeAction = true, autoUseWorkspaceTsdk = true },
        typescript = {
          updateImportsOnFileMove = { enabled = "always" },
          suggest = { completeFunctionCalls = true },
          inlayHints = {
            parameterNames = { enabled = "literals" },
            parameterTypes = { enabled = true },
            variableTypes = { enabled = false },
            propertyDeclarationTypes = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            enumMemberValues = { enabled = true },
          },
        },
      },
    },
    eslint = {}, -- lint diagnostics + "fix all" code actions
    html = {},
    cssls = {},
    tailwindcss = {
      -- attach only in real tailwind projects (lspconfig's default also matches any .git)
      root_dir = function(buf, on_dir)
        local fname = vim.api.nvim_buf_get_name(buf)
        local markers = { "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.mjs", "tailwind.config.ts",
          "postcss.config.js", "postcss.config.cjs", "postcss.config.mjs", "postcss.config.ts" }
        markers = require("lspconfig.util").insert_package_json(markers, "tailwindcss", fname)
        local found = vim.fs.find(markers, { path = fname, upward = true })[1]
        if found then
          on_dir(vim.fs.dirname(found))
        end
      end,
    },
    emmet_language_server = {},
  },
  formatters = formatters,
  dap = function(dap)
    for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
      dap.adapters[adapter] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = { command = "js-debug-adapter", args = { "${port}" } },
      }
    end
    -- allow `"type": "node"` / `"chrome"` in .vscode/launch.json
    dap.adapters.node = dap.adapters["pwa-node"]
    dap.adapters.chrome = dap.adapters["pwa-chrome"]

    for _, ft in ipairs(js_fts) do
      dap.configurations[ft] = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch current file (node)",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to node process",
          processId = function()
            return require("dap.utils").pick_process()
          end,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-chrome",
          request = "launch",
          name = "Launch Chrome (localhost:3000)",
          url = function()
            return vim.fn.input("URL: ", "http://localhost:3000")
          end,
          webRoot = "${workspaceFolder}",
          sourceMaps = true,
        },
      }
    end
  end,
  tests = function()
    return {
      require("neotest-jest")({}),
      require("neotest-vitest"),
    }
  end,
  plugins = {
    { "nvim-neotest/neotest-jest", lazy = true },
    { "marilari88/neotest-vitest", lazy = true },
    -- auto close/rename html & jsx tags
    { "windwp/nvim-ts-autotag", event = { "BufReadPre", "BufNewFile" }, opts = {} },
  },
}
