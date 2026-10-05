-- Notes: the Obsidian vault ~/Documents/Devlogs, written here (the Obsidian app is only
-- for the graph view). capture -> Inbox/ -> topic notes -> cards -> `cards review`.
-- Everything sits under <leader>k ("knowledge"; <leader>n is the per-project scratch).
-- Cards are callouts inside notes, see cards/README.md; `cards` is bin/cards.

local vault = vim.fn.expand("~/Documents/Devlogs")
-- templates live in the dotfiles (cards/templates), not the vault, so they're versioned
local templates = vim.fs.normalize(vim.fn.resolve(vim.fn.stdpath("config")) .. "/../cards/templates")

-- one-line capture into Inbox/capture.md without leaving the current buffer
local function capture()
  vim.ui.input({ prompt = "capture: " }, function(text)
    if not text or vim.trim(text) == "" then
      return
    end
    local file = vault .. "/Inbox/capture.md"
    vim.fn.mkdir(vault .. "/Inbox", "p")
    local new = vim.fn.filereadable(file) == 0
    local f = assert(io.open(file, "a"))
    if new then
      f:write("# Capture\n\nTriage into notes, then delete the line.\n\n")
    end
    f:write(("- %s %s\n"):format(os.date("%Y-%m-%d %H:%M"), vim.trim(text)))
    f:close()
    vim.cmd.checktime() -- refresh it if it's open somewhere
    vim.notify("captured", vim.log.levels.INFO, { title = "notes" })
  end)
end

-- insert a card callout below the cursor; in visual mode the selection becomes the card
-- (first line = front, the rest = back)
local function card(kind)
  return function()
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
      local s, e = vim.fn.line("v"), vim.fn.line(".")
      if s > e then
        s, e = e, s
      end
      vim.cmd("normal! \27") -- leave visual mode
      local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
      local out = { ("> [!%s] %s"):format(kind, lines[1]) }
      for i = 2, #lines do
        table.insert(out, lines[i] == "" and ">" or "> " .. lines[i])
      end
      vim.api.nvim_buf_set_lines(0, s - 1, e, false, out)
      return
    end
    local row = vim.fn.line(".")
    local head = ("> [!%s] "):format(kind)
    vim.api.nvim_buf_set_lines(0, row, row, false, { "", head, "> " })
    vim.api.nvim_win_set_cursor(0, { row + 2, #head })
    vim.cmd.startinsert({ bang = true })
  end
end

-- wrap the visual selection in {{cN::...}}, N = one more than the highest in the callout
local function cloze()
  vim.cmd("normal! \27")
  local s, e = vim.api.nvim_buf_get_mark(0, "<"), vim.api.nvim_buf_get_mark(0, ">")
  if s[1] ~= e[1] then
    return vim.notify("select within one line", vim.log.levels.WARN, { title = "cloze" })
  end
  local top, bot = s[1], s[1]
  while top > 1 and vim.fn.getline(top - 1):match("^>") do
    top = top - 1
  end
  while bot < vim.fn.line("$") and vim.fn.getline(bot + 1):match("^>") do
    bot = bot + 1
  end
  local n = 0
  for _, l in ipairs(vim.api.nvim_buf_get_lines(0, top - 1, bot, false)) do
    for d in l:gmatch("{{c(%d+)::") do
      n = math.max(n, tonumber(d))
    end
  end
  local line = vim.fn.getline(s[1])
  local last = math.min(e[2] + 1, #line) -- '> col is 0-based and may be past the end ($)
  -- extend to the end of a multibyte char
  last = last + #vim.fn.strcharpart(line:sub(last), 0, 1) - 1
  local new = line:sub(1, s[2]) .. ("{{c%d::%s}}"):format(n + 1, line:sub(s[2] + 1, last)) .. line:sub(last + 1)
  vim.api.nvim_buf_set_lines(0, s[1] - 1, s[1], false, { new })
end

-- `cards` in a float (review needs a real terminal for single-key answers)
local function cards(args)
  return function()
    Snacks.terminal("cards " .. args, {
      interactive = true,
      win = { position = "float", width = 0.7, height = 0.8, border = "single", title = " cards ", title_pos = "center" },
    })
  end
end

-- add/update the cards of the current note in the background
local function push_note()
  local file = vim.api.nvim_buf_get_name(0)
  if not vim.startswith(file, vault .. "/") then
    return vim.notify("not a vault note", vim.log.levels.WARN, { title = "cards" })
  end
  vim.cmd.update()
  vim.system({ "cards", "push", file }, { text = true }, function(r)
    vim.schedule(function()
      local out = vim.trim((r.stdout or "") .. (r.stderr or ""))
      vim.notify(out ~= "" and out or "done", r.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN, { title = "cards" })
      vim.cmd.checktime() -- pick up the anki:<id> markers it wrote
    end)
  end)
end

local K = "<leader>k"

return {
  {
    "obsidian-nvim/obsidian.nvim", -- maintained fork of epwalsh/obsidian.nvim
    version = "*",
    -- load for vault notes, or on any <leader>k key from elsewhere
    event = { "BufReadPre " .. vault .. "/*.md", "BufNewFile " .. vault .. "/*.md" },
    cmd = "Obsidian",
    keys = {
      { K .. "n", "<cmd>Obsidian new<CR>", desc = "New note (Inbox)" },
      { K .. "N", "<cmd>Obsidian new_from_template<CR>", desc = "New note from template" },
      { K .. "c", capture, desc = "Quick capture" },
      { K .. "d", "<cmd>Obsidian today<CR>", desc = "Today's daily note" },
      { K .. "y", "<cmd>Obsidian yesterday<CR>", desc = "Yesterday's daily note" },
      { K .. "D", "<cmd>Obsidian dailies<CR>", desc = "Daily notes" },
      { K .. "f", "<cmd>Obsidian quick_switch<CR>", desc = "Find note" },
      { K .. "s", "<cmd>Obsidian search<CR>", desc = "Search notes" },
      { K .. "b", "<cmd>Obsidian backlinks<CR>", desc = "Backlinks" },
      { K .. "l", "<cmd>Obsidian links<CR>", desc = "Links in note" },
      { K .. "t", "<cmd>Obsidian tags<CR>", desc = "Tags" },
      { K .. "T", "<cmd>Obsidian template<CR>", desc = "Insert template" },
      { K .. "x", "<cmd>Obsidian toggle_checkbox<CR>", desc = "Toggle checkbox" },
      { K .. "e", "<cmd>Obsidian extract_note<CR>", mode = "x", desc = "Extract to new note" },
      { K .. "r", "<cmd>Obsidian rename<CR>", desc = "Rename note (updates links)" },
      { K .. "o", "<cmd>Obsidian open<CR>", desc = "Open in Obsidian (graph)" },
      -- cards (spaced repetition)
      { K .. "a", card("card"), mode = { "n", "x" }, desc = "Add card" },
      { K .. "z", card("cloze"), desc = "Add cloze card" },
      { K .. "z", cloze, mode = "x", desc = "Cloze selection" },
      { K .. "p", push_note, desc = "Push this note's cards" },
      { K .. "S", cards("sync"), desc = "Sync cards + AnkiWeb" },
      { K .. "R", cards("review"), desc = "Review cards" },
      {
        K .. "i",
        function()
          vim.system({ "cards", "stats" }, { text = true }, function(r)
            vim.schedule(function()
              vim.notify(vim.trim(r.stdout .. r.stderr), vim.log.levels.INFO, { title = "cards" })
            end)
          end)
        end,
        desc = "Card stats",
      },
    },
    opts = {
      legacy_commands = false, -- only `:Obsidian <sub>`
      workspaces = { { name = "devlogs", path = vault } },
      log_level = vim.log.levels.WARN,
      -- new notes go to Inbox/ (triage later) with readable names: "Segment Tree" -> segment-tree.md
      new_notes_location = "notes_subdir",
      notes_subdir = "Inbox",
      note_id_func = function(title, dir)
        return require("obsidian.builtin").title_id(title, dir)
      end,
      note = { template = "topic.md" },
      templates = { folder = templates, date_format = "YYYY-MM-DD", time_format = "HH:mm" },
      daily_notes = {
        folder = "Daily",
        date_format = "YYYY-MM-DD",
        template = "daily.md",
        default_tags = { "daily" },
        workdays_only = false, -- weekends count too
      },
      -- the templates write the frontmatter; don't let the plugin rewrite it on every save
      frontmatter = { enabled = false },
      picker = { name = "snacks.picker" },
      checkbox = { order = { " ", "x" } },
      footer = { enabled = false },
      -- render-markdown (lang/data.lua) draws the buffer; two concealers fight
      ui = { enable = false },
      -- completion ([[links, #tags) comes from the plugin's in-process LSP, which
      -- blink.cmp's "lsp" source already picks up: nothing to wire
    },
  },

  -- render the card callouts (render-markdown itself is set up in lang/data.lua)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      callout = {
        card = { raw = "[!card]", rendered = "󰘸 Card", highlight = "RenderMarkdownHint", category = "cards" },
        cloze = { raw = "[!cloze]", rendered = "󰘸 Cloze", highlight = "RenderMarkdownHint", category = "cards" },
      },
    },
  },

  -- label the group in the which-key popup (its spec list lives in editor.lua)
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { K, group = "notes", icon = "\u{f0219} ", mode = { "n", "x" } })
    end,
  },
}
