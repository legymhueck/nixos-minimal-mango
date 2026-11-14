-- <leader>r…: run Python and Java files, preview and export Typst, Marp and
-- Markdown, with the same commands as the repo unterricht (README, _tools/).
local vscode = require("m.vscode")

local function term(cmd, cwd)
  Snacks.terminal.open(cmd, { cwd = cwd, auto_close = false, win = { position = "bottom", height = 0.3 } })
end

local function job(cmd, cwd, done)
  vim.notify(table.concat(cmd, " "))
  vim.system(
    cmd,
    { cwd = cwd, text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        vim.notify((res.stderr ~= "" and res.stderr or res.stdout), vim.log.levels.ERROR)
      elseif done then
        vim.notify(done)
      end
    end)
  )
end

local function is_marp(buf)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 20, false)) do
    if line:match("^marp:%s*true") then
      return true
    end
  end
  return false
end

local function git_root(file)
  return vim.fs.root(file, ".git") or vim.fs.dirname(file)
end

-- Python: the .venv of the unit, started in the file's folder (as .vscode/tasks.json does).
local function run_python(file)
  local root = vim.fs.root(file, { "pyproject.toml", ".venv" })
  local venv = root and root .. "/.venv/bin/python"
  local python = venv and vim.uv.fs_stat(venv) and venv or "python3"
  term({ python, file }, vim.fs.dirname(file))
end

-- Java: compile the file and what it uses (-sourcepath) into .java-bin/ (git-ignored), then start it.
local function run_java(file, buf)
  local flat, root = vscode.settings(file)
  root = root or vim.fs.dirname(file)
  local pkg
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 40, false)) do
    pkg = line:match("^%s*package%s+([%w_.]+)%s*;")
    if pkg then
      break
    end
  end
  local dir = vim.fs.dirname(file)
  local src = { pkg and dir:sub(1, #dir - #pkg - 1) or dir }
  for _, p in ipairs(flat["java.project.sourcePaths"] or {}) do
    table.insert(src, root .. "/" .. p)
  end
  local cp = {}
  for _, pattern in ipairs(flat["java.project.referencedLibraries"] or { "lib/**/*.jar" }) do
    vim.list_extend(cp, vim.fn.glob(root .. "/" .. pattern, false, true))
  end
  local out = root .. "/.java-bin"
  local main = (pkg and pkg .. "." or "") .. vim.fn.fnamemodify(file, ":t:r")
  local classpath = table.concat(vim.list_extend({ out }, cp), ":")
  local script = string.format(
    "javac -d %s -cp %s -sourcepath %s %s && java -cp %s %s",
    vim.fn.shellescape(out),
    vim.fn.shellescape(classpath),
    vim.fn.shellescape(table.concat(src, ":")),
    vim.fn.shellescape(file),
    vim.fn.shellescape(classpath),
    main
  )
  term({ "bash", "-c", script }, root) -- cwd = the .vscode folder, like VS Code
end

local function run()
  local buf, file = 0, vim.api.nvim_buf_get_name(0)
  vim.cmd.update()
  local ft = vim.bo.filetype
  if ft == "python" then
    run_python(file)
  elseif ft == "java" then
    run_java(file, buf)
  else
    vim.notify("Nothing to run for " .. ft, vim.log.levels.WARN)
  end
end

local function preview()
  local file = vim.api.nvim_buf_get_name(0)
  if vim.bo.filetype == "typst" then
    vim.cmd("TypstPreviewToggle")
  elseif vim.bo.filetype == "markdown" and is_marp(0) then
    vim.system({ "marp", "--preview", "--html", "--allow-local-files", file }, { cwd = vim.fs.dirname(file) })
  elseif vim.bo.filetype == "markdown" then
    vim.cmd("RenderMarkdown toggle")
  end
end

-- PDF: typst compile --root <repo> | marp --pdf | _tools/pdf-bauen.sh <folder>
local function export_pdf()
  vim.cmd.update()
  local file = vim.api.nvim_buf_get_name(0)
  local root = git_root(file)
  if vim.bo.filetype == "typst" then
    job({ "typst", "compile", "--root", root, file }, root, "PDF written next to the file")
  elseif is_marp(0) then
    job(
      { "marp", "--pdf", "--html", "--allow-local-files", file },
      vim.fs.dirname(file),
      "PDF written next to the file"
    )
  elseif vim.bo.filetype == "markdown" then
    term({ "bash", root .. "/_tools/pdf-bauen.sh", vim.fs.dirname(file) }, root)
  end
end

-- HTML: marp --html | _tools/html-bauen.sh <folder> (student HTML for Logineo)
local function export_html()
  vim.cmd.update()
  local file = vim.api.nvim_buf_get_name(0)
  local root = git_root(file)
  if is_marp(0) then
    job({ "marp", "--html", file }, vim.fs.dirname(file), "HTML written next to the file")
  elseif vim.bo.filetype == "markdown" then
    term({ "bash", root .. "/_tools/html-bauen.sh", vim.fs.dirname(file) }, root)
  end
end

local function export_pptx()
  vim.cmd.update()
  local file = vim.api.nvim_buf_get_name(0)
  job(
    { "marp", "--pptx", "--html", "--allow-local-files", file },
    vim.fs.dirname(file),
    "PPTX written next to the file"
  )
end

local map = vim.keymap.set
map("n", "<leader>rr", run, { desc = "Run file (Python / Java)" })
map("n", "<leader>rp", preview, { desc = "Preview (Typst / Marp / Markdown)" })
map("n", "<leader>re", export_pdf, { desc = "Export PDF" })
map("n", "<leader>rh", export_html, { desc = "Export HTML" })
map("n", "<leader>rx", export_pptx, { desc = "Export PPTX (Marp)" })
