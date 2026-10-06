-- Competitive programming. Problems live in ~/Desktop/code/dsa (a git repo):
--   <judge>/<set>/<id>-<slug>/   main.cpp + tests/N.in|out + problem.md   (bin/cp-fetch)
--   leetcode/<0932.slug>/        solution.cpp + testcases.txt + question.md (leetgo via bin/lc)
-- and each has plan.md (frontmatter + the plan) and sketch.excalidraw.md (Obsidian).
--
-- :CpOpen lays a problem out as  statement | code  with plan.md under the
-- statement, and enters CP mode (<leader>j, keys in plugins/cp.lua). Running
-- Codeforces/CSES/AtCoder samples is done here (async, results in a float);
-- LeetCode test/submit runs `lc` into a bottom output split. An Accepted submit
-- marks plan.md solved and commits + pushes the folder (bin/cp-index).
--
-- <leader>r (config/run.lua) is untouched: it still runs the file interactively.
local M = {}

local ROOT = vim.fn.expand(vim.env.CP_ROOT or "~/Desktop/code/dsa")
local VAULT, VAULT_DIR = "Devlogs", vim.fn.expand("~/Documents/Devlogs")
local VAULT_LINK = "DSA/Solutions" -- symlink to ROOT inside the vault (install.sh)
local LC_CACHE = vim.fn.expand("~/.config/leetgo/cache/leetcode-questions.json")

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
  if #list == 0 then return vim.notify("cp: tests/ has no .in files (n in CP mode adds one)", vim.log.levels.WARN) end
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

-- ── problem folders ──────────────────────────────────────────────────────────

local function exists(p) return vim.uv.fs_stat(p) ~= nil end

---Problem folder holding `path` (plan.md, testcases.txt or tests/ marks one).
local function folder(path)
  path = path or vim.api.nvim_buf_get_name(0)
  local dir = path ~= "" and (vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)) or vim.uv.cwd()
  return vim.fs.root(dir, function(name, p)
    return name == "plan.md" or name == "testcases.txt"
      or (name == "tests" and vim.fn.isdirectory(p .. "/tests") == 1)
  end)
end

local function is_lc(root) return exists(root .. "/testcases.txt") end

local function files(root)
  local function first(...)
    for _, n in ipairs({ ... }) do
      if exists(root .. "/" .. n) then return root .. "/" .. n end
    end
  end
  return {
    src = first("solution.cpp", "main.cpp"),
    statement = first("question.md", "problem.md"),
    plan = first("plan.md"),
  }
end

local function meta(root)
  local m = {}
  local text = read(root .. "/plan.md") or ""
  for line in (text:match("^%-%-%-\n(.-)\n%-%-%-") or ""):gmatch("[^\n]+") do
    local k, v = line:match("^(%w+):%s*(.-)%s*$")
    if k then m[k] = v:gsub('^"(.*)"$', "%1") end
  end
  if not m.id then m.id = (vim.fs.basename(root):match("^0*(%d+)")) end
  m.url = m.url or (read(root .. "/problem.md") or ""):match("https?://%S+")
  return m
end

---The plan nudge: which of approach / complexity are still blank.
local function plan_gaps(root)
  local text = read(root .. "/plan.md")
  if not text then return {} end
  local function section(h)
    local body = text:match("\n## " .. h .. "[^\n]*\n(.-)\n## ") or ""
    return (body:gsub("Time:", ""):gsub("Space:", ""):gsub("[%s%-`]", ""))
  end
  local gaps = {}
  if section("Approach") == "" then table.insert(gaps, "approach") end
  if section("Complexity") == "" then table.insert(gaps, "complexity") end
  return gaps
end

local function nudge(root)
  local gaps = plan_gaps(root)
  if #gaps > 0 then
    vim.notify(("cp: plan first: %s still empty in plan.md (2 to jump there)"):format(table.concat(gaps, " and ")),
      vim.log.levels.WARN)
  end
end

local function current()
  local root = folder()
  if not root then vim.notify("cp: not in a problem folder (p pick, f fetch, b browse)", vim.log.levels.WARN) end
  return root
end

-- ── output split (LeetCode runs) ─────────────────────────────────────────────

local out_buf

local function output(cmd, done)
  vim.cmd("silent! wall")
  if not (out_buf and vim.api.nvim_buf_is_valid(out_buf)) then
    out_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[out_buf].bufhidden = "hide"
    vim.api.nvim_buf_set_name(out_buf, "cp://output")
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = out_buf, nowait = true, silent = true })
    vim.api.nvim_buf_call(out_buf, function()
      vim.cmd([[syntax match CpPass /\v(Accepted|Passed|✔).*/]])
      vim.cmd([[syntax match CpFail /\v(Wrong Answer|Wrong answer|Runtime Error|Compile Error|Failed|Error|✘).*/]])
      vim.cmd([[syntax match CpTle /\v(Time Limit Exceeded|Memory Limit Exceeded).*/]])
      vim.cmd([[syntax match CpDim /^\$ .*/]])
    end)
  end
  local win = vim.fn.bufwinid(out_buf)
  if win == -1 then
    local cur = vim.api.nvim_get_current_win()
    vim.cmd("botright " .. math.max(10, math.floor(vim.o.lines / 3)) .. "split")
    vim.api.nvim_win_set_buf(0, out_buf)
    win = vim.api.nvim_get_current_win()
    vim.wo[win].number, vim.wo[win].relativenumber, vim.wo[win].signcolumn = false, false, "no"
    vim.wo[win].wrap, vim.wo[win].winfixheight = true, true
    vim.api.nvim_set_current_win(cur)
  end
  local head = { "$ " .. table.concat(cmd, " "), "" }
  vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, vim.list_extend(vim.deepcopy(head), { "running…" }))
  local acc = ""
  local function render(tail)
    local lines = vim.split(acc:gsub("\27%[[%d;?]*[A-Za-z]", ""):gsub("\r", ""), "\n", { plain = true })
    if tail then vim.list_extend(lines, tail) end
    vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, vim.list_extend(vim.deepcopy(head), lines))
    local w = vim.fn.bufwinid(out_buf)
    if w ~= -1 then vim.api.nvim_win_set_cursor(w, { vim.api.nvim_buf_line_count(out_buf), 0 }) end
  end
  local function on_data(_, data)
    if data then vim.schedule(function() acc = acc .. data; render() end) end
  end
  vim.system(cmd, { text = true, env = { NO_COLOR = "1" }, stdout = on_data, stderr = on_data },
    vim.schedule_wrap(function(r)
      render({ "", ("[exit %d]"):format(r.code) })
      if done then done(r.code, acc) end
    end))
end

-- ── actions (CP mode keys) ───────────────────────────────────────────────────

function M.run_tests()
  local root = current()
  if not root then return end
  nudge(root)
  if is_lc(root) then
    output({ "lc", "test", meta(root).id, "-L" })
  else
    M.test({ root = root, src = files(root).src })
  end
end

function M.run_remote()
  local root = current()
  if not root then return end
  if not is_lc(root) then return vim.notify("cp: only LeetCode runs tests remotely; t runs the samples", vim.log.levels.INFO) end
  output({ "lc", "test", meta(root).id, "-R" })
end

local function set_status(root, status)
  vim.system({ "cp-index", "status", root, status }, { text = true }, vim.schedule_wrap(function(r)
    local msg = vim.trim((r.stdout or "") .. (r.stderr or ""))
    vim.notify(msg ~= "" and msg or ("cp-index exited %d"):format(r.code), r.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
    for _, b in ipairs(vim.api.nvim_list_bufs()) do -- plan.md was rewritten on disk
      if vim.api.nvim_buf_get_name(b) == root .. "/plan.md" and not vim.bo[b].modified then
        vim.api.nvim_buf_call(b, function() vim.cmd("silent! checktime") end)
      end
    end
  end))
end

function M.judge_submit()
  local root = current()
  if not root then return end
  nudge(root)
  if not is_lc(root) then
    M.submit() -- copy + open the problem page; S once it's accepted
    return vim.notify("cp: submit in the browser, then S marks it solved", vim.log.levels.INFO)
  end
  output({ "lc", "submit", meta(root).id }, function(_, text)
    if text:find("Accepted") then
      set_status(root, "solved")
    elseif text:find("Wrong Answer") or text:find("Exceeded") or text:find("Error") then
      if meta(root).status == "todo" then set_status(root, "attempted") end
    end
  end)
end

function M.mark_solved()
  local root = current()
  if root then set_status(root, "solved") end
end

function M.new_test()
  local root = current()
  if not root then return end
  if not is_lc(root) then return M.add() end
  -- leetgo's format: "input:\n<args, one per line>\noutput:\n<expected>" blocks
  vim.cmd("botright split " .. vim.fn.fnameescape(root .. "/testcases.txt"))
  local n = vim.api.nvim_buf_line_count(0)
  local last = vim.api.nvim_buf_get_lines(0, n - 1, n, false)[1]
  local block = { "input:", "", "output:", "" }
  if last ~= "" then table.insert(block, 1, "") end
  vim.api.nvim_buf_set_lines(0, n, n, false, block)
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0) - 2, 0 })
end

local function focus(path)
  if not path then return end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)) == path then
      return vim.api.nvim_set_current_win(w)
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.jump(which)
  local root = current()
  if root then focus(files(root)[which]) end
end

local function urlencode(s)
  return (s:gsub("[^%w%-_%.~]", function(ch) return ("%%%02X"):format(ch:byte()) end))
end

function M.sketch()
  local root = current()
  if not root then return end
  if not exists(VAULT_DIR .. "/" .. VAULT_LINK) then
    return vim.notify(("cp: %s/%s missing (install.sh links it to %s)"):format(VAULT_DIR, VAULT_LINK, ROOT), vim.log.levels.WARN)
  end
  local rel = root:sub(#ROOT + 2)
  vim.ui.open(("obsidian://open?vault=%s&file=%s"):format(VAULT, urlencode(VAULT_LINK .. "/" .. rel .. "/sketch.excalidraw.md")))
end

function M.web()
  local root = current()
  local url = root and meta(root).url
  if not url then return root and vim.notify("cp: no URL in plan.md", vim.log.levels.WARN) end
  if vim.fn.executable("qb") == 1 then vim.system({ "qb", url }, { detach = true }) else vim.ui.open(url) end
end

-- ── layout ───────────────────────────────────────────────────────────────────

---Open a problem: statement on the left with plan.md under it, code on the right.
function M.open(dir)
  local root = folder(dir and vim.fn.fnamemodify(dir, ":p") or nil)
  if not root then return vim.notify("cp: no problem folder at " .. (dir or vim.uv.cwd()), vim.log.levels.WARN) end
  local f = files(root)
  if not f.src then return vim.notify("cp: no solution.cpp / main.cpp in " .. root, vim.log.levels.WARN) end
  -- reuse a tab that only shows this file or an empty buffer (nvim +CpOpen file), else a new tab
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local name = vim.api.nvim_buf_get_name(0)
  if #wins == 1 and (name == f.src or (name == "" and not vim.bo.modified)) then
    vim.cmd("edit " .. vim.fn.fnameescape(f.src))
  else
    vim.cmd("tabnew " .. vim.fn.fnameescape(f.src))
  end
  vim.cmd("tcd " .. vim.fn.fnameescape(root))
  local code = vim.api.nvim_get_current_win()
  local plan_win
  if f.statement then
    vim.cmd("topleft vsplit " .. vim.fn.fnameescape(f.statement))
    vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.42))
    vim.wo.wrap, vim.wo.linebreak, vim.wo.number, vim.wo.relativenumber = true, true, false, false
    if f.plan then
      vim.cmd("belowright split " .. vim.fn.fnameescape(f.plan))
      vim.wo.wrap, vim.wo.linebreak = true, true
      plan_win = vim.api.nvim_get_current_win()
    end
  end
  -- the nudge: an empty plan gets the cursor, a filled one hands it to the code
  local gaps = plan_gaps(root)
  vim.api.nvim_set_current_win((#gaps > 0 and plan_win) or code)
  if #gaps > 0 and plan_win then
    local l = vim.fn.search("^## Approach", "nw")
    if l > 0 then vim.api.nvim_win_set_cursor(plan_win, { l + 1, 0 }) end
  end
  require("config.modes").enter("cp", { auto = true })
  nudge(root)
end

-- ── pickers ──────────────────────────────────────────────────────────────────

local DIFF_HL = { Easy = "CpPass", Medium = "CpTle", Hard = "CpFail" }
local STATUS = { solved = { "✓", "CpPass" }, attempted = { "~", "CpTle" }, todo = { "·", "CpDim" } }

local function index()
  local r = vim.system({ "cp-index", "--json" }, { text = true }):wait()
  local ok, list = pcall(vim.json.decode, r.stdout or "")
  return ok and list or {}
end

---Run cp-fetch for `url` (no tmux), then open the folder here.
function M.fetch(url)
  if not url then
    local clip = vim.fn.getreg("+")
    vim.ui.input({ prompt = "Problem URL: ", default = clip:match("^https?://%S+$") and clip or "" }, function(u)
      if u and u ~= "" then M.fetch(u) end
    end)
    return
  end
  vim.notify("cp: fetching " .. url)
  vim.system({ "cp-fetch", url, "--no-open" }, { text = true }, vim.schedule_wrap(function(r)
    local out = vim.trim((r.stdout or "") .. (r.stderr or ""))
    local dir = out:match("→ (%S+)")
    if r.code ~= 0 or not dir then return vim.notify(out, vim.log.levels.ERROR) end
    M.open(vim.fn.expand(dir))
  end))
end

---Every LeetCode problem (leetgo's cache), local status marked; Enter fetches and opens it.
function M.pick()
  local f = io.open(LC_CACHE, "r")
  if not f then return vim.notify("cp: no leetgo cache yet; run `lc cache update`", vim.log.levels.WARN) end
  local ok, qs = pcall(vim.json.decode, f:read("*a"))
  f:close()
  if not ok then return vim.notify("cp: can't read " .. LC_CACHE, vim.log.levels.ERROR) end
  local mine = {}
  for _, p in ipairs(index()) do
    if p.judge == "leetcode" then mine[p.id] = p end
  end
  local items = {}
  for _, q in ipairs(qs) do
    local id = q.questionFrontendId
    local p = mine[id]
    table.insert(items, {
      text = ("%s %s %s %s"):format(id, q.title, q.difficulty, q.titleSlug),
      id = id, title = q.title, slug = q.titleSlug, diff = q.difficulty, paid = q.isPaidOnly,
      status = p and p.status, dir = p and p.dir, n = tonumber(id) or 0,
    })
  end
  table.sort(items, function(a, b) return a.n < b.n end)
  Snacks.picker({
    title = "LeetCode",
    items = items,
    layout = { preset = "select", preview = false },
    format = function(item)
      local s = STATUS[item.status] or { " ", "CpDim" }
      return {
        { s[1] .. " ", s[2] },
        { ("%5s  "):format(item.id), "CpDim" },
        { item.title .. (item.paid and " $" or "") .. "  ", item.paid and "CpDim" or nil },
        { item.diff, DIFF_HL[item.diff] },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      if item.dir then return M.open(item.dir) end
      M.fetch("https://leetcode.com/problems/" .. item.slug .. "/")
    end,
  })
end

---My problems (every plan.md), newest first; preview is the plan.
function M.browse()
  local items = {}
  for _, p in ipairs(index()) do
    local tags = type(p.tags) == "table" and table.concat(p.tags, ", ") or ""
    table.insert(items, {
      text = ("%s %s %s %s %s %s"):format(p.status, p.judge, p.id, p.title, p.difficulty or "", tags),
      file = p.dir .. "/plan.md", p = p, tags = tags,
    })
  end
  if #items == 0 then return vim.notify("cp: no problems in " .. ROOT .. " yet (p / f)", vim.log.levels.INFO) end
  Snacks.picker({
    title = "Solutions",
    items = items,
    format = function(item)
      local p, s = item.p, STATUS[item.p.status] or STATUS.todo
      return {
        { s[1] .. " ", s[2] },
        { ("%-10s "):format(p.judge), "CpDim" },
        { ("%s. %s  "):format(p.id, p.title) },
        { (p.difficulty or "") .. "  ", DIFF_HL[p.difficulty] },
        { item.tags, "CpDim" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then M.open(item.p.dir) end
    end,
  })
end

return M
