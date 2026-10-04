-- blink runs keymaps as expressions, so tabout is fed as a key afterwards
local function tabout(plug)
  require("tabout")
  vim.schedule(function()
    vim.api.nvim_feedkeys(vim.keycode(plug), "m", false)
  end)
  return true
end

return {
  {
    "saghen/blink.cmp",
    version = "1.*", -- downloads the prebuilt fuzzy matcher
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "enter", -- <CR> accept, <C-space> open, <C-e> close, <C-n>/<C-p> select
        ["<Tab>"] = {
          "select_next",
          "snippet_forward",
          function() -- jump out of brackets/quotes (or insert a tab)
            return tabout("<Plug>(Tabout)")
          end,
          "fallback",
        },
        ["<S-Tab>"] = {
          "select_prev",
          "snippet_backward",
          function()
            return tabout("<Plug>(TaboutBack)")
          end,
          "fallback",
        },
        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        list = { selection = { preselect = true, auto_insert = false } },
        menu = {
          border = "single",
          scrollbar = false,
          draw = {
            padding = { 0, 1 },
            treesitter = { "lsp" },
            columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
          },
        },
        documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "single", scrollbar = false } },
        ghost_text = { enabled = true }, -- preview the selected item inline
      },
      signature = { enabled = true, window = { border = "single", show_documentation = false } },
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          sql = { "dadbod", "snippets", "buffer" },
          mysql = { "dadbod", "snippets", "buffer" },
        },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
          dadbod = { name = "DB", module = "vim_dadbod_completion.blink" }, -- tables/columns in SQL
        },
      },
      cmdline = {
        completion = { menu = { auto_show = true } },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
  {
    "abecodes/tabout.nvim",
    lazy = true,
    opts = {
      tabkey = "", -- driven from blink's <Tab> above
      backwards_tabkey = "",
      act_as_tab = true,
      completion = false,
      tabouts = {
        { open = "'", close = "'" },
        { open = '"', close = '"' },
        { open = "`", close = "`" },
        { open = "(", close = ")" },
        { open = "[", close = "]" },
        { open = "{", close = "}" },
        { open = "<", close = ">" },
      },
      ignore_beginning = true,
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
  },
}
