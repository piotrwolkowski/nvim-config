return {
  "nvim-mini/mini.move",
  version = false,
  config = function()
    require("mini.move").setup({
      mappings = {
        left = "<M-h>",
        right = "<M-l>",
        down = "<M-j>",
        up = "<M-k>",
      },
    })
  end,
}
