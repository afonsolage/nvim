return {
    {
        'saecki/crates.nvim',
        event = { "BufRead Cargo.toml" },
        config = function()
            require('crates').setup()
        end,
    },
    {
        'mrcjkb/rustaceanvim',
        version = '^6', -- Recommended
        lazy = false, -- This plugin is already lazy
        ft = { "rust" },
        config = function()
            vim.g.rustaceanvim = {
                server = {
                    on_attach = function(client, bufrn)
                        local opts = { buffer = bufrn, remap = false }

                        vim.lsp.inlay_hint.enable(true)

                        vim.keymap.set("n", "<leader>vca", 
                        function()
                            vim.lsp.buf.code_action()
                        end, opts)
                        vim.keymap.set("n", "<leader>h", 
                        function()
                            local enabled = vim.lsp.inlay_hint.is_enabled()
                            vim.lsp.inlay_hint.enable(not enabled, opts)
                        end, opts)
                        vim.keymap.set("n", "<leader>vee",
                        function()
                            vim.cmd.RustLsp({'explainError', 'current'})
                        end, opts)
                       	vim.keymap.set("n", "gd", function()
                            vim.lsp.buf.definition()
                        end, opts)
                        vim.keymap.set("n", "<leader>vws", function()
                            vim.lsp.buf.workspace_symbol()
                        end, opts)
                        vim.keymap.set("n", "<leader>vd", function()
                            vim.diagnostic.open_float()
                        end, opts)
                        vim.keymap.set("n", "[d", function()
                            vim.diagnostic.goto_next()
                        end, opts)
                        vim.keymap.set("n", "]d", function()
                            vim.diagnostic.goto_prev()
                        end, opts)
                        vim.keymap.set("n", "<leader>vrr", function()
                            vim.lsp.buf.references()
                        end, opts)
                        vim.keymap.set("n", "<leader>vrn", function()
                            vim.lsp.buf.rename()
                        end, opts)
                        vim.keymap.set("i", "<C-h>", function()
                            vim.lsp.buf.signature_help()
                        end, opts) 
                        vim.keymap.set("n", "<leader>vme", function()
                            vim.cnd.RustLsp('expandMacro')
                        end, opts)

                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer = bufrn,
                            callback = function()
                                vim.lsp.buf.format({ async = false })
                            end
                        })

                    end,
                },
                settings = {
                    ["rust-analyzer"] = {
                        cargo = {
                            loadOutDirsFromCheck = true,
                            runBuildScripts = true,
                        },
                        checkOnSave = {
                            allFeatures = true,
                            command = "clippy",
                            extraArgs = { "--no-deps" },
                        },
                        procMacro = {
                            enable = true,
                            ignored = {
                                ["async-trait"] = { "async_trait" },
                                ["napi-derive"] = { "napi" },
                                ["async-recursion"] = { "async_recursion" },
                            },
                        },
                        inlayHints = {
                            enable = true,
                            showParameterNames = true,
                        },
                    }
                },
            }
        end,
    }
}
