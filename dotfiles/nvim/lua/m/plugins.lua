-- UI, navigation and editing plugins. All of them are installed by
-- common/neovim.nix; this file only configures them.
vim.cmd.colorscheme("tokyonight-night")

require("mini.icons").setup()
require("mini.statusline").setup()
require("mini.surround").setup() -- sa / sd / sr: add, delete, replace quotes and brackets
require("mini.pairs").setup()
require("mini.ai").setup() -- extra text objects: af/if (function call), aa/ia (argument)

require("snacks").setup({
  picker = { enabled = true },
  explorer = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true },
  terminal = { enabled = true },
  lazygit = { enabled = true },
  indent = { enabled = true },
})

require("oil").setup({ view_options = { show_hidden = true } })
require("gitsigns").setup()

require("render-markdown").setup({ enabled = false }) -- toggled with <leader>rp
-- nixpkgs patches in tinymist and websocat; the default root is the folder
-- with .git, so /_vorlagen/typst/schule.typ resolves.
require("typst-preview").setup()

-- Tree-sitter: grammars come prebuilt from nixpkgs; start highlighting where one exists.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

require("blink.cmp").setup({
  keymap = {
    preset = "default", -- <C-y> accept, <C-n>/<C-p> move, <C-space> open, <C-e> close
    -- <Tab>: jump in a snippet, else accept the Copilot ghost text, else a real tab.
    ["<Tab>"] = {
      "snippet_forward",
      function()
        return vim.lsp.inline_completion.get()
      end,
      "fallback",
    },
  },
  completion = { documentation = { auto_show = true } },
  signature = { enabled = true },
})

local wk = require("which-key")
wk.setup({ delay = 400 })
wk.add({
  { "<leader>a", group = "AI: Claude / Copilot" },
  { "<leader>o", group = "AI: opencode" },
  { "<leader>g", group = "Git" },
  { "<leader>r", group = "Run / render" },
  { "<leader>s", group = "Search" },
  { "<leader>c", group = "Code" },
})

local map = vim.keymap.set
local pick = Snacks.picker
map("n", "<leader><space>", function()
  pick.smart()
end, { desc = "Find file (smart)" })
map("n", "<leader>/", function()
  pick.grep()
end, { desc = "Grep in project" })
map("n", "<leader>,", function()
  pick.buffers()
end, { desc = "Open buffers" })
map("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "File tree" })
map("n", "-", "<cmd>Oil<cr>", { desc = "Folder as buffer (oil)" })
map("n", "<leader>sr", function()
  pick.recent()
end, { desc = "Recent files" })
map("n", "<leader>sh", function()
  pick.help()
end, { desc = "Help pages" })
map("n", "<leader>sk", function()
  pick.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>sd", function()
  pick.diagnostics()
end, { desc = "Diagnostics" })
map("n", "<leader>ss", function()
  pick.lsp_symbols()
end, { desc = "Symbols in file" })
map("n", "<leader>sw", function()
  pick.grep_word()
end, { desc = "Word under cursor" })
map("n", "<leader>gg", function()
  Snacks.lazygit()
end, { desc = "Lazygit" })
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>", { desc = "Blame line" })
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Preview change" })
map("n", "]h", "<cmd>Gitsigns next_hunk<cr>", { desc = "Next change" })
map("n", "[h", "<cmd>Gitsigns prev_hunk<cr>", { desc = "Previous change" })
map({ "n", "t" }, "<C-/>", function()
  Snacks.terminal()
end, { desc = "Terminal" })
