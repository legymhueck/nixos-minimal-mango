-- Language servers, formatting and linting. The servers are on PATH through
-- common/neovim.nix (extraPackages) and common/apps.nix.
local vscode = require("m.vscode")

vim.diagnostic.config({ virtual_text = true, severity_sort = true })

-- Python: use the unit's .venv (uv sync) when there is one.
vim.lsp.config("basedpyright", {
  settings = { basedpyright = { analysis = { typeCheckingMode = "standard" } } },
  before_init = function(_, config)
    local python = config.root_dir and config.root_dir .. "/.venv/bin/python"
    if python and vim.uv.fs_stat(python) then
      config.settings.python = { pythonPath = python }
    end
  end,
})

-- Typst: the repo root is the root for absolute imports, like `typst compile --root .`.
vim.lsp.config("tinymist", {
  root_markers = { ".git" },
  settings = { formatterMode = "typstyle", exportPdf = "never" },
  before_init = function(_, config)
    config.settings.rootPath = config.root_dir
  end,
})

vim.lsp.enable({ "basedpyright", "ruff", "tinymist", "marksman", "lua_ls", "nixd", "copilot" })

-- Java: jdtls reads the source paths and jars from .vscode/settings.json,
-- exactly like the Java extension in VS Code.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function(ev)
    local flat, root = vscode.settings(ev.file)
    root = root or vim.fs.root(ev.buf, { "pom.xml", "build.gradle", ".git" }) or vim.fs.dirname(ev.file)
    local settings = vscode.nested("java", flat)
    -- Compile against the JDK with JavaFX (JAVA_HOME is set by common/neovim.nix).
    settings.java = settings.java or {}
    settings.java.configuration = {
      runtimes = { { name = "JavaSE-21", path = vim.env.JAVA_HOME, default = true } },
    }
    require("jdtls").start_or_attach({
      cmd = { "jdtls", "-data", vim.fn.stdpath("cache") .. "/jdtls/" .. root:gsub("/", "%%") },
      root_dir = root,
      settings = settings,
    })
  end,
})

-- Keys on top of the built-in LSP ones (K, grn, gra, grr, gri, gO, [d, ]d).
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>cd", vim.diagnostic.open_float, "Show diagnostic")
  end,
})

-- Formatting. On save only where .vscode/settings.json says "editor.formatOnSave".
local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    python = { "ruff_organize_imports", "ruff_format" },
    nix = { "nixfmt" },
  },
  default_format_opts = { lsp_format = "fallback" }, -- Java (jdtls), Typst (tinymist)
  formatters = {
    ruff_format = {
      -- The folder's indent width from .vscode/settings.json (python-ag uses 2);
      -- without one, ruff's own default or pyproject.toml applies.
      prepend_args = function(_, ctx)
        local size = vscode.get(ctx.buf, "editor.tabSize")
        return type(size) == "number" and { "--config", "indent-width=" .. size } or {}
      end,
    },
  },
  format_on_save = function(buf)
    if vscode.get(buf, "editor.formatOnSave") == true then
      return { timeout_ms = 3000 }
    end
  end,
})
vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  conform.format()
end, { desc = "Format" })

-- Markdown lint with the repo's .markdownlint.json.
local lint = require("lint")
lint.linters_by_ft = { markdown = { "markdownlint-cli2" } }
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  callback = function()
    lint.try_lint()
  end,
})
