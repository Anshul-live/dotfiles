-- Look & feel: colorscheme, snacks (picker, dashboard, notifications, ...), statusline
local header = [[
███╗   ██╗██╗   ██╗██╗███╗   ███╗
████╗  ██║██║   ██║██║████╗ ████║
██╔██╗ ██║██║   ██║██║██╔████╔██║
██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝]]

return {
  -- vague: muted, low-saturation colors. Syntax separates things without shouting;
  -- only errors/warnings are loud. Opaque background = no desktop behind your code.
  {
    "vague2k/vague.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("vague").setup({
        transparent = false,
        bold = true,
        italic = false, -- italics only on comments (below)
        on_highlights = function(hl, c)
          local p = { edge = c.comment, accent = c.keyword, faint = c.line, dim = c.comment }
          hl.Comment = { fg = c.comment, italic = true }
          hl.WinSeparator = { fg = p.edge }
          hl.CursorLineNr = { fg = p.accent, bold = true }
          hl.LineNr = { fg = c.line }
          hl.FloatBorder = { fg = p.edge, bg = c.bg }
          hl.NormalFloat = { fg = c.fg, bg = c.bg }
          hl.FloatTitle = { fg = p.accent, bold = true }
          hl.SnacksPickerBorder = { fg = p.edge }
          hl.SnacksInputBorder = { fg = p.edge }
          hl.SnacksWinSeparator = { fg = p.edge }
          hl.SnacksPickerTitle = { fg = p.accent, bold = true }
          hl.SnacksIndentScope = { fg = p.faint }
          hl.WhichKeyBorder = { fg = p.edge }
          hl.BlinkCmpMenuBorder = { fg = p.edge }
          hl.BlinkCmpDocBorder = { fg = p.edge }
          hl.BlinkCmpSignatureHelpBorder = { fg = p.edge }
          hl.DapUIFloatBorder = { fg = p.edge }
          hl.TreesitterContext = { bg = c.bg }
          hl.TreesitterContextBottom = { underline = true, sp = p.faint }
          hl.TreesitterContextLineNumber = { fg = c.line }
          hl.SnacksDashboardHeader = { fg = p.dim }
          hl.SnacksDashboardKey = { fg = p.accent, bold = true }
          hl.SnacksDashboardDesc = { fg = c.fg }
          hl.SnacksDashboardIcon = { fg = p.dim }
          hl.SnacksDashboardFooter = { fg = p.dim }
          hl.StatusLine = { fg = c.fg, bg = c.bg }
          hl.StatusLineNC = { fg = p.dim, bg = c.bg }
        end,
      })
      vim.cmd.colorscheme("vague")

      -- mode feedback where your eyes are: the cursor's line number takes the mode color
      local p = require("config.palette")
      local mode_colors = { n = p.normal, i = p.insert, v = p.visual, V = p.visual, ["\22"] = p.visual, s = p.visual, R = p.replace, c = p.command, t = p.terminal }
      vim.api.nvim_create_autocmd({ "ModeChanged", "ColorScheme" }, {
        callback = function()
          local color = mode_colors[vim.fn.mode():sub(1, 1)] or p.normal
          vim.api.nvim_set_hl(0, "CursorLineNr", { fg = color, bold = true })
        end,
      })
    end,
  },

  { "nvim-tree/nvim-web-devicons", lazy = true },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true }, -- disables heavy features on huge files
      quickfile = { enabled = true },
      input = { enabled = true },
      notifier = {
        enabled = true,
        style = "compact",
        timeout = 3000,
        -- background tool installs stay quiet unless they fail (progress is in :Mason)
        filter = function(n)
          return not (n.title == "mason-tool-installer" and n.level ~= vim.log.levels.ERROR and n.level ~= "error")
        end,
      },
      indent = { enabled = true, indent = { enabled = false }, animate = { enabled = false } }, -- one guide: current scope
      scope = { enabled = true },
      words = { enabled = true },
      lazygit = { enabled = true },
      terminal = { enabled = true },
      statuscolumn = { enabled = true, left = { "mark", "sign" }, right = { "git" } }, -- no fold column
      explorer = { enabled = true, replace_netrw = false },
      picker = {
        enabled = true,
        ui_select = true, -- every vim.ui.select menu uses the picker
        -- centered, one outer border, thin dividers (no nested boxes)
        layouts = {
          minimal = {
            layout = {
              box = "vertical",
              backdrop = false,
              width = 0.8,
              min_width = 80,
              height = 0.8,
              border = true,
              title = "{title} {live} {flags}",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              {
                box = "horizontal",
                { win = "list", border = "none" },
                { win = "preview", title = "{preview}", width = 0.55, border = "left" },
              },
            },
          },
        },
        layout = {
          cycle = true,
          preset = function()
            return vim.o.columns >= 100 and "minimal" or "vertical"
          end,
        },
        formatters = { file = { filename_first = true } },
        icons = { ui = { selected = "\u{f00c} ", unselected = "  " } },
        -- debug/run builds land in build/; keep their artifacts out of search
        exclude = { "*.dSYM", ".DS_Store" },
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
          explorer = { hidden = true },
        },
      },
      dashboard = {
        enabled = true,
        preset = {
          header = header,
          keys = {
            { icon = "\u{f002} ", key = "f", desc = "Find anything", action = ":lua Snacks.picker.smart({ filter = { cwd = true } })" },
            { icon = "\u{f0b0} ", key = "g", desc = "Grep text", action = ":lua Snacks.picker.grep()" },
            { icon = "\u{f1da} ", key = "r", desc = "Recent files", action = ":lua Snacks.picker.recent({ filter = { cwd = true } })" },
            { icon = "\u{f07c} ", key = "e", desc = "Explorer", action = ":lua Snacks.explorer()" },
            { icon = "\u{f15b} ", key = "n", desc = "New file", action = ":ene | startinsert" },
            { icon = "\u{f0e2} ", key = "s", desc = "Restore session", section = "session" },
            { icon = "\u{f013} ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
            { icon = "\u{f1b3} ", key = "l", desc = "Plugins", action = ":Lazy" },
            { icon = "\u{f011} ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 0, padding = 1 },
          { section = "startup" },
        },
      },
    },
    keys = {
      { "<leader>gg", function() Snacks.lazygit() end, desc = "LazyGit" },
      { "<leader>gl", function() Snacks.lazygit.log_file() end, desc = "LazyGit file log" },
      { "<leader>go", function() Snacks.gitbrowse() end, mode = { "n", "v" }, desc = "Open in browser" },
      { "<C-/>", function() Snacks.terminal() end, mode = { "n", "t" }, desc = "Toggle terminal" },
      { "<C-_>", function() Snacks.terminal() end, mode = { "n", "t" }, desc = "which_key_ignore" },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer" },
      { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Delete other buffers" },
      { "<leader>cF", function() Snacks.rename.rename_file() end, desc = "Rename file" },
      { "<leader>uN", function() Snacks.picker.notifications() end, desc = "Notification history" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss notifications" },
      { "<leader>uz", function() Snacks.zen() end, desc = "Zen mode" },
      { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference" },
      { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev reference" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          local toggle = Snacks.toggle
          toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          toggle.option("relativenumber", { name = "Relative number" }):map("<leader>ur")
          toggle.diagnostics():map("<leader>ud")
          toggle.inlay_hints():map("<leader>uh")
          toggle.treesitter():map("<leader>uT")
          toggle.indent():map("<leader>ui")
          toggle
            .new({
              id = "virtual_text",
              name = "Inline diagnostics (all lines)",
              get = function()
                local vt = vim.diagnostic.config().virtual_text
                return type(vt) == "table" and not vt.current_line
              end,
              set = function(on)
                vim.diagnostic.config({ virtual_text = { current_line = not on or nil } })
              end,
            })
            :map("<leader>uv")
          toggle
            .new({
              id = "autoformat",
              name = "Format on save",
              get = function()
                return not vim.g.disable_autoformat
              end,
              set = function(on)
                vim.g.disable_autoformat = not on
              end,
            })
            :map("<leader>uf")
          toggle
            .new({
              id = "autosave",
              name = "Autosave",
              get = function()
                return vim.g.autosave ~= false
              end,
              set = function(on)
                vim.g.autosave = on
              end,
            })
            :map("<leader>ua")
        end,
      })
      -- LSP-aware file renames from oil
      vim.api.nvim_create_autocmd("User", {
        pattern = "OilActionsPost",
        callback = function(ev)
          if ev.data.actions[1] and ev.data.actions[1].type == "move" then
            Snacks.rename.on_rename_file(ev.data.actions[1].src_url, ev.data.actions[1].dest_url)
          end
        end,
      })
    end,
  },

  -- statusline shows only what you might act on; mode lives on the cursor line number
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local p = require("config.palette")
      local plain = { a = { fg = p.fg, bg = p.bg }, b = { fg = p.fg, bg = p.bg }, c = { fg = p.dim, bg = p.bg } }
      local theme = { normal = plain, insert = plain, visual = plain, replace = plain, command = plain, terminal = plain, inactive = plain }

      local function breadcrumb()
        local ok, aerial = pcall(require, "aerial")
        if not ok then
          return ""
        end
        local loc = aerial.get_location(true)
        if type(loc) ~= "table" or #loc == 0 then
          return ""
        end
        local parts = {}
        for _, sym in ipairs(loc) do
          table.insert(parts, (sym.icon or "") .. sym.name)
        end
        return table.concat(parts, " \u{f105} ")
      end

      local function recording()
        local reg = vim.fn.reg_recording()
        return reg ~= "" and ("\u{f111} rec @" .. reg) or ""
      end

      -- pinned files (harpoon): "1 main  2 oa", current one highlighted
      local function pinned()
        local ok, harpoon = pcall(require, "harpoon")
        if not ok then
          return ""
        end
        local current = vim.fn.expand("%:p")
        local out = {}
        for i, item in ipairs(harpoon:list().items) do
          if i > 4 then
            break
          end
          local name = vim.fn.fnamemodify(item.value, ":t:r")
          local here = vim.fn.fnamemodify(item.value, ":p") == current
          table.insert(out, (here and "%#SnacksPickerTitle#" or "%#Comment#") .. i .. " " .. name .. "%*")
        end
        return table.concat(out, "  ")
      end

      -- warn when a code file that should have an LSP has none
      local lsp_fts
      local function no_lsp()
        if not lsp_fts then
          lsp_fts = {}
          for name in pairs(require("lang").map("servers")) do
            for _, ft in ipairs((vim.lsp.config[name] or {}).filetypes or {}) do
              lsp_fts[ft] = true
            end
          end
          lsp_fts.rust = true
        end
        if vim.bo.buftype == "" and lsp_fts[vim.bo.filetype] and #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
          return "\u{f071} no LSP"
        end
        return ""
      end

      require("lualine").setup({
        options = {
          theme = theme,
          section_separators = "",
          component_separators = "",
          globalstatus = true,
          disabled_filetypes = { statusline = { "snacks_dashboard" } },
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            { "filetype", icon_only = true, padding = { left = 1, right = 0 } },
            {
              "filename",
              path = 1,
              color = { fg = p.fg },
              symbols = { modified = "\u{f111}", readonly = "\u{f023}", unnamed = "", newfile = "" },
              fmt = function(name)
                return vim.bo.buftype == "terminal" and "terminal" or name
              end,
            },
            { breadcrumb, color = { fg = p.dim } },
          },
          lualine_x = {
            { recording, color = { fg = p.command } },
            { no_lsp, color = { fg = p.warn } },
            {
              "diagnostics",
              symbols = { error = "\u{f057} ", warn = "\u{f071} ", info = "\u{f05a} ", hint = "\u{f0335} " },
            },
            { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
            { pinned },
            { "branch", icon = "\u{e725}", color = { fg = p.dim } },
          },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { "oil", "lazy", "mason", "trouble", "nvim-dap-ui", "quickfix" },
      })

      vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
        callback = function()
          vim.schedule(require("lualine").refresh)
        end,
      })
    end,
  },
}
