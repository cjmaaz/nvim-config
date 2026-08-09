--------------------------------------------------------------------------------
-- Salesforce manifest picker — search manifest/**/*.xml, then retrieve/deploy
--------------------------------------------------------------------------------

local M = {}

local metadata = require("config.salesforce.metadata")

local function list_xml(dir)
  local uv = vim.uv or vim.loop
  local results = {}

  local function walk(path, relative)
    local scanner = uv.fs_scandir(path)
    if not scanner then
      return
    end
    while true do
      local name, kind = uv.fs_scandir_next(scanner)
      if not name then
        break
      end
      local child_path = vim.fs.joinpath(path, name)
      local child_relative = relative == "" and name or vim.fs.joinpath(relative, name)
      if kind == "directory" then
        walk(child_path, child_relative)
      elseif kind == "file" and name:lower():match("%.xml$") then
        results[#results + 1] = child_relative
      end
    end
  end

  walk(dir, "")
  table.sort(results)
  return results
end

local function selected_path(selected, dir)
  local relative = selected and selected[1] or nil
  return relative and vim.fs.joinpath(dir, relative) or nil
end

function M.open()
  local dir, ctx = metadata.manifest_dir()
  if not dir or not ctx then
    return
  end
  if not (vim.uv or vim.loop).fs_stat(dir) then
    vim.notify("No manifest directory in this Salesforce project.", vim.log.levels.WARN, {
      title = "SF manifests",
    })
    return
  end

  local files = list_xml(dir)
  if #files == 0 then
    vim.notify("No XML manifests found under manifest/.", vim.log.levels.WARN, {
      title = "SF manifests",
    })
    return
  end

  require("fzf-lua").fzf_exec(files, {
    prompt = string.format("Manifests [%s]> ", ctx.org),
    header = "<CR> retrieve | ^D deploy",
    cwd = dir,
    fzf_opts = {
      ["--no-multi"] = true,
      ["--scheme"] = "path",
    },
    keymap = {
      fzf = {
        ["ctrl-d"] = false, -- replaced by deploy action below
      },
    },
    winopts = {
      preview = {
        hidden = false,
        title = " Manifest XML ",
      },
    },
    preview = {
      field_index = "{}",
      fn = function(selected)
        local path = selected_path(selected, dir)
        if not path then
          return {}
        end
        local ok, lines = pcall(vim.fn.readfile, path)
        return ok and lines or { "Could not read " .. path }
      end,
    },
    actions = {
      ["default"] = function(selected)
        local path = selected_path(selected, dir)
        if path then
          metadata.retrieve_manifest(path)
        end
      end,
      ["ctrl-d"] = function(selected)
        local path = selected_path(selected, dir)
        if not path then
          return
        end
        local relative = vim.fs.relpath(ctx.root, path) or path
        local answer = vim.fn.confirm(
          string.format("Deploy manifest?\n\n%s\n\nTarget: %s", relative, ctx.org),
          "&Deploy\n&Cancel",
          2
        )
        if answer == 1 then
          metadata.deploy_manifest(path)
        end
      end,
    },
  })
end

M._test = {
  list_xml = list_xml,
  selected_path = selected_path,
}

return M
