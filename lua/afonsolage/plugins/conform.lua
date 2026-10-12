return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			ron = { "ronfmt" },
		},
		format_on_save = {
			-- I recommend these options. See :help conform.format for details.
			lsp_format = "fallback",
			timeout_ms = 500,
		},
		formatters = {
			ronfmt = {
				command = "ronfmt",
				args = "$FILENAME && rm $FILENAME.bak",
				stdin = false,
			},
		},
	},
}
