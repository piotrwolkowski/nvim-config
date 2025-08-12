-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Running unit tests
require("which-key").register({
  ["<leader>t"] = { name = "+unit tests" },
})

local neotest = require("neotest")
vim.keymap.set("n", "<leader>tt", function()
  neotest.run.run()
end, { desc = "Run nearest test" })

vim.keymap.set("n", "<leader>tf", function()
  neotest.run.run(vim.fn.expand("%"))
end, { desc = "Run all tests in current file" })

vim.keymap.set("n", "<leader>to", function()
  neotest.output.open({ enter = true })
end, { desc = "Open test output" })

vim.keymap.set("n", "<leader>ts", function()
  neotest.summary.toggle()
end, { desc = "Toggle test summary" })

vim.keymap.set("n", "<leader>td", function()
  neotest.run.run({ strategy = "dap" })
end, { desc = "Debug nearest test" })

-- Debug
vim.keymap.set("n", "<F5>", function()
  require("dap").continue()
end, { desc = "DAP Continue" })
vim.keymap.set("n", "<F8>", function()
  require("dap").terminate()
  require("dapui").close()
end, { desc = "DAP Stop" })
vim.keymap.set("n", "<F10>", function()
  require("dap").step_over()
end, { desc = "DAP Step Over" })
vim.keymap.set("n", "<F11>", function()
  require("dap").step_into()
end, { desc = "DAP Step Into" })
vim.keymap.set("n", "<F12>", function()
  require("dap").step_out()
end, { desc = "DAP Step Out" })
vim.keymap.set("n", "<F9>", function()
  require("dap").toggle_breakpoint()
end, { desc = "DAP Toggle Breakpoint" })
