-- nvim-treesitter `main` branch: installs parsers; highlighting/indent are
-- started per buffer below. Requires the `tree-sitter` CLI (brew install tree-sitter-cli).
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local base = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "bash", "regex", "comment" }
      local wanted = vim.list_extend(base, require("lang").list("parsers"))
      local installed = require("nvim-treesitter.config").get_installed()
      local missing = vim.tbl_filter(function(p)
        return not vim.tbl_contains(installed, p)
      end, wanted)
      if #missing > 0 then
        require("nvim-treesitter").install(missing)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(ev)
          if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })
      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      -- vaf / dif / cic / yaa ...
      local objects = {
        f = "function", c = "class", a = "parameter", i = "conditional", l = "loop", k = "block",
      }
      for key, obj in pairs(objects) do
        for _, scope in ipairs({ "outer", "inner" }) do
          local lhs = (scope == "outer" and "a" or "i") .. key
          vim.keymap.set({ "x", "o" }, lhs, function()
            select.select_textobject("@" .. obj .. "." .. scope, "textobjects")
          end, { desc = scope .. " " .. obj })
        end
      end

      -- ]f [f functions · ]C [C classes
      local moves = { f = "function", C = "class" }
      for key, obj in pairs(moves) do
        vim.keymap.set({ "n", "x", "o" }, "]" .. key, function()
          move.goto_next_start("@" .. obj .. ".outer", "textobjects")
        end, { desc = "Next " .. obj })
        vim.keymap.set({ "n", "x", "o" }, "[" .. key, function()
          move.goto_previous_start("@" .. obj .. ".outer", "textobjects")
        end, { desc = "Prev " .. obj })
      end

      vim.keymap.set("n", "<leader>cs", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap parameter with next" })
      vim.keymap.set("n", "<leader>cS", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap parameter with prev" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context", -- sticky function/class header
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3, multiline_threshold = 1 },
    keys = {
      { "<leader>ut", "<cmd>TSContext toggle<CR>", desc = "Toggle sticky context" },
      {
        "[x",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Jump to context",
      },
    },
  },
}
