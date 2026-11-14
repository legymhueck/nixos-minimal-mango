-- Reads the nearest .vscode/settings.json, so nvim follows the same per-folder
-- settings as VS Code (Java source paths, indent width, format on save).
local M = {}

local cache = {}

-- The folder that holds the nearest .vscode/settings.json above `path`.
function M.root(path)
  return vim.fs.root(path or 0, function(name, dir)
    return name == ".vscode" and vim.uv.fs_stat(dir .. "/.vscode/settings.json") ~= nil
  end)
end

-- Flat table as written in the file ({ ["java.project.sourcePaths"] = {...} }).
function M.settings(path)
  local root = M.root(path)
  if not root then
    return {}, nil
  end
  if cache[root] then
    return cache[root], root
  end
  local file = io.open(root .. "/.vscode/settings.json", "r")
  if not file then
    return {}, root
  end
  local text = file:read("*a")
  file:close()
  -- JSONC: drop whole-line comments and trailing commas.
  text = ("\n" .. text):gsub("\n%s*//[^\n]*", "\n"):gsub(",(%s*[}%]])", "%1")
  local ok, flat = pcall(vim.json.decode, text)
  cache[root] = ok and flat or {}
  return cache[root], root
end

-- "java.*" keys nested the way a language server expects them.
function M.nested(prefix, flat)
  local out = {}
  for key, value in pairs(flat) do
    if vim.startswith(key, prefix .. ".") then
      local node = out
      local parts = vim.split(key, ".", { plain = true })
      for i = 1, #parts - 1 do
        node[parts[i]] = node[parts[i]] or {}
        node = node[parts[i]]
      end
      node[parts[#parts]] = value
    end
  end
  return out
end

-- A setting for one file type: "[python]" block first, then the top level.
function M.get(buf, key)
  local flat = M.settings(vim.api.nvim_buf_get_name(buf))
  local lang = flat["[" .. vim.bo[buf].filetype .. "]"]
  if type(lang) == "table" and lang[key] ~= nil then
    return lang[key]
  end
  return flat[key]
end

-- Apply indent width per buffer.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    local size = M.get(ev.buf, "editor.tabSize")
    if type(size) == "number" then
      vim.bo[ev.buf].shiftwidth = size
      vim.bo[ev.buf].tabstop = size
    end
  end,
})

return M
