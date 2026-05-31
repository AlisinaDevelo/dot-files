local map = vim.keymap.set

-- Exit insert with jk
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- Save from any mode
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Keep cursor centered when scrolling / searching
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })
map("n", "n", "nzzzv", { desc = "Next result" })
map("n", "N", "Nzzzv", { desc = "Prev result" })

-- Stay in visual mode after indent
map("v", "<", "<gv", { desc = "Dedent" })
map("v", ">", ">gv", { desc = "Indent" })

-- Move lines up/down in normal and visual mode
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down", silent = true })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up", silent = true })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Paste over selection without losing clipboard register
map("v", "p", '"_dP', { desc = "Paste without overwriting register" })

-- Extra Telescope pickers
map("n", "<leader>fc", "<cmd>Telescope commands<cr>", { desc = "Commands" })
map("n", "<leader>fm", "<cmd>Telescope marks<cr>", { desc = "Marks" })
map("n", "<leader>fj", "<cmd>Telescope jumplist<cr>", { desc = "Jumplist" })
