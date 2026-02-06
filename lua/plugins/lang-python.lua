return {
  -- Treesitter for Python (parser only; use classic syntax highlighting for Python)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "python" })
      -- opts.highlight = opts.highlight or {}
      -- opts.highlight.disable = opts.highlight.disable or {}
      -- vim.list_extend(opts.highlight.disable, { "python" })
    end,
  },

  -- LSP server for Python
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "pyright" })
    end,
  },

  -- Disable LSP semantic tokens for Pyright so syntax/colorscheme control Python highlighting
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          on_init = function(client)
            if client.server_capabilities then
              client.server_capabilities.semanticTokensProvider = nil
            end
          end,
        },
      },
    },
  },

  -- Formatters and linters for Python
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "black", -- Formatter
        "ruff", -- Linter
      })
    end,
  },
}
