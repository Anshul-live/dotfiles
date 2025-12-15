local function aerial_component()
  local ok, aerial = pcall(require, "aerial")
  if not ok then
    return ""
  end

  local loc = aerial.get_location(true)
  if type(loc) == "table" then
    return #loc > 0 and table.concat(loc, " > ") or ""
  end

  return loc or ""
end

local function aerial_cond()
  local ok, aerial = pcall(require, "aerial")
  if not ok then
    return false
  end

  local loc = aerial.get_location(true)
  if type(loc) == "table" then
    return #loc > 0
  end

  return loc ~= nil and loc ~= ""
end

require("lualine").setup({
  options = {
    theme = "auto",
    section_separators = "",
    component_separators = "",
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = {
      "filename",
      {
        aerial_component,
        cond = aerial_cond,
      },
    },
    lualine_x = { "diagnostics" },
    lualine_y = {},
    lualine_z = { "location" },
  },
})

