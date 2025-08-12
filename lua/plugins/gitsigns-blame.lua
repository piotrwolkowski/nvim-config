return {
  "lewis6991/gitsigns.nvim",
  opts = {
    current_line_blame = true, -- enable blame
    current_line_blame_opts = {
      delay = 100, -- milliseconds before showing
      virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
    },
    -- Format: Author, date, commit message
    current_line_blame_formatter = "    <abbrev_sha>, <author>, <author_time:%Y-%M-%d %H:%m:%S> (<author_time:%R>) - <summary>",
  },
  config = function(_, opts)
    require("gitsigns").setup(opts)
    vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", {
      fg = "#211436",
      bg = "#392848",
      italic = true,
    })
  end,
}
