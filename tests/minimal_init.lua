local root = vim.fn.getcwd()
local lazy = vim.fn.stdpath("data") .. "/lazy"

vim.opt.rtp:prepend(root)
for _, plugin in ipairs({ "plenary.nvim", "neo-tree.nvim", "nui.nvim" }) do
  vim.opt.rtp:prepend(vim.fs.joinpath(lazy, plugin))
end
vim.loader.reset()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.opt.swapfile = false
