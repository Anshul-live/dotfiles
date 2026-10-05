-- Dev tools that live next to the code: HTTP requests, databases, Docker, scratch playgrounds.
-- HTTP, database and Docker are modes (config/modes.lua): <leader>oh / ob / od, or <leader>m.

-- Docker mode: lazydocker in a float, compose commands in a bottom terminal.
-- Defined here, not in a spec's init: snacks.nvim's init lives in plugins/ui.lua
-- and lazy.nvim keeps only one init per plugin.
local function docker(cmd)
  return function()
    Snacks.terminal(cmd, { interactive = false, win = { position = "bottom", height = 0.3 } })
  end
end
require("config.modes").define("docker", {
  key = "<leader>od",
  desc = "lazydocker, compose up/down/logs/build",
  keys = {
    {
      "o",
      function()
        Snacks.terminal("lazydocker", { win = { position = "float", width = 0.9, height = 0.9, border = "single" } })
      end,
      "lazydocker",
    },
    { "p", docker("docker ps"), "containers" },
    { "u", docker("docker compose up -d"), "compose up" },
    { "d", docker("docker compose down"), "compose down" },
    { "r", docker("docker compose restart"), "compose restart" },
    { "b", docker("docker compose build"), "compose build" },
    { "l", docker("docker compose logs -f --tail=100"), "compose logs" },
  },
})

return {
  -- REST client: requests in plain-text *.hurl files (free hurl CLI, also works as API tests).
  -- In a .hurl file <CR> (or <leader>r) sends the request under the cursor; http mode has the rest.
  {
    "jellydn/hurl.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    ft = "hurl",
    init = function()
      require("config.modes").define("http", {
        key = "<leader>oh",
        desc = "send requests from requests.hurl",
        keys = {
          { "s", "<cmd>HurlRunnerAt<CR>", "send request" },
          { "a", "<cmd>HurlRunner<CR>", "send all" },
          { "v", "<cmd>HurlVerbose<CR>", "send verbose" },
          { "m", "<cmd>HurlToggleMode<CR>", "split / popup" },
          { "o", "<cmd>edit requests.hurl<CR>", "requests.hurl" },
        },
        on_enter = function()
          if vim.bo.filetype ~= "hurl" then
            vim.cmd.edit("requests.hurl")
          end
        end,
      })
    end,
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
    init = function()
      require("config.modes").define("db", {
        key = "<leader>ob",
        desc = "database sidebar, run and save queries",
        keys = {
          { "r", "<Plug>(DBUI_ExecuteQuery)", "run query", mode = { "n", "x" } },
          { "s", "<Plug>(DBUI_SaveQuery)", "save query" },
          { "u", "<cmd>DBUIToggle<CR>", "sidebar" },
          { "a", "<cmd>DBUIAddConnection<CR>", "add connection" },
          { "f", "<cmd>DBUIFindBuffer<CR>", "attach buffer to db" },
        },
        on_enter = function()
          vim.cmd("DBUI")
        end,
      })
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

  -- scratch playgrounds: throwaway buffer for the current filetype; <leader>r runs it
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>os", function() Snacks.scratch() end, desc = "Scratch (this filetype)" },
      { "<leader>oS", function() Snacks.scratch.select() end, desc = "Open a scratch" },
    },
  },
}
