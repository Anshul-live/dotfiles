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

-- a request starts with its method line; the request "at the cursor" is the nearest one above
local methods = { GET = 1, POST = 1, PUT = 1, PATCH = 1, DELETE = 1, HEAD = 1, OPTIONS = 1 }
local function request_at_cursor()
  for l = vim.fn.line("."), 1, -1 do
    local word = (vim.fn.getline(l):match("^%s*(%u+)%s+%S") or "")
    if methods[word] then
      return true
    end
  end
  return false
end

-- Run a Hurl command from the .hurl file even when the cursor is in the response split
-- (which takes focus when it opens), then hand focus back so the next `s` works too.
-- at_cursor: the command sends the request under the cursor, so check there is one first
-- (hurl.nvim's own message is hidden by show_notification = false).
local function hurl(cmd, at_cursor)
  return function()
    local win = vim.api.nvim_get_current_win()
    if vim.bo.filetype ~= "hurl" then
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "hurl" then
          win = w
          break
        end
      end
      vim.api.nvim_set_current_win(win)
    end
    if vim.bo.filetype ~= "hurl" then
      return vim.notify("no .hurl file in this tab", vim.log.levels.WARN)
    end
    if at_cursor and not request_at_cursor() then
      return vim.notify(
        "No request at the cursor. A request starts with a method line, e.g.\n  GET http://localhost:3000/health",
        vim.log.levels.WARN,
        { title = "hurl" }
      )
    end
    vim.cmd(cmd)
    -- the response split opens (and takes focus) when the request finishes
    local id = vim.api.nvim_create_autocmd("WinEnter", {
      once = true,
      callback = function()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_set_current_win(win)
          end
        end)
      end,
    })
    vim.defer_fn(function() -- no response window (e.g. the request failed): don't hijack a later WinEnter
      pcall(vim.api.nvim_del_autocmd, id)
    end, 30000)
  end
end

local function toggle_response_layout()
  vim.cmd("HurlToggleMode")
  vim.notify("responses now open in a " .. _HURL_GLOBAL_CONFIG.mode, vim.log.levels.INFO, { title = "hurl" })
end

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
          { "s", hurl("HurlRunnerAt", true), "send request" },
          { "a", hurl("HurlRunner"), "send all" },
          { "v", hurl("HurlVerbose", true), "send verbose" },
          { "m", toggle_response_layout, "split / popup" },
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
      auto_close = false, -- keep the response open while the cursor is back in the .hurl file
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
        map("<CR>", hurl("HurlRunnerAt", true), "Send request")
        map("<leader>r", hurl("HurlRunnerAt", true), "Send request")
        require("config.hurl_cmp").attach(buf) -- completion menu after [ {{ Header: query
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
