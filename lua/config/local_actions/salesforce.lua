--------------------------------------------------------------------------------
-- Salesforce localleader provider — guarded cloud actions for project buffers.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local web_filetypes = {
  html = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}
local web_metadata_roots = {
  aura = true,
  components = true,
  lwc = true,
  pages = true,
  staticresources = true,
}
local package_cache = {}

local function canonical_path(path)
  path = vim.fs.normalize(path)
  local real = uv.fs_realpath(path)
  if real then
    return vim.fs.normalize(real)
  end
  local parent = uv.fs_realpath(vim.fs.dirname(path))
  return parent and vim.fs.joinpath(parent, vim.fs.basename(path)) or path
end

local function package_roots(root)
  root = canonical_path(root)
  local project_file = vim.fs.joinpath(root, "sfdx-project.json")
  local stat = uv.fs_stat(project_file)
  local cached = package_cache[root]
  local stamp = stat and string.format("%s:%s", stat.mtime.sec, stat.mtime.nsec) or "missing"
  if cached and cached.stamp == stamp then
    return cached.roots
  end

  local roots = {}
  local ok, lines = pcall(vim.fn.readfile, project_file)
  local decoded_ok, project = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  if decoded_ok and type(project) == "table" then
    for _, entry in ipairs(project.packageDirectories or {}) do
      if type(entry.path) == "string" and entry.path ~= "" then
        roots[#roots + 1] = canonical_path(vim.fs.joinpath(root, entry.path))
      end
    end
  end
  package_cache[root] = { roots = roots, stamp = stamp }
  return roots
end

local function source_relative(path, root)
  path = canonical_path(path)
  root = canonical_path(root)
  local best
  for _, package_root in ipairs(package_roots(root)) do
    local relative = vim.fs.relpath(package_root, path)
    if relative and relative ~= ".." and not relative:match("^%.%.[/\\]") then
      relative = relative:gsub("\\", "/")
      if not best or #relative < #best then
        best = relative
      end
    end
  end
  return best and best:gsub("^main/default/", "") or nil
end

local function is_metadata_buffer(context, root)
  if not context.path or not root then
    return false
  end
  local relative = source_relative(context.path, root)
  local metadata_root = relative and relative:match("^([^/]+)/")
  if metadata_root == "classes" or metadata_root == "triggers" then
    return context.filetype == "apex" or context.filetype == "apexcode"
  end
  return web_metadata_roots[metadata_root] == true and web_filetypes[context.filetype] == true
end

function M.new(deps)
  local function sf_method(bufnr, method)
    return function()
      deps.guarded_load(deps.sf_action(method), bufnr)
    end
  end

  return {
    id = "salesforce",
    label = "Salesforce",
    priority = 80,
    resolve = function(context)
      local root = deps.salesforce_root(context.bufnr)
      if not root then
        return nil
      end

      local bufnr = context.bufnr
      local actions = {
        {
          id = "org-browser",
          label = "Open Org Browser",
          run = function()
            deps.guarded_load(function()
              vim.cmd("Neotree sf_org toggle left")
            end, bufnr)
          end,
        },
        {
          id = "metadata-browser",
          label = "Open metadata/package.xml browser",
          run = function()
            deps.guarded_load(function()
              require("config.salesforce.browser").open()
            end, bufnr)
          end,
        },
        {
          id = "open-org",
          label = "Open target org in browser",
          run = sf_method(bufnr, "org_open"),
        },
        {
          id = "cancel",
          label = "Cancel active Salesforce actions",
          run = function()
            deps.cancel()
          end,
        },
      }

      if is_metadata_buffer(context, root) then
        vim.list_extend(actions, {
          {
            id = "retrieve-current",
            label = "Retrieve current metadata",
            run = sf_method(bufnr, "retrieve"),
          },
          {
            id = "deploy-current",
            label = "Save and deploy current metadata",
            desc = "Salesforce: save and deploy current metadata",
            slot = "build",
            run = sf_method(bufnr, "save_and_push"),
          },
          {
            id = "diff-current",
            label = "Diff current metadata with org",
            run = sf_method(bufnr, "diff_in_target_org"),
          },
          {
            id = "open-current",
            label = "Open current metadata in org",
            run = sf_method(bufnr, "org_open_current_file"),
          },
        })
      end

      if context.filetype == "apex" or context.filetype == "apexcode" then
        actions[#actions + 1] = {
          id = "test-current",
          label = "Run Apex test under cursor",
          desc = "Salesforce: test under cursor",
          slot = "test",
          run = sf_method(bufnr, "run_current_test"),
        }
        actions[#actions + 1] = {
          id = "test-current-coverage",
          label = "Run Apex test under cursor with coverage",
          run = sf_method(bufnr, "run_current_test_with_coverage"),
        }
      end

      return {
        label = "Salesforce",
        root = root,
        actions = actions,
      }
    end,
  }
end

M._test = {
  canonical_path = canonical_path,
  is_metadata_buffer = is_metadata_buffer,
  package_roots = package_roots,
  source_relative = source_relative,
}

return M
