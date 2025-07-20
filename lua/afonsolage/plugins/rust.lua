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
