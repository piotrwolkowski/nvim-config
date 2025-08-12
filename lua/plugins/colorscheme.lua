return {
  -- Set LazyVim to use catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- Configure catppuccin with transparent background
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      transparent_background = false,
      flavour = "mocha", -- or latte, frappe, macchiato
    },
  },
}
