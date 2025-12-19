-- =========================================================
-- File path component
-- =========================================================
local function file_path()
	local path = vim.fn.expand("%:~:.")

	if path == "" then
		return "[No File]"
	end

	local max_len = 40
	if #path > max_len then
		path = "…" .. path:sub(#path - max_len + 2)
	end

	return path
end

-- =========================================================
-- Symbol kind → icon fallback (used if Aerial icon missing)
-- =========================================================
local kind_icons = {
	Class = "󰠱 ",
	Function = "󰊕 ",
	Method = "󰆧 ",
	Constructor = "󰆧 ",
	Variable = "󰀫 ",
	Field = "󰜢 ",
	Property = "󰜢 ",
	Interface = " ",
	Module = "󰕳 ",
	Namespace = "󰦮 ",
	Struct = "󰆼 ",
	Enum = "󰕘 ",
}

-- =========================================================
-- Aerial breadcrumb component (icons + names)
-- =========================================================
local function aerial_breadcrumb()
	local ok, aerial = pcall(require, "aerial")
	if not ok then
		return ""
	end

	local loc = aerial.get_location(true)
	if type(loc) ~= "table" or #loc == 0 then
		return ""
	end

	local parts = {}

	for _, sym in ipairs(loc) do
		if type(sym) == "table" and sym.name then
			local icon = ""

			-- Prefer Aerial-provided icon
			if sym.icon and sym.icon ~= "" then
				icon = sym.icon
			-- Fallback to kind map
			elseif sym.kind and kind_icons[sym.kind] then
				icon = kind_icons[sym.kind]
			end

			table.insert(parts, icon .. sym.name)
		end
	end

	if #parts == 0 then
		return ""
	end

	return "› " .. table.concat(parts, " > ")
end

-- =========================================================
-- Lualine setup
-- =========================================================
require("lualine").setup({
	options = {
		theme = "auto",
		section_separators = "",
		component_separators = "",
		globalstatus = true,
	},

	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },

		lualine_c = {
			{ file_path },
			{ aerial_breadcrumb },
		},

		lualine_x = { "encoding", "diagnostics", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
})
