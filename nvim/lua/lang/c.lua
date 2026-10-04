-- C / C++
-- clangd reads compile_commands.json from the project root or build/.
-- CMake projects: run :CMakeGen once (and after adding files/deps).
-- Without one, clangd falls back to Homebrew's include path (boost, fmt, ...).
local brew = vim.fn.isdirectory("/opt/homebrew/include") == 1 and "/opt/homebrew" or "/usr/local"

return {
  setup = function()
    vim.api.nvim_create_user_command("CMakeGen", function()
      vim.notify("cmake: generating build/compile_commands.json ...")
      vim.system(
        { "cmake", "-S", ".", "-B", "build", "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", "-DCMAKE_BUILD_TYPE=Debug" },
        { text = true },
        vim.schedule_wrap(function(res)
          if res.code ~= 0 then
            vim.notify(res.stderr, vim.log.levels.ERROR, { title = "cmake" })
            return
          end
          vim.notify("compile_commands.json ready, restarting clangd")
          vim.cmd("lsp restart clangd")
        end)
      )
    end, { desc = "Generate compile_commands.json with CMake (Debug)" })
  end,
  requires = { { "clang++", "xcode-select --install" }, { "cmake", "brew install cmake" } },
  parsers = { "c", "cpp", "cmake", "make", "doxygen" },
  tools = { "clangd", "clang-format", "codelldb", "neocmakelsp" },
  servers = {
    clangd = {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--header-insertion=iwyu",
        "--function-arg-placeholders=true",
        "--fallback-style=llvm",
        "--log=error",
      },
      init_options = {
        clangdFileStatus = true,
        -- used only when the project has no compile_commands.json
        fallbackFlags = { "-I" .. brew .. "/include", "-Iinclude", "-I../include" },
      },
    },
    neocmake = {},
  },
  formatters = {
    c = { "clang_format" },
    cpp = { "clang_format" },
  },
  dap = function(dap)
    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = { command = "codelldb", args = { "--port", "${port}" } },
    }
    -- run a command without freezing the UI (dap evaluates config functions in a coroutine)
    local function run(cmd, cwd)
      local co = coroutine.running()
      if not co then
        return vim.system(cmd, { cwd = cwd, text = true }):wait()
      end
      vim.system(cmd, { cwd = cwd, text = true }, function(res)
        vim.schedule(function()
          coroutine.resume(co, res)
        end)
      end)
      return coroutine.yield()
    end

    local function fail(title, res)
      vim.notify((res.stderr ~= "" and res.stderr or res.stdout), vim.log.levels.ERROR, { title = title })
      return dap.ABORT
    end

    local function pick(items, prompt)
      if #items <= 1 then
        return items[1]
      end
      local co = coroutine.running()
      vim.ui.select(items, { prompt = prompt, format_item = function(p) return vim.fn.fnamemodify(p, ":t") end }, function(choice)
        coroutine.resume(co, choice)
      end)
      return coroutine.yield()
    end

    local function cmake_root()
      return vim.fs.root(0, "CMakeLists.txt")
    end

    -- CMake project: Debug build of the whole project, then launch its executable.
    -- Single file: compile it (with Homebrew headers/libs) into build/<name>.
    local function build()
      local root = cmake_root()
      if root then
        vim.notify("cmake: building (Debug) ...", vim.log.levels.INFO, { title = "debug" })
        local res = run({ "cmake", "-S", ".", "-B", "build", "-DCMAKE_BUILD_TYPE=Debug", "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" }, root)
        if res.code ~= 0 then
          return fail("cmake configure failed", res)
        end
        res = run({ "cmake", "--build", "build", "-j" }, root)
        if res.code ~= 0 then
          return fail("cmake build failed", res)
        end
        local exes = {}
        for name, kind in vim.fs.dir(root .. "/build") do
          local path = root .. "/build/" .. name
          if kind == "file" and vim.fn.executable(path) == 1 and not name:match("%.dylib$") then
            table.insert(exes, path)
          end
        end
        if #exes == 0 then
          vim.notify("no executable found in build/", vim.log.levels.ERROR, { title = "debug" })
          return dap.ABORT
        end
        -- prefer the real program over test binaries; only ask when still ambiguous
        local main = vim.tbl_filter(function(p)
          return not vim.fn.fnamemodify(p, ":t"):lower():match("test")
        end, exes)
        return pick(#main > 0 and main or exes, "Executable to debug")
      end

      local file = vim.fn.expand("%:p")
      local cpp = vim.bo.filetype == "cpp"
      local out = vim.fn.expand("%:p:h") .. "/build/" .. vim.fn.expand("%:t:r")
      vim.fn.mkdir(vim.fn.fnamemodify(out, ":h"), "p")
      local res = run({
        cpp and "clang++" or "clang", "-g", "-O0", cpp and "-std=c++20" or "-std=c17",
        "-I" .. brew .. "/include", "-L" .. brew .. "/lib", file, "-o", out,
      })
      if res.code ~= 0 then
        return fail("build failed", res)
      end
      return out
    end

    -- arguments prompt, prefilled with the last ones used in this project/file
    local function args()
      local list = require("config.args").ask(cmake_root() or vim.fn.expand("%:p"))
      return list or dap.ABORT
    end

    local configs = {
      {
        name = "Build & debug (CMake project or current file)",
        type = "codelldb",
        request = "launch",
        program = build,
        args = args,
        cwd = function()
          return cmake_root() or vim.fn.expand("%:p:h")
        end,
        terminal = "integrated", -- program I/O (cin/scanf) in the debug console
      },
      {
        name = "Launch executable",
        type = "codelldb",
        request = "launch",
        program = function()
          return require("dap.utils").pick_file({ executables = true })
        end,
        args = args,
        cwd = "${workspaceFolder}",
        terminal = "integrated",
      },
      {
        name = "Attach to process",
        type = "codelldb",
        request = "attach",
        pid = function()
          return require("dap.utils").pick_process()
        end,
        cwd = "${workspaceFolder}",
      },
    }
    dap.configurations.c = configs
    dap.configurations.cpp = configs
  end,
  tests = function()
    return { require("neotest-gtest").setup({}) }
  end,
  plugins = {
    { "alfaix/neotest-gtest", lazy = true },
  },
}
