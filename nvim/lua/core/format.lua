require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "ruff_format" },
		c = { "clang_format" },
		cpp = { "clang_format" },
		go = { "gofmt" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
	},

	format_on_save = {
		timeout_ms = 1000,
		lsp_fallback = false,
	},
})
