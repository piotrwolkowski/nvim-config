return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lsp-signature-help", -- suggestion 3
      "onsails/lspkind.nvim", -- suggestion 4
    },
    opts = function(_, opts)
      local cmp = require("cmp")

      -- 1️⃣ Prioritize LSP
      opts.sorting = {
        priority_weight = 2,
        comparators = cmp.config.compare,
      }

      -- 2️⃣ Clean sources (LSP first, buffer less noisy)
      opts.sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "nvim_lsp_signature_help" }, -- suggestion 3
        { name = "buffer", keyword_length = 5 }, -- less spam
      })

      -- 4️⃣ Better formatting (icons)
      opts.formatting = {
        format = require("lspkind").cmp_format({
          mode = "symbol_text",
          maxwidth = 50,
          ellipsis_char = "...",
        }),
      }

      return opts
    end,
  },
}
