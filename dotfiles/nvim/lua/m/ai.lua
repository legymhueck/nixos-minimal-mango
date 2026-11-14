-- Three assistants side by side:
--   Copilot   ghost text while typing (native LSP inline completion, <Tab> accepts)
--   Claude    Claude Code in a right split, sees your selection and shows diffs in nvim
--   opencode  opencode in a right split, prompts with @this / @buffer context
local map = vim.keymap.set

-- Copilot. Sign in once with :LspCopilotSignIn.
vim.lsp.inline_completion.enable(true)
map("i", "<M-]>", function()
  vim.lsp.inline_completion.select({ count = 1 })
end, { desc = "Next Copilot suggestion" })
map("i", "<M-[>", function()
  vim.lsp.inline_completion.select({ count = -1 })
end, { desc = "Previous Copilot suggestion" })
map("n", "<leader>at", function()
  local on = vim.lsp.inline_completion.is_enabled()
  vim.lsp.inline_completion.enable(not on)
  vim.notify("Copilot suggestions " .. (on and "off" or "on"))
end, { desc = "Toggle Copilot suggestions" })
map("n", "<leader>ag", function()
  Snacks.terminal("copilot", { win = { position = "right", width = 0.4 } })
end, { desc = "Copilot CLI" })

-- Claude Code (coder/claudecode.nvim): `claude` connects to nvim like to the VS Code extension.
require("claudecode").setup({ terminal = { split_side = "right", split_width_percentage = 0.4 } })
map("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume a Claude session" })
map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue last Claude session" })
map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add file to Claude" })
map("x", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send selection to Claude" })
map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept Claude's change" })
map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Reject Claude's change" })

-- opencode (nickjvandyke/opencode.nvim): talks to `opencode --port` in a right split.
local opencode_cmd = "opencode --port"
local opencode_win = { win = { position = "right", width = 0.4, enter = false } }
vim.g.opencode_opts = {
  server = {
    start = function()
      Snacks.terminal.open(opencode_cmd, opencode_win)
    end,
  },
}
local oc = function()
  return require("opencode")
end
map("n", "<leader>oo", function()
  Snacks.terminal.toggle(opencode_cmd, opencode_win)
end, { desc = "Toggle opencode" })
map({ "n", "x" }, "<leader>oa", function()
  oc().ask("@this: ")
end, { desc = "Ask opencode about this" })
map({ "n", "x" }, "<leader>os", function()
  oc().select()
end, { desc = "opencode prompts and commands" })
map({ "n", "x" }, "go", function()
  return oc().operator("@this ")
end, { desc = "Add range to opencode", expr = true })
map("n", "goo", function()
  return oc().operator("@this ") .. "_"
end, { desc = "Add line to opencode", expr = true })
