return {
    {
        "mfussenegger/nvim-dap",
        -- stylua: ignore
        keys = {
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
            { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
            { "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
            { "<leader>dj", function() require("dap").down() end, desc = "Down" },
            { "<leader>dk", function() require("dap").up() end, desc = "Up" },
            { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
            { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
            { "<leader>ds", function() require("dap").session() end, desc = "Session" },
            { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
            { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },

            { "<F5>", function() require("dap").continue() end, desc = "Continue" },
            { "<F6>", function() require("dap").step_into() end, desc = "Step Into" },
            { "<F7>", function() require("dap").step_out() end, desc = "Step Out" },
            { "<F8>", function() require("dap").step_over() end, desc = "Step Over" },
        },
        dependencies = { "nvim-neotest/nvim-nio" },
    },
    { 
        "rcarriga/nvim-dap-ui", 
        dependencies = { "mfussenegger/nvim-dap" },
        keys = {
            { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
            { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
        },
        opts = {},
        config = function(_, opts)
            -- setup dap config by VsCode launch.json file
            -- require("dap.ext.vscode").load_launchjs()
            local dap = require("dap")
            local dapui = require("dapui")
            dapui.setup(opts)
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open({})
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close({})
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close({})
            end
        end,
    },
    -- virtual text for the debugger
    {
        "theHamsta/nvim-dap-virtual-text",
        dependencies = { "mfussenegger/nvim-dap" },
        opts = {},
    },
    -- {
    --     "Jorenar/nvim-dap-disasm",
    --     dependencies = "igorlfs/nvim-dap-view",
    --     config = true,
    -- },
    -- {
    --     "igorlfs/nvim-dap-view",
    --     ---@module 'dap-view'
    --     ---@type dapview.Config
    --     opts = {},
    -- },
}
