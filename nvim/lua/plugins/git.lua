return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    init = function()
      local function gs()
        return require("gitsigns")
      end
      local function selection()
        return { vim.fn.line("."), vim.fn.line("v") }
      end
      local function hunk(dir)
        return function()
          if vim.wo.diff then
            vim.cmd.normal({ dir == "next" and "]c" or "[c", bang = true })
          else
            gs().nav_hunk(dir)
          end
        end
      end
      require("config.modes").define("git", {
        key = "<leader>g",
        desc = "hunks, staging, blame, diffs, lazygit",
        keys = {
          { "n", hunk("next"), "next hunk" },
          { "N", hunk("prev"), "prev hunk" },
          { "s", function() gs().stage_hunk() end, "stage / unstage hunk" },
          { "s", function() gs().stage_hunk(selection()) end, "stage selection", mode = "x" },
          { "r", function() gs().reset_hunk() end, "reset hunk" },
          { "r", function() gs().reset_hunk(selection()) end, "reset selection", mode = "x" },
          { "S", function() gs().stage_buffer() end, "stage file" },
          { "R", function() gs().reset_buffer() end, "reset file" },
          { "p", function() gs().preview_hunk() end, "preview hunk" },
          { "b", function() gs().blame_line({ full = true }) end, "blame line" },
          { "B", function() gs().blame() end, "blame file" },
          { "d", function() gs().diffthis() end, "diff this file" },
          {
            "D",
            function()
              vim.cmd(require("diffview.lib").get_current_view() and "DiffviewClose" or "DiffviewOpen")
            end,
            "repo diff view",
          },
          { "h", "<cmd>DiffviewFileHistory %<CR>", "file history" },
          { "L", function() Snacks.lazygit() end, "lazygit" },
        },
      })
    end,
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "\u{f0da}" },
        topdelete = { text = "\u{f0da}" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "\u{f0da}" },
        topdelete = { text = "\u{f0da}" },
        changedelete = { text = "▎" },
      },
      preview_config = { border = "single" },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end

        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev hunk")

        map("n", "<leader>ub", gs.toggle_current_line_blame, "Toggle inline blame")
        map({ "o", "x" }, "ih", gs.select_hunk, "Inside hunk")
      end,
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    opts = { enhanced_diff_hl = true },
  },
}
