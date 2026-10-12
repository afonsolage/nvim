local ensure_installed = {
	"rust",
	"diff",
	"c_sharp",
	"html",
	"javascript",
	"jsdoc",
	-- `jsonc` is gone on the `main` branch; the json parser covers it now.
	"json",
	"lua",
	"luadoc",
	"luap",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"regex",
	"toml",
	"vim",
	"vimdoc",
	"yaml",
	"wgsl",
	"wgsl_bevy",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		dependencies = {
			{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
		},
		cmd = { "TSUpdate", "TSInstall", "TSLog" },
		config = function()
			require("nvim-treesitter").setup()

			-- `main` has no `ensure_installed` option, so install what is missing by hand.
			local installed = require("nvim-treesitter.config").get_installed("parsers")
			local missing = vim.tbl_filter(function(lang)
				return not vim.tbl_contains(installed, lang)
			end, ensure_installed)
			if #missing > 0 then
				require("nvim-treesitter").install(missing)
			end

			-- `main` no longer wires highlight/indent for us.
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("afonsolage_treesitter", { clear = true }),
				callback = function(ev)
					local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
					if not lang or not pcall(vim.treesitter.language.add, lang) then
						return
					end
					pcall(vim.treesitter.start, ev.buf, lang)
					vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})

			require("nvim-treesitter-textobjects").setup({
				move = { set_jumps = true },
			})

			local move = require("nvim-treesitter-textobjects.move")
			local moves = {
				["]f"] = { move.goto_next_start, "@function.outer", "Next function start" },
				["]c"] = { move.goto_next_start, "@class.outer", "Next class start" },
				["]F"] = { move.goto_next_end, "@function.outer", "Next function end" },
				["]C"] = { move.goto_next_end, "@class.outer", "Next class end" },
				["[f"] = { move.goto_previous_start, "@function.outer", "Previous function start" },
				["[c"] = { move.goto_previous_start, "@class.outer", "Previous class start" },
				["[F"] = { move.goto_previous_end, "@function.outer", "Previous function end" },
				["[C"] = { move.goto_previous_end, "@class.outer", "Previous class end" },
			}
			for lhs, spec in pairs(moves) do
				local fn, capture, desc = spec[1], spec[2], spec[3]
				vim.keymap.set({ "n", "x", "o" }, lhs, function()
					fn(capture, "textobjects")
				end, { desc = desc })
			end
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-context",
		enabled = true,
		opts = { mode = "cursor", max_lines = 3 },
	},
}
