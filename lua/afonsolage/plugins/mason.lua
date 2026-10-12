return {
	{
		-- mason.nvim moved from williamboman/ to mason-org/ on the 2.0 release.
		"mason-org/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		-- `init` runs on startup even while the plugin itself stays lazy, so tools
		-- like stylua/shfmt are on $PATH for conform without loading mason.
		init = function()
			vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
		end,
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
				"codelldb",
				"wgsl-analyzer",
			},
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					-- trigger FileType event to possibly load this newly installed LSP server
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local ok, p = pcall(mr.get_package, tool)
					if ok and not p:is_installed() then
						p:install()
					end
				end
			end
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
	},
}
