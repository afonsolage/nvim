vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move line up and down keeping identation
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Merge the bellow line on the current one
vim.keymap.set("n", "J", "mzJ`z")

-- Move half-page up/down and keep cursor on center
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Paste above or bellow
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Delete above or bello
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Some commands only works <Esc>
vim.keymap.set("i", "<C-c>", "<Esc>")


