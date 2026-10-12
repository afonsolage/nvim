-- This file enables LSP servers that are handled by nvim native LSP manager.
-- Configs live in `lsp/<name>.lua`.

-- wgsl-analyzer (WGSL and WESL) is installed by mason, whose `init` puts its
-- bin dir on $PATH before this file runs. Only enable it when the binary is
-- actually around, otherwise every wgsl buffer greets us with a
-- "cmd not executable" error.
if vim.fn.executable("wgsl-analyzer") == 1 then
	vim.lsp.enable("wgsl_analyzer")
end
