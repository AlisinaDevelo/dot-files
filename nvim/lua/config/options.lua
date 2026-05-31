local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs / indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true

-- Wrapping
opt.wrap = false
opt.linebreak = true
opt.breakindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

-- Cursor / scrolling
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.cursorline = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.showmode = false
opt.pumblend = 10
opt.winblend = 10
opt.conceallevel = 2

-- Files
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- System clipboard
opt.clipboard = "unnamedplus"

-- Timing
opt.updatetime = 250
opt.timeoutlen = 300

-- Completion
opt.completeopt = "menu,menuone,noselect"
opt.confirm = true

-- Folding via treesitter
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevelstart = 99
