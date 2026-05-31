return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      background = { light = "latte", dark = "mocha" },
      transparent_background = false,
      term_colors = true,
      dim_inactive = { enabled = true, shade = "dark", percentage = 0.15 },
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
      },
      integrations = {
        cmp = true,
        gitsigns = true,
        neo_tree = true,
        telescope = { enabled = true },
        treesitter = true,
        which_key = true,
        mini = { enabled = true },
        indent_blankline = { enabled = true },
        mason = true,
        notify = true,
        noice = true,
        lsp_trouble = true,
        flash = true,
        illuminate = { enabled = true },
        harpoon = true,
      },
    },
  },
  -- Tell LazyVim to use catppuccin as the default colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
