-- LSP, Mason tool installation, formatting, linting.
-- Servers/tools/formatters/linters come from lua/lang/*.lua
local lang = require("lang")

return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "single",
        icons = { package_installed = "\u{f00c}", package_pending = "\u{f110}", package_uninstalled = "\u{f00d}" },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
    -- startup only stats Mason's package folders; the installer loads only if one is missing
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          local root = vim.fn.stdpath("data") .. "/mason/packages/"
          for _, tool in ipairs(lang.list("tools")) do
            if not vim.uv.fs_stat(root .. tool) then
              require("lazy").load({ plugins = { "mason-tool-installer.nvim" } })
              return vim.cmd("MasonToolsInstall")
            end
          end
        end,
      })
    end,
    config = function()
      local seen, tools = {}, {}
      for _, tool in ipairs(lang.list("tools")) do
        if not seen[tool] then
          seen[tool] = true
          table.insert(tools, tool)
        end
      end
      require("mason-tool-installer").setup({ ensure_installed = tools, run_on_start = false })
    end,
  },
  {
    "neovim/nvim-lspconfig", -- provides default configs for vim.lsp.config
    event = { "BufReadPre", "BufNewFile" },
    -- mason is a dependency so its bin/ is on PATH before servers start
    dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
    config = function()
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
      lang.each("setup")
      for name, config in pairs(lang.map("servers")) do
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end

      -- Neovim defaults kept: K hover · gO document symbols · <C-s> (insert) signature help
      -- (the default gr* prefix maps are removed in config/keymaps.lua so `gr` is instant)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = ev.buf, desc = desc, nowait = true })
          end
          local pick = Snacks.picker

          map("gd", pick.lsp_definitions, "Go to definition")
          map("gD", pick.lsp_declarations, "Go to declaration")
          map("gy", pick.lsp_type_definitions, "Go to type definition")
          map("gr", pick.lsp_references, "References")
          map("gI", pick.lsp_implementations, "Go to implementation")
          map("<leader>ci", pick.lsp_incoming_calls, "Incoming calls")
          map("<leader>co", pick.lsp_outgoing_calls, "Outgoing calls")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>cl", "<cmd>checkhealth vim.lsp<CR>", "LSP info")
          map("<leader>cL", "<cmd>lsp restart<CR>", "Restart LSP")

          -- inlay hints are off by default to keep code clean; <leader>uh toggles them
          if client and client.name == "clangd" then
            map("<leader>ch", "<cmd>LspClangdSwitchSourceHeader<CR>", "Switch source/header")
            -- clangd_extensions (lang/c.lua)
            map("<leader>ct", "<cmd>ClangdTypeHierarchy<CR>", "Type hierarchy")
            map("<leader>cy", "<cmd>ClangdSymbolInfo<CR>", "Symbol info")
            map("<leader>cm", "<cmd>ClangdMemoryUsage<CR>", "clangd memory usage")
            map("<leader>cA", "<cmd>ClangdAST<CR>", "AST of line")
            map("<leader>cA", ":ClangdAST<CR>", "AST of selection", "x")
          end
        end,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = lang.map("formatters"),
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(buf)
        if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
          return
        end
        return { timeout_ms = 1000 }
      end,
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = lang.map("linters")
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
        callback = function()
          -- skip linters that aren't installed yet instead of erroring
          local names = vim.tbl_filter(function(name)
            local linter = lint.linters[name]
            local cmd = type(linter) == "table" and linter.cmd or name
            return type(cmd) ~= "string" or vim.fn.executable(cmd) == 1
          end, lint._resolve_linter_by_ft(vim.bo.filetype))
          lint.try_lint(names)
        end,
      })
    end,
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim", -- whole message inline (wrapped), no line shifting
    -- it hooks a buffer on these events (default LspAttach only, which misses linter-only buffers)
    event = { "LspAttach", "DiagnosticChanged" },
    opts = {
      options = {
        overwrite_events = { "LspAttach", "DiagnosticChanged" },
        -- cursor line only; <leader>uv (plugins/ui.lua) turns on every line
        multilines = { enabled = false, always_show = false },
      },
    },
  },
}
