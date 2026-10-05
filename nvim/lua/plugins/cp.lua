-- Competitive programming keys (config/cp.lua). No plugin to install: a
-- virtual spec just lets lazy.nvim register the keys and load cp.lua on first use.
local function cp(fn)
  return function() require("config.cp")[fn]() end
end

return {
  {
    -- virtual: lazy needs a dir in the spec but never adds it to the rtp
    dir = vim.fn.stdpath("config"),
    name = "cp",
    virtual = true,
    keys = {
      { "<leader>jj", cp("test"), desc = "Run sample tests" },
      { "<leader>jl", cp("show_last"), desc = "Last test results" },
      { "<leader>ja", cp("add"), desc = "Add a test case" },
      { "<leader>js", cp("submit"), desc = "Copy solution + open problem" },
      { "<leader>jp", cp("problem"), desc = "Problem statement" },
    },
    cmd = { "CpTest" },
    config = function()
      vim.api.nvim_create_user_command("CpTest", function() require("config.cp").test() end, { desc = "Run sample tests" })
    end,
    init = function()
      -- Apple clang lacks <bits/stdc++.h>; cp-fetch writes one here. Via the env it
      -- reaches clangd and the <leader>r runner too, without touching their configs.
      local inc = vim.fn.expand("~/Desktop/code/dsa/include")
      local cur = vim.env.CPLUS_INCLUDE_PATH
      if not (cur or ""):find(inc, 1, true) then
        vim.env.CPLUS_INCLUDE_PATH = (cur and cur ~= "") and (inc .. ":" .. cur) or inc
      end
      -- which-key group label; editor.lua owns the main spec, so add it once UI is up
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          local ok, wk = pcall(require, "which-key")
          if ok then wk.add({ { "<leader>j", group = "judge (cp)", icon = "\u{f0ae} " } }) end
        end,
      })
    end,
  },
}
