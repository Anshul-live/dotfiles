-- Test runner. Adapters come from lua/lang/*.lua.
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    init = function()
      local function nt()
        return require("neotest")
      end
      require("config.modes").define("test", {
        key = "<leader>t",
        desc = "run, debug and inspect tests",
        keys = {
          { "t", function() nt().run.run() end, "nearest test" },
          { "f", function() nt().run.run(vim.fn.expand("%")) end, "this file" },
          { "a", function() nt().run.run(vim.uv.cwd()) end, "all tests" },
          { "l", function() nt().run.run_last() end, "run last" },
          { "d", function() nt().run.run({ strategy = "dap" }) end, "debug nearest" },
          { "x", function() nt().run.stop() end, "stop" },
          { "w", function() nt().watch.toggle(vim.fn.expand("%")) end, "watch file" },
          { "s", function() nt().summary.toggle() end, "summary" },
          { "o", function() nt().output.open({ enter = true, auto_close = true }) end, "output" },
          { "O", function() nt().output_panel.toggle() end, "output panel" },
          { "n", function() nt().jump.next({ status = "failed" }) end, "next failed" },
          { "N", function() nt().jump.prev({ status = "failed" }) end, "prev failed" },
        },
      })
    end,
    keys = {
      { "]T", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
      { "[T", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev failed test" },
    },
    config = function()
      require("neotest").setup({
        adapters = require("lang").each("tests"),
        status = { virtual_text = true },
        output = { open_on_run = true },
      })
    end,
  },
}
