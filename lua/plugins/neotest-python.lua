return {
  -- Load Python support for neotest
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
      "nvim-neotest/nvim-nio",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require("neotest-python")({
          -- Optional:
          dap = { justMyCode = false }, -- enable debug
          runner = "unittest", -- or "pytest" if you use that
        })
      )
    end,
  },
}
