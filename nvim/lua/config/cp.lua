-- Competitive programming: run a problem's sample tests (folders made by
-- bin/cp-fetch: main.cpp + tests/N.in / N.out). Async; the editor never waits.
--
--   <leader>jj  compile once, run every test, show ✓/✗/TLE/RE in a float
--   <leader>jl  reopen the last results
--   <leader>ja  add a test case (tests/N.in + N.out in a split)
--   <leader>js  submit: copy the solution, open the problem page
--   <leader>jp  read problem.md
--
-- <leader>r (config/run.lua) is untouched: it still runs the file interactively.
local M = {}

local TIMEOUT = 2000 -- ms per test; well above typical 1-2s limits on -O2
local SHOW = 20 -- lines of input / expected / got shown per failed test
local brew = vim.fn.isdirectory("/opt/homebrew/include") == 1 and "/opt/homebrew" or "/usr/local"
-- sanitizers turn silent UB / out-of-bounds into an RE with a stack trace
local FLAGS = {
  "-std=c++20", "-O2", "-g", "-Wall", "-Wextra", "-Wshadow",
  "-fsanitize=address,undefined", "-DLOCAL", "-I" .. brew .. "/include",
}

local c = { bg = "#141415", fg = "#cdcdcd", raised = "#252530", dim = "#606079",
  red = "#d8647e", green = "#7fa563", yellow = "#f3be7c", blue = "#6e94b2" }
local function set_hl()
  local hl = function(n, o) vim.api.nvim_set_hl(0, n, o) end
  hl("CpNormal", { fg = c.fg, bg = c.bg })
  hl("CpBorder", { fg = c.dim, bg = c.bg })
  hl("CpTitle", { fg = c.blue, bg = c.bg, bold = true })
  hl("CpPass", { fg = c.green, bold = true })
  hl("CpFail", { fg = c.red, bold = true })
  hl("CpTle", { fg = c.yellow, bold = true })
  hl("CpDim", { fg = c.dim })
  hl("CpHead", { fg = c.blue, bg = c.raised, bold = true })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

local busy, last, win = false, nil, nil

local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

---Problem folder (has tests/) for the current buffer, and the source to build.
local function problem()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
  local root = vim.fs.root(dir, function(name, path)
    return name == "tests" and vim.fn.isdirectory(path .. "/tests") == 1
  end)
  if not root then return nil end
  local src = (vim.bo.filetype == "cpp" and vim.fs.dirname(file) == root) and file or root .. "/main.cpp"
  return root, src
end

local function tests(root)
  local list = {}
  for _, p in ipairs(vim.fn.glob(root .. "/tests/*.in", false, true)) do
    local name = vim.fn.fnamemodify(p, ":t:r")
    table.insert(list, { name = name, inp = p, out = p:sub(1, -4) .. ".out" })
  end
  table.sort(list, function(a, b)
    local na, nb = tonumber(a.name), tonumber(b.name)
    if na and nb then return na < nb end
    return a.name < b.name
  end)
  return list
end

-- whitespace-insensitive; numbers with a decimal point match within 1e-6
local function same(got, want)
  local a, b = vim.split(vim.trim(got), "%s+"), vim.split(vim.trim(want), "%s+")
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i] ~= b[i] then
      local x, y = tonumber(a[i]), tonumber(b[i])
      if not (x and y and (a[i]:find("%.") or b[i]:find("%."))
          and math.abs(x - y) <= 1e-6 * math.max(1, math.abs(y))) then
        return false
      end
    end
  end
  return true
end

-- ── results float ────────────────────────────────────────────────────────────

local ICON = { AC = "✓", WA = "✗", TLE = "⏱", RE = "!", ["?"] = "?" }
local HL = { AC = "CpPass", WA = "CpFail", TLE = "CpTle", RE = "CpFail", ["?"] = "CpDim" }

local function clip(text, width)
  local out = {}
  local lines = vim.split((text or ""):gsub("\n$", ""), "\n", { plain = true })
  for i, l in ipairs(lines) do
    if i > SHOW then
      table.insert(out, ("… %d more lines"):format(#lines - SHOW))
      break
    end
    l = l:gsub("\t", "  ")
    if vim.fn.strdisplaywidth(l) > width then
      l = vim.fn.strcharpart(l, 0, width - 1) .. "…"
    end
    table.insert(out, l)
  end
  return out
end

local function close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
end

local function show(res)
  close()
  local W = math.min(110, vim.o.columns - 4)
  local lines, marks, at = {}, {}, {}
  local function add(text, hl, from, to)
    table.insert(lines, text)
    if hl then table.insert(marks, { #lines - 1, from or 0, to or #text, hl }) end
  end

  local passed = 0
  for _, r in ipairs(res.results) do
    if r.status == "AC" then passed = passed + 1 end
    local head = (" %s  %-4s %6s  %s"):format(ICON[r.status], r.name, r.ms .. "ms", r.status ~= "AC" and r.status or "")
    add(head, HL[r.status], 0, #(" " .. ICON[r.status]))
    table.insert(marks, { #lines - 1, #(" " .. ICON[r.status] .. "  " .. ("%-4s"):format(r.name)), #head, "CpDim" })
    at[#lines] = r
  end

  local half = math.floor((W - 3) / 2)
  for _, r in ipairs(res.results) do
    if r.status ~= "AC" then
      add("")
      add((" test %s · %s"):format(r.name, r.status) .. string.rep(" ", W), "CpHead")
      at[#lines] = r
      add(" input", "CpDim")
      for _, l in ipairs(clip(r.input, W - 2)) do add(" " .. l) end
      if r.status == "RE" or r.status == "TLE" or r.want == nil then
        add(" output", "CpDim")
        for _, l in ipairs(clip(r.got, W - 2)) do add(" " .. l) end
        if r.err ~= "" then
          add(" stderr", "CpDim")
          for _, l in ipairs(clip(r.err, W - 2)) do add(" " .. l, "CpFail") end
        end
      else
        -- expected | got side by side, so the first differing line is easy to spot
        add((" %-" .. half .. "s │ %s"):format("expected", "got"), "CpDim")
        local e, g = clip(r.want, half - 1), clip(r.got, half - 1)
        for i = 1, math.max(#e, #g) do
          local el, gl = e[i] or "", g[i] or ""
          local pad = half - vim.fn.strdisplaywidth(el)
          local left = " " .. el .. string.rep(" ", pad) .. " │ "
          add(left .. gl, el ~= gl and "CpFail" or nil, #left, #left + #gl)
        end
        if r.err ~= "" then
          add(" stderr", "CpDim")
          for _, l in ipairs(clip(r.err, W - 2)) do add(" " .. l, "CpDim") end
        end
      end
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ns = vim.api.nvim_create_namespace("cp")
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = math.min(m[3], #lines[m[1] + 1]), hl_group = m[4] })
  end
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local all = passed == #res.results
  local H = math.min(#lines, vim.o.lines - 6)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - H) / 2) - 1,
    col = math.floor((vim.o.columns - W) / 2),
    width = W,
    height = H,
    style = "minimal",
    border = "single",
    title = { { (" %s  %d/%d passed "):format(vim.fn.fnamemodify(res.src, ":t"), passed, #res.results), all and "CpPass" or "CpFail" } },
    title_pos = "center",
    footer = { { " q close · r rerun · a add test · ⏎ open test ", "CpDim" } },
    footer_pos = "center",
  })
  vim.wo[win].winhighlight = "Normal:CpNormal,FloatBorder:CpBorder"
  vim.wo[win].cursorline = true
  local o = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", close, o)
  vim.keymap.set("n", "<Esc>", close, o)
  vim.keymap.set("n", "r", function() close() M.test() end, o)
  vim.keymap.set("n", "a", function() close() M.add() end, o)
  vim.keymap.set("n", "<CR>", function()
    local r = at[vim.api.nvim_win_get_cursor(0)[1]]
    if r then
      close()
      M.open_test(r.inp, r.inp:sub(1, -4) .. ".out")
    end
  end, o)
end

-- ── running ──────────────────────────────────────────────────────────────────

local function compile(src, bin, done)
  local s, b = vim.uv.fs_stat(src), vim.uv.fs_stat(bin)
  if s and b and (b.mtime.sec > s.mtime.sec or (b.mtime.sec == s.mtime.sec and b.mtime.nsec >= s.mtime.nsec)) then
    return done(true) -- binary is newer than the source: skip the slow sanitizer build
  end
  vim.fn.mkdir(vim.fs.dirname(bin), "p")
  local cmd = vim.list_extend({ "clang++" }, FLAGS)
  -- <bits/stdc++.h> stand-in that cp-fetch drops in <dsa>/include
  for dir in vim.fs.parents(src) do
    if vim.uv.fs_stat(dir .. "/include/bits/stdc++.h") then
      table.insert(cmd, "-I" .. dir .. "/include")
      break
    end
  end
  vim.list_extend(cmd, { src, "-o", bin })
  vim.system(cmd, { text = true }, vim.schedule_wrap(function(r)
    if r.code == 0 then
      -- macOS scans a brand-new binary on first exec (~0.5s); pay that here, not in test 1
      return vim.system({ bin }, { stdin = "", timeout = 1000 }, vim.schedule_wrap(function() done(true) end))
    end
    vim.fn.setqflist({}, " ", {
      title = "cp: compile " .. vim.fn.fnamemodify(src, ":t"),
      lines = vim.split(r.stderr or "", "\n"),
      efm = "%f:%l:%c: fatal %trror: %m,%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%-G%.%#",
    })
    vim.cmd("botright copen")
    done(false)
  end))
end

local function run_one(bin, root, t, done)
  local input = read(t.inp) or ""
  local want = read(t.out)
  local start = vim.uv.hrtime()
  vim.system({ bin }, {
    cwd = root,
    stdin = input,
    text = true,
    timeout = TIMEOUT,
    -- leaks aren't bugs here; the nano-zone line is macOS ASan noise on stderr
    env = { ASAN_OPTIONS = "detect_leaks=0", MallocNanoZone = "0" },
  }, function(r)
    local ms = math.floor((vim.uv.hrtime() - start) / 1e6)
    local status
    -- vim.system kills on timeout and reports 124 (signal is 9 or 15 by version)
    if (r.code == 124 and r.signal ~= 0) or ms >= TIMEOUT then
      status = "TLE"
    elseif r.code ~= 0 or r.signal ~= 0 then
      status = "RE"
    elseif want == nil then
      status = "?"
    else
      status = same(r.stdout or "", want) and "AC" or "WA"
    end
    done({ name = t.name, inp = t.inp, status = status, ms = ms, input = input, want = want,
      got = r.stdout or "", err = vim.trim(r.stderr or "") })
  end)
end

---Compile and run all tests. opts.on_done(res) gets the results; opts.quiet skips the float.
---@param opts? { on_done?: fun(res: table), quiet?: boolean, root?: string, src?: string }
function M.test(opts)
  opts = opts or {}
  if busy then return vim.notify("cp: tests already running", vim.log.levels.WARN) end
  local root, src = opts.root, opts.src
  if not root then root, src = problem() end
  src = src or (root and root .. "/main.cpp")
  if not root then return vim.notify("cp: no tests/ folder here", vim.log.levels.WARN) end
  local list = tests(root)
  if #list == 0 then return vim.notify("cp: tests/ has no .in files (<leader>ja adds one)", vim.log.levels.WARN) end
  vim.cmd("silent! wall")
  busy = true
  local bin = root .. "/build/" .. vim.fn.fnamemodify(src, ":t:r")
  local ok_start, err = pcall(compile, src, bin, function(ok)
    if not ok then
      busy = false
      vim.notify("cp: compile failed (quickfix)", vim.log.levels.ERROR)
      if opts.on_done then opts.on_done({ compile_error = true, results = {} }) end
      return
    end
    local results, i = {}, 0
    local function next_test()
      i = i + 1
      if i > #list then
        busy = false
        last = { src = src, results = results }
        local passed = #vim.tbl_filter(function(r) return r.status == "AC" end, results)
        if not opts.quiet then
          show(last)
        end
        vim.notify(("cp: %d/%d passed"):format(passed, #results),
          passed == #results and vim.log.levels.INFO or vim.log.levels.WARN)
        if opts.on_done then opts.on_done(last) end
        return
      end
      run_one(bin, root, list[i], vim.schedule_wrap(function(r)
        table.insert(results, r)
        next_test()
      end))
    end
    next_test()
  end)
  if not ok_start then -- e.g. clang++ missing: don't stay "busy" forever
    busy = false
    vim.notify("cp: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.show_last()
  if not last then return vim.notify("cp: no results yet", vim.log.levels.INFO) end
  show(last)
end

function M.open_test(inp, out)
  vim.cmd("botright split " .. vim.fn.fnameescape(inp))
  vim.cmd("resize " .. math.max(8, math.floor(vim.o.lines / 3)))
  vim.cmd("vsplit " .. vim.fn.fnameescape(out))
  vim.cmd("wincmd h")
end

function M.add()
  local root = problem()
  if not root then
    -- a fresh folder becomes a problem folder by adding its first test
    root = vim.fn.expand("%:p:h")
  end
  vim.fn.mkdir(root .. "/tests", "p")
  local n = 0
  for _, t in ipairs(tests(root)) do
    n = math.max(n, tonumber(t.name) or 0)
  end
  M.open_test(("%s/tests/%d.in"):format(root, n + 1), ("%s/tests/%d.out"):format(root, n + 1))
end

function M.submit()
  local root, src = problem()
  root = root or vim.fn.expand("%:p:h")
  if not src or vim.uv.fs_stat(src) == nil then
    src = vim.fn.filereadable(root .. "/solution.cpp") == 1 and root .. "/solution.cpp" or vim.fn.expand("%:p")
  end
  vim.cmd("silent! wall")
  local code = read(src)
  if not code then return vim.notify("cp: nothing to copy", vim.log.levels.WARN) end
  vim.fn.setreg("+", code)
  local url = (read(root .. "/problem.md") or ""):match("https?://%S+")
  if url then
    if vim.fn.executable("qb") == 1 then
      vim.system({ "qb", url }, { detach = true })
    else
      vim.ui.open(url)
    end
  end
  vim.notify(("cp: copied %s%s"):format(vim.fn.fnamemodify(src, ":t"), url and ", opened the problem" or ""))
end

function M.problem()
  local root = problem() or vim.fn.expand("%:p:h")
  local md = root .. "/problem.md"
  if vim.fn.filereadable(md) == 0 then return vim.notify("cp: no problem.md", vim.log.levels.WARN) end
  vim.cmd("tabedit " .. vim.fn.fnameescape(md))
  vim.wo.wrap, vim.wo.linebreak = true, true
end

return M
