-- <leader>r: run the current file or project in a bottom terminal.
-- Re-running replaces the previous run. If input.txt sits next to the file,
-- it is piped to stdin (handy for DSA / competitive programming).
local M = {}

local brew = vim.fn.isdirectory("/opt/homebrew/include") == 1 and "/opt/homebrew" or "/usr/local"
local term

local function q(s)
  return vim.fn.shellescape(s)
end

local function native(file, cpp)
  local root = vim.fs.root(0, "CMakeLists.txt")
  if root then
    return "cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON >/dev/null"
      .. " && cmake --build build -j"
      .. " && exe=$(find build -maxdepth 1 -type f -perm -u+x ! -name '*.dylib' ! -iname '*test*' | head -1)"
      .. ' && echo "── $exe" && "$exe"',
      root
  end
  local dir = vim.fn.fnamemodify(file, ":h")
  local out = dir .. "/build/" .. vim.fn.fnamemodify(file, ":t:r")
  local compile = table.concat({
    cpp and "clang++ -std=c++20" or "clang -std=c17",
    "-O2 -Wall -g",
    "-I" .. brew .. "/include -L" .. brew .. "/lib",
    q(file),
    "-o " .. q(out),
  }, " ")
  return "mkdir -p build && " .. compile .. " && " .. q(out), dir
end

local runners = {
  c = function(f) return native(f, false) end,
  cpp = function(f) return native(f, true) end,
  go = function() return "go run .", vim.fs.root(0, "go.mod") end,
  rust = function() return "cargo run", vim.fs.root(0, "Cargo.toml") end,
  python = function(f) return "python3 " .. q(f) end,
  javascript = function(f) return "node " .. q(f) end,
  typescript = function(f) return "npx --yes tsx " .. q(f) end,
  lua = function(f) return "nvim -l " .. q(f) end,
  sh = function(f) return "bash " .. q(f) end,
  zsh = function(f) return "zsh " .. q(f) end,
}

---@param with_args? boolean prompt for program arguments (remembered per project)
function M.run(with_args)
  if with_args then
    local key = vim.fs.root(0, { "CMakeLists.txt", "go.mod", "Cargo.toml" }) or vim.fn.expand("%:p")
    return require("config.args").ask(key, function(_, raw)
      if raw then
        M.exec(raw)
      end
    end)
  end
  M.exec()
end

---@param raw_args? string
function M.exec(raw_args)
  local runner = runners[vim.bo.filetype]
  if not runner then
    vim.notify("No runner for filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
    return
  end
  vim.cmd("silent! wall")
  local file = vim.fn.expand("%:p")
  local cmd, cwd = runner(file)
  cwd = cwd or vim.fn.fnamemodify(file, ":h")
  if raw_args and raw_args ~= "" then
    -- the program is always the last command in the chain, so args go at the end
    cmd = cmd .. " " .. raw_args
  end

  local input = vim.fn.fnamemodify(file, ":h") .. "/input.txt"
  local piped = vim.uv.fs_stat(input) ~= nil
  if piped then
    cmd = "(" .. cmd .. ") < " .. q(input)
  end

  if term and term:buf_valid() then
    term:close()
  end
  term = Snacks.terminal.open({ vim.o.shell, "-c", cmd }, {
    cwd = cwd,
    auto_close = false,
    -- focus the panel only when you need to type input; otherwise stay in the code
    interactive = not piped,
    start_insert = not piped,
    win = {
      position = "bottom",
      height = 0.3,
      enter = not piped,
      wo = { winbar = " \u{f04b} " .. vim.fn.fnamemodify(file, ":t") .. "   esc esc: normal mode · ctrl-k: back to code" },
    },
  })
end

return M
