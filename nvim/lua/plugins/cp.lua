-- Competitive programming: CP mode (config/modes.lua) over config/cp.lua.
-- No plugin to install: a virtual spec just lets lazy.nvim register :CpOpen/:CpTest
-- and load cp.lua on first use.
--
--   <leader>j   CP mode (entered by itself when a problem opens: cp-fetch, p, f, b)
--   :CpOpen     lay out the problem in the current folder (cp-fetch starts nvim with it)
local function cp(fn, ...)
  local args = { ... }
  return function() require("config.cp")[fn](unpack(args)) end
end

return {
  {
    -- virtual: lazy needs a dir in the spec but never adds it to the rtp
    dir = vim.fn.stdpath("config"),
    name = "cp",
    virtual = true,
    cmd = { "CpTest", "CpOpen" },
    config = function()
      vim.api.nvim_create_user_command("CpTest", function() require("config.cp").run_tests() end, { desc = "Run sample tests" })
      vim.api.nvim_create_user_command("CpOpen", function(o)
        require("config.cp").open(o.args ~= "" and o.args or nil)
      end, { nargs = "?", complete = "dir", desc = "Open a CP problem layout" })
    end,
    init = function()
      -- Apple clang lacks <bits/stdc++.h>; cp-fetch writes one here. Via the env it
      -- reaches clangd and the <leader>r runner too, without touching their configs.
      local inc = vim.fn.expand("~/Desktop/code/dsa/include")
      local cur = vim.env.CPLUS_INCLUDE_PATH
      if not (cur or ""):find(inc, 1, true) then
        vim.env.CPLUS_INCLUDE_PATH = (cur and cur ~= "") and (inc .. ":" .. cur) or inc
      end
      -- i a o c and hjkl stay free: the mode is on while you read and plan, and
      -- editing the plan or code must not need leaving it first
      require("config.modes").define("cp", {
        key = "<leader>j",
        desc = "pick, test, submit problems; plan + sketch first",
        keys = {
          { "t", cp("run_tests"), "test (local)" },
          { "T", cp("run_remote"), "test on LeetCode" },
          { "s", cp("judge_submit"), "submit" },
          { "S", cp("mark_solved"), "mark solved + push" },
          { "n", cp("new_test"), "new test case" },
          { "r", cp("show_last"), "last results" },
          { "p", cp("pick"), "pick LeetCode" },
          { "f", cp("fetch"), "fetch URL" },
          { "b", cp("browse"), "browse solutions" },
          { "1", cp("jump", "statement"), "statement" },
          { "2", cp("jump", "plan"), "plan" },
          { "3", cp("jump", "src"), "code" },
          { "d", cp("sketch"), "draw (Obsidian)" },
          { "w", cp("web"), "open in browser" },
        },
      })
    end,
  },
}
