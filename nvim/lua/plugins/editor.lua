return {
  -- keymap hints: press <leader> (or g, [, ], z, ") and wait
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
      -- centered popup, keys laid out in columns
      win = {
        width = { min = 60, max = 110 },
        height = { min = 4, max = 0.6 },
        col = 0.5,
        row = 0.5,
        border = "single",
        padding = { 1, 2 },
        title = true,
        title_pos = "center",
      },
      layout = { width = { min = 24, max = 40 }, spacing = 3 },
      icons = { separator = "\u{f178}", group = "", rules = false },
      spec = {
        { "<leader>a", group = "ai", icon = "\u{f086} ", mode = { "n", "v" } },
        { "<leader>b", group = "buffer", icon = "\u{f0db} " },
        { "<leader>c", group = "code", icon = "\u{f121} ", mode = { "n", "v" } },
        { "<leader>d", group = "debug", icon = "\u{f188} " },
        { "<leader>f", group = "find", icon = "\u{f002} " },
        { "<leader>g", group = "git", icon = "\u{f1d3} " },
        { "<leader>h", group = "hunks", icon = "\u{f126} ", mode = { "n", "v" } },
        { "<leader>p", group = "netrw", icon = "\u{f07c} " },
        { "<leader>o", group = "open", icon = "\u{f0e7} " },
        { "<leader>1", desc = "Pinned 1-4", icon = "\u{f08d} " },
        { "<leader>q", group = "session", icon = "\u{f0c7} " },
        { "<leader>s", group = "symbols", icon = "\u{f1b3} " },
        { "<leader>t", group = "test", icon = "\u{f0c3} " },
        { "<leader>u", group = "toggle", icon = "\u{f205} " },
        { "<leader>x", group = "lists", icon = "\u{f03a} " },
        { "gs", group = "surround" },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "z", group = "fold" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer keymaps",
      },
    },
  },

  -- fuzzy finding (snacks.picker, configured in ui.lua)
  {
    "folke/snacks.nvim",
    keys = {
      -- the one finder: open buffers + recent + project files, ranked by frecency
      { "<leader><space>", function() Snacks.picker.smart({ filter = { cwd = true } }) end, desc = "Find anything" },
      -- action palette: search every mapping by its description and run it
      {
        "<leader>;",
        function()
          Snacks.picker.keymaps({
            title = "Actions",
            layout = { preset = "select" },
            modes = { "n" },
            -- only named actions, searchable by name or key
            transform = function(item)
              local desc = item.item.desc
              if not desc or desc == "" or desc == "which_key_ignore" then
                return false
              end
              local prefix = item.item.lhs:match("^<Space>(%a)") or item.item.lhs:match("^ (%a)")
              item.group = ({
                a = "ai", b = "buffer", c = "code", d = "debug", f = "find", g = "git", h = "git",
                q = "session", s = "symbols", t = "test", u = "toggle", x = "lists",
              })[prefix or ""] or ""
              item.text = item.group .. " " .. desc .. " " .. item.item.lhs
            end,
            format = function(item)
              local key = item.item.lhs:gsub("<Space>", "\u{f1050} "):gsub("^ ", "\u{f1050} ")
              return { { ("%-8s"):format(item.group), "Comment" }, { ("%-40s"):format(item.item.desc) }, { key, "Special" } }
            end,
          })
        end,
        desc = "Action palette",
      },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Files" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Git files" },
      { "<leader>fr", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent files" },
      { "<leader>fe", function() Snacks.explorer() end, desc = "File tree" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fh", function() Snacks.picker.help() end, desc = "Help" },
      { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>fc", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>fw", function() Snacks.picker.grep_word() end, mode = { "n", "x" }, desc = "Grep word/selection" },
      { "<leader>f/", function() Snacks.picker.lines() end, desc = "Search in buffer" },
      { "<leader>fu", function() Snacks.picker.undo() end, desc = "Undo history" },
      { "<leader>fm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>fj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      { '<leader>f"', function() Snacks.picker.registers() end, desc = "Registers" },
      { "<leader>fq", function() Snacks.picker.qflist() end, desc = "Quickfix" },
      { "<leader>fR", function() Snacks.picker.resume() end, desc = "Resume last search" },
      { "<leader>fn", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Neovim config" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Live grep" },
      { "<leader>bb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "Document symbols" },
      { "<leader>sw", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Workspace symbols" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git status" },
      { "<leader>gc", function() Snacks.picker.git_log() end, desc = "Git commits" },
      { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "File commits" },
      { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git branches" },
    },
  },

  -- file explorer as an editable buffer
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      default_file_explorer = false,
      columns = { "icon" },
      view_options = {
        show_hidden = true,
        natural_order = true,
        is_always_hidden = function(name)
          return name == ".git"
        end,
      },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      lsp_file_methods = { enabled = true, autosave_changes = true }, -- update imports on rename
      win_options = { signcolumn = "no", statuscolumn = "" },
      float = { padding = 0, max_width = 0.6, max_height = 0.7 },
      confirmation = { border = "single" },
      -- g? inside oil shows all of these
      keymaps = {
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-x>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["_"] = "actions.open_cwd",
        ["g."] = "actions.toggle_hidden",
        ["gr"] = "actions.refresh",
        ["q"] = "actions.close",
        ["<Esc>"] = "actions.close",
        -- keep <C-h>/<C-l> for window/tmux navigation
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-s>"] = false,
        ["<C-c>"] = false,
      },
    },
  },

  -- pin up to 4 working files: <leader>m pins, <leader>1..4 jumps, <leader>M edits the list
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { settings = { save_on_toggle = true, sync_on_ui_close = true } },
    keys = function()
      local keys = {
        {
          "<leader>m",
          function()
            require("harpoon"):list():add()
            vim.notify("Pinned " .. vim.fn.expand("%:t"))
          end,
          desc = "Pin file",
        },
        {
          "<leader>M",
          function()
            local h = require("harpoon")
            h.ui:toggle_quick_menu(h:list(), { border = "single", title = " pinned ", title_pos = "center", ui_width_ratio = 0.4 })
          end,
          desc = "Pinned files",
        },
      }
      for i = 1, 4 do
        table.insert(keys, {
          "<leader>" .. i,
          function()
            require("harpoon"):list():select(i)
          end,
          desc = "which_key_ignore",
        })
      end
      return keys
    end,
  },

  -- jump anywhere
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter search" },
      { "<C-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle flash search" },
    },
  },

  -- surround: gsa (add), gsd (delete), gsr (replace) — e.g. gsaiw" , gsd( , gsr'"
  {
    "echasnovski/mini.surround",
    keys = { { "gs", mode = { "n", "x" }, desc = "Surround" } },
    opts = {
      mappings = {
        add = "gsa", delete = "gsd", find = "gsf", find_left = "gsF",
        highlight = "gsh", replace = "gsr", update_n_lines = "gsn",
      },
    },
  },

  -- symbols outline + statusline breadcrumbs
  {
    "stevearc/aerial.nvim",
    event = "LspAttach",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>so", "<cmd>AerialToggle<CR>", desc = "Symbols outline" },
      { "<leader>sn", "<cmd>AerialNext<CR>", desc = "Next symbol" },
      { "<leader>sp", "<cmd>AerialPrev<CR>", desc = "Prev symbol" },
    },
    opts = {
      attach_mode = "global",
      layout = { max_width = { 40 }, min_width = 30 },
      backends = { "lsp", "treesitter" },
      show_guides = true,
      filter_kind = false,
      highlight_on_hover = true,
      autojump = true,
    },
  },

  -- TODO/FIXME/HACK/NOTE highlighting
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
      { "<leader>ft", function() Snacks.picker.todo_comments() end, desc = "TODOs" },
      { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "TODOs (Trouble)" },
    },
  },

  -- diagnostics / references / quickfix lists
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = { focus = true, auto_preview = false },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Workspace diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<CR>", desc = "Symbols" },
      { "<leader>xl", "<cmd>Trouble lsp toggle win.position=right<CR>", desc = "LSP defs/refs" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix (Trouble)" },
    },
  },

  -- sessions: `nvim` in a project folder reopens your files/splits from last time.
  -- (no session yet -> dashboard; `nvim file` -> just that file)
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("StdinReadPre", {
        callback = function()
          vim.g.started_with_stdin = true
        end,
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        nested = true,
        callback = function()
          if vim.fn.argc(-1) > 0 or vim.g.started_with_stdin then
            return
          end
          local persistence = require("persistence")
          if vim.uv.fs_stat(persistence.current()) then
            persistence.load()
          end
        end,
      })
    end,
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session (cwd)" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Select session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save this session" },
    },
  },

  -- seamless <C-h/j/k/l> between nvim splits and tmux panes
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>" },
    },
  },

  { "ThePrimeagen/vim-be-good", cmd = "VimBeGood" },
}
