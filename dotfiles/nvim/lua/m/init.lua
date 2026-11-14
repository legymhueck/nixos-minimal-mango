-- Entry point, loaded from the init.lua that Home Manager writes.
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.g.markdown_recommended_style = 0 -- keep 2-space lists (.markdownlint.json MD007)

local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.mouse = "a"
o.clipboard = "unnamedplus" -- wl-clipboard is installed
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.termguicolors = true
o.expandtab = true
o.shiftwidth = 2 -- the repo default; .vscode/settings.json can override per folder
o.tabstop = 2
o.linebreak = true
o.updatetime = 300
o.confirm = true
o.spelllang = { "de", "en" }

-- Prose files: wrap long lines, check spelling.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "typst" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Briefly highlight what was yanked.
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

require("m.plugins")
require("m.lsp")
require("m.run")
require("m.ai")

local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map({ "n", "t" }, "<C-h>", "<cmd>wincmd h<cr>", { desc = "Window left" })
map({ "n", "t" }, "<C-j>", "<cmd>wincmd j<cr>", { desc = "Window down" })
map({ "n", "t" }, "<C-k>", "<cmd>wincmd k<cr>", { desc = "Window up" })
map({ "n", "t" }, "<C-l>", "<cmd>wincmd l<cr>", { desc = "Window right" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
