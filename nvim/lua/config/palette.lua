-- Semantic UI colors, derived from the colorscheme (vague).
-- Everything UI-side (statusline, mode color, borders) reads from here,
-- so swapping the theme means editing only this file.
local c = require("vague").get_palette()

return {
  bg = c.bg,
  fg = c.fg,
  dim = c.comment, -- secondary text: paths, breadcrumbs, branch
  faint = c.line, -- barely-there lines: indent scope, context underline
  edge = c.comment, -- window/float borders: slim but clearly visible
  accent = c.keyword, -- titles, focused things

  -- mode colors (cursor line number)
  normal = c.keyword,
  insert = c.plus,
  visual = c.parameter,
  replace = c.error,
  command = c.warning,
  terminal = c.builtin,

  -- extra modes (config/modes.lua): statusline badge, line number, cheat-sheet
  debug = c.error,
  test = c.plus,
  git = c.warning,
  ai = c.builtin,
  db = c.parameter,
  docker = c.hint,
  http = c.constant,

  warn = c.warning,
  error = c.error,
}
