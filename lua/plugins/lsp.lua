return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local cmp_lsp = require("cmp_nvim_lsp")
      opts.capabilities = cmp_lsp.default_capabilities(opts.capabilities)
    end,
  },
}
