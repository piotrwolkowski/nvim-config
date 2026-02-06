return {
  "gorbit99/codewindow.nvim",
  event = "BufReadPre",
  config = function()
    local opts = {
      active_in_terminals = false,
      auto_enable = false,
      exclude_filetypes = { "help" },
      max_minimap_height = nil,
      max_lines = nil,
      minimap_width = 20,
      use_lsp = true,
      use_treesitter = false, -- ts_utils was removed from nvim-treesitter; must be set before require("codewindow")
      use_git = true,
      width_multiplier = 4,
      z_index = 1,
      show_cursor = true,
      screen_bounds = "lines",
      window_border = "single",
      relative = "win",
      events = { "TextChanged", "InsertLeave", "DiagnosticChanged", "FileWritePost" },
    }
    -- Set config before any codewindow module loads; highlight.lua reads config at load time
    -- and requires nvim-treesitter.ts_utils when use_treesitter is true (default).
    require("codewindow.config").setup(opts)
    local codewindow = require("codewindow")
    codewindow.setup(opts)
    codewindow.apply_default_keybinds()
    codewindow.toggle_minimap()
  end,
}
