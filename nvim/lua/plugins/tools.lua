-- Dev tools that live next to the code: HTTP requests, databases, Docker, scratch playgrounds.
-- All of them are under <leader>o ("open").
return {
  -- REST client: requests in plain-text *.hurl files (free hurl CLI, also works as API tests).
  -- In a .hurl file: <CR> sends the request under the cursor, <leader>R sends all.
  {
    "jellydn/hurl.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    ft = "hurl",
    keys = {
      { "<leader>oh", "<cmd>edit requests.hurl<CR>", desc = "HTTP requests (requests.hurl)" },
    },
    opts = {
      mode = "split",
      show_notification = false,
      formatters = { json = { "jq" } },
      split_position = "right",
      split_size = "45%",
    },
    config = function(_, opts)
      require("hurl").setup(opts)
      local function maps(buf)
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
        end
        map("<CR>", "<cmd>HurlRunnerAt<CR>", "Send request")
        map("<leader>r", "<cmd>HurlRunnerAt<CR>", "Send request")
        map("<leader>R", "<cmd>HurlRunner<CR>", "Send all requests")
        map("<leader>ov", "<cmd>HurlVerbose<CR>", "Send verbose")
        map("<leader>om", "<cmd>HurlToggleMode<CR>", "Split / popup")
      end
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "hurl",
        callback = function(ev)
          maps(ev.buf)
        end,
      })
      if vim.bo.filetype == "hurl" then
        maps(0)
      end
    end,
  },

  -- Database client: browse tables, run SQL (sqlite, mysql, postgres, ...)
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>ob", "<cmd>DBUIToggle<CR>", desc = "Database" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_execute_on_save = 0 -- run with <leader>r instead (below)
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_winwidth = 32
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
      -- in SQL buffers <leader>r runs the query (same "run" key as everywhere else)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function(ev)
          vim.keymap.set("n", "<leader>r", "<Plug>(DBUI_ExecuteQuery)", { buffer = ev.buf, desc = "Run query" })
          vim.keymap.set("x", "<leader>r", "<Plug>(DBUI_ExecuteQuery)", { buffer = ev.buf, desc = "Run selection" })
        end,
      })
    end,
  },

  -- Docker: containers, logs, restarts in a float
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>od",
        function()
          Snacks.terminal("lazydocker", { win = { position = "float", width = 0.9, height = 0.9, border = "single" } })
        end,
        desc = "Docker",
      },
      -- scratch playgrounds: throwaway buffer for the current filetype; <leader>r runs it
      { "<leader>os", function() Snacks.scratch() end, desc = "Scratch (this filetype)" },
      { "<leader>oS", function() Snacks.scratch.select() end, desc = "Open a scratch" },
    },
  },
}
