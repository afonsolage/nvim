-- This file enables LSP servers that are handled by nvim native LSP manager.
-- Configs live in `lsp/<name>.lua`.

-- wgsl-analyzer is not packaged; install with
--   cargo install --git https://github.com/wgsl-analyzer/wgsl-analyzer wgsl-analyzer
-- Only enable it when the binary is actually around, otherwise every wgsl
-- buffer greets us with a "cmd not executable" error.
if vim.fn.executable("wgsl-analyzer") == 1 then
	vim.lsp.enable("wgsl_analyzer")
end
