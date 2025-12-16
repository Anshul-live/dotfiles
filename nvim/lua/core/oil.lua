require("oil").setup({
  -- DO NOT hijack netrw or symbols
  default_file_explorer = false,

  -- Minimal, readable
  columns = {
    "icon",
  },

  view_options = {
    show_hidden = true,
    natural_order = true,

    -- Hide noise, not information
    is_always_hidden = function(name)
      return name == ".git"
    end,
  },

  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,

  keymaps = {
    -- Navigation
    ["<CR>"] = "actions.select",

    -- Splits
    ["<C-v>"] = "actions.select_vsplit",
    ["<C-x>"] = "actions.select_split",
    ["<C-t>"] = "actions.select_tab",

    -- Context
    ["_"] = "actions.open_cwd",

    -- Control
    ["<C-l>"] = "actions.refresh",
    ["q"] = "actions.close",
    ["<Esc>"] = "actions.close",
  },
})

